//
//  MemoryManager.swift
//  Synagamy3.0
//
//  Memory management and optimization utilities
//

import UIKit
import SwiftUI

@MainActor
final class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published private(set) var memoryUsage: MemoryInfo = MemoryInfo()
    @Published private(set) var isLowMemoryMode: Bool = false
    
    private var timer: Timer?
    private let threshold: UInt64 = 500 * 1024 * 1024 // 500MB threshold
    
    struct MemoryInfo {
        let used: UInt64
        let total: UInt64
        let available: UInt64
        let percentage: Double
        
        init() {
            let info = MemoryManager.getMemoryInfo()
            self.used = info.used
            self.total = info.total
            self.available = info.available
            self.percentage = info.percentage
        }
    }
    
    private init() {
        startMonitoring()
        setupMemoryWarningObserver()
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Memory Monitoring
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryInfo()
            }
        }
    }
    
    private func updateMemoryInfo() {
        memoryUsage = MemoryInfo()
        isLowMemoryMode = memoryUsage.used > threshold
        
        if isLowMemoryMode {
            optimizeMemoryUsage()
        }
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        Task { @MainActor in
            isLowMemoryMode = true
            optimizeMemoryUsage()
        }
    }
    
    // MARK: - Memory Optimization
    
    private func optimizeMemoryUsage() {
        // Clear unused caches
        ImageCache.shared.clearUnusedImages()
        
        // Reduce image quality for low memory
        ImageCache.shared.enableLowMemoryMode()
        
        // Clear old prediction results
        PredictionCache.shared.clearOldPredictions()
        
        // Request garbage collection
        autoreleasepool {
            // Force deallocation of unused objects
        }
        
        #if DEBUG
        print("🧹 MemoryManager: Optimized memory usage. Current: \(memoryUsage.used / (1024*1024))MB")
        #endif
    }
    
    nonisolated static func getMemoryInfo() -> (used: UInt64, total: UInt64, available: UInt64, percentage: Double) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return (0, 0, 0, 0)
        }
        
        let used = UInt64(info.resident_size)
        let total = UInt64(ProcessInfo.processInfo.physicalMemory)
        let available = total > used ? total - used : 0
        let percentage = total > 0 ? Double(used) / Double(total) * 100 : 0
        
        return (used, total, available, percentage)
    }
}

// MARK: - Image Cache Management

@MainActor
final class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private var cache: NSCache<NSString, UIImage> = NSCache()
    private var isLowMemoryMode = false
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func image(for key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }
    
    func setImage(_ image: UIImage, for key: String) {
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: NSString(string: key), cost: cost)
    }
    
    func clearUnusedImages() {
        cache.removeAllObjects()
    }
    
    func enableLowMemoryMode() {
        isLowMemoryMode = true
        cache.countLimit = 50
        cache.totalCostLimit = 25 * 1024 * 1024 // 25MB
    }
    
    func disableLowMemoryMode() {
        isLowMemoryMode = false
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
}

// MARK: - Prediction Result Cache

@MainActor
final class PredictionCache: ObservableObject {
    static let shared = PredictionCache()
    
    private var cache: [String: CachedPrediction] = [:]
    private let maxCacheSize = 50
    private let maxAge: TimeInterval = 3600 // 1 hour
    
    struct CachedPrediction {
        let result: Any // Your prediction result type
        let timestamp: Date
        let accessCount: Int
    }
    
    private init() {}
    
    func prediction(for key: String) -> Any? {
        guard let cached = cache[key] else { return nil }
        
        // Check if expired
        if Date().timeIntervalSince(cached.timestamp) > maxAge {
            cache.removeValue(forKey: key)
            return nil
        }
        
        // Update access count
        cache[key] = CachedPrediction(
            result: cached.result,
            timestamp: cached.timestamp,
            accessCount: cached.accessCount + 1
        )
        
        return cached.result
    }
    
    func setPrediction(_ result: Any, for key: String) {
        // Remove oldest if at capacity
        if cache.count >= maxCacheSize {
            removeOldestPrediction()
        }
        
        cache[key] = CachedPrediction(
            result: result,
            timestamp: Date(),
            accessCount: 0
        )
    }
    
    func clearOldPredictions() {
        let cutoff = Date().addingTimeInterval(-maxAge)
        cache = cache.filter { $0.value.timestamp > cutoff }
    }
    
    private func removeOldestPrediction() {
        guard let oldestKey = cache.min(by: { 
            $0.value.timestamp < $1.value.timestamp 
        })?.key else { return }
        
        cache.removeValue(forKey: oldestKey)
    }
}

// MARK: - SwiftUI Memory Monitoring

struct MemoryMonitorView: View {
    @StateObject private var memoryManager = MemoryManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory Usage")
                .font(.headline)
            
            HStack {
                Text("Used: \(formatBytes(memoryManager.memoryUsage.used))")
                Spacer()
                Text("\(memoryManager.memoryUsage.percentage, specifier: "%.1f")%")
            }
            .font(.caption.monospacedDigit())
            
            ProgressView(value: memoryManager.memoryUsage.percentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: 
                    memoryManager.isLowMemoryMode ? .red : .blue
                ))
            
            if memoryManager.isLowMemoryMode {
                Text("Low Memory Mode Active")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - View Modifier for Memory Optimization

struct MemoryOptimizedModifier: ViewModifier {
    @StateObject private var memoryManager = MemoryManager.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: memoryManager.isLowMemoryMode) { _, isLowMemory in
                if isLowMemory {
                    // Reduce animations or disable effects
                    UIView.setAnimationsEnabled(false)
                } else {
                    UIView.setAnimationsEnabled(true)
                }
            }
    }
}

extension View {
    func memoryOptimized() -> some View {
        modifier(MemoryOptimizedModifier())
    }
}

#Preview("Memory Monitor") {
    MemoryMonitorView()
        .padding()
}