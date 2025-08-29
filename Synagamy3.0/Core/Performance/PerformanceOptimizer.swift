//
//  PerformanceOptimizer.swift
//  Synagamy3.0
//
//  Performance monitoring and optimization utilities.
//

import SwiftUI
import Combine

// MARK: - Extended Performance Metrics

extension PerformanceMetrics {
    var calculationTimes: [String: TimeInterval] {
        get { [:] } // Use existing metrics
        set { } // No-op since we use existing system
    }
}

// MARK: - Performance Monitor

@MainActor
class AppPerformanceMonitor: ObservableObject {
    @Published var metrics = PerformanceMetrics()
    @Published var slowOperations: [String] = []
    
    private var startTimes: [String: Date] = [:]
    private let warningThreshold: TimeInterval = 0.5 // 500ms
    private let criticalThreshold: TimeInterval = 1.0 // 1 second
    
    // MARK: - Timing Operations
    
    func startTiming(_ operation: String) {
        startTimes[operation] = Date()
    }
    
    func endTiming(_ operation: String, category: PerformanceCategory = .general) {
        guard let startTime = startTimes[operation] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        startTimes.removeValue(forKey: operation)
        
        switch category {
        case .viewLoad:
            metrics.lastRenderTime = duration
            if metrics.averageRenderTime == 0 {
                metrics.averageRenderTime = duration
            } else {
                metrics.averageRenderTime = (metrics.averageRenderTime + duration) / 2.0
            }
        case .calculation:
            metrics.calculationTimes[operation] = duration
        case .general:
            break
        }
        
        // Track slow operations
        if duration > warningThreshold {
            slowOperations.append("\(operation): \(String(format: "%.3f", duration))s")
            
            // Keep only recent slow operations
            if slowOperations.count > 10 {
                slowOperations = Array(slowOperations.suffix(10))
            }
        }
        
        // Log critical performance issues
        if duration > criticalThreshold {
            print("⚠️ Performance Warning: \(operation) took \(String(format: "%.3f", duration))s")
        }
    }
    
    func measureAsync<T>(_ operation: String, work: @escaping () async throws -> T) async rethrows -> T {
        let start = Date()
        let result = try await work()
        let duration = Date().timeIntervalSince(start)
        
        metrics.calculationTimes[operation] = duration
        
        if duration > warningThreshold {
            slowOperations.append("\(operation): \(String(format: "%.3f", duration))s")
        }
        
        return result
    }
}

enum PerformanceCategory {
    case viewLoad
    case calculation
    case general
}

// MARK: - Memory Management

class MemoryManager: ObservableObject {
    @Published var memoryWarnings: [String] = []
    
    private let warningThresholdMB: Double = 150.0
    private let criticalThresholdMB: Double = 200.0
    
    func checkMemoryUsage() {
        let memoryUsage = getCurrentMemoryUsage()
        
        if memoryUsage > criticalThresholdMB {
            memoryWarnings.append("Critical memory usage: \(String(format: "%.1f", memoryUsage))MB")
            triggerMemoryCleanup()
        } else if memoryUsage > warningThresholdMB {
            memoryWarnings.append("High memory usage: \(String(format: "%.1f", memoryUsage))MB")
        }
        
        // Keep only recent warnings
        if memoryWarnings.count > 5 {
            memoryWarnings = Array(memoryWarnings.suffix(5))
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        }
        return 0
    }
    
    private func triggerMemoryCleanup() {
        // Clear caches, images, etc.
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
    }
}

// MARK: - Image Optimization

@MainActor
class ImageOptimizer: ObservableObject {
    private var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.countLimit = 100 // Maximum 100 images
        return cache
    }()
    
    func optimizedImage(named: String, maxWidth: CGFloat = 300) -> UIImage? {
        let cacheKey = "\(named)_\(Int(maxWidth))" as NSString
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Load and resize image
        guard let originalImage = UIImage(named: named) else { return nil }
        
        let optimizedImage = resizeImage(originalImage, maxWidth: maxWidth)
        
        // Cache the optimized image
        imageCache.setObject(optimizedImage, forKey: cacheKey)
        
        return optimizedImage
    }
    
    private func resizeImage(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        let originalSize = image.size
        
        // Calculate new size maintaining aspect ratio
        let ratio = maxWidth / originalSize.width
        let newHeight = originalSize.height * ratio
        let newSize = CGSize(width: maxWidth, height: newHeight)
        
        // Only resize if necessary
        if originalSize.width <= maxWidth {
            return image
        }
        
        // Create optimized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
}

// MARK: - Lazy Loading Components

struct LazyImage: View {
    let imageName: String
    let maxWidth: CGFloat
    
    @StateObject private var imageOptimizer = ImageOptimizer()
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            let optimizedImage = await Task.detached {
                return await MainActor.run {
                    return imageOptimizer.optimizedImage(named: imageName, maxWidth: maxWidth)
                }
            }.value
            
            await MainActor.run {
                self.image = optimizedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - View Performance Extensions

extension View {
    func optimizedRedrawing() -> some View {
        self
            .drawingGroup() // Flatten view hierarchy for complex views
    }
    
    func memoryEfficient() -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: .memoryWarning)) { _ in
                // Handle memory warning by clearing caches, etc.
            }
    }
}

// MARK: - Batch Updates

class BatchUpdater<T>: ObservableObject {
    @Published private(set) var items: [T] = []
    
    private var pendingItems: [T] = []
    private var updateTimer: Timer?
    private let batchInterval: TimeInterval = 0.1 // 100ms batching
    
    func add(_ item: T) {
        pendingItems.append(item)
        scheduleUpdate()
    }
    
    func addBatch(_ newItems: [T]) {
        pendingItems.append(contentsOf: newItems)
        scheduleUpdate()
    }
    
    private func scheduleUpdate() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { _ in
            self.flushUpdates()
        }
    }
    
    private func flushUpdates() {
        guard !pendingItems.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            items.append(contentsOf: pendingItems)
            pendingItems.removeAll()
        }
    }
    
    func clear() {
        pendingItems.removeAll()
        items.removeAll()
    }
}

// MARK: - Calculation Optimization

struct OptimizedCalculationResult<T> {
    let result: T
    let cached: Bool
    let calculationTime: TimeInterval
}

actor CalculationCache<Key: Hashable, Value> {
    private var cache: [Key: (value: Value, timestamp: Date)] = [:]
    private let maxAge: TimeInterval = 300 // 5 minutes
    private let maxSize = 100
    
    func get(for key: Key) -> Value? {
        // Clean expired entries
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) < maxAge }
        
        return cache[key]?.value
    }
    
    func set(_ value: Value, for key: Key) {
        // Remove oldest entry if at capacity
        if cache.count >= maxSize {
            let oldestKey = cache.min { a, b in
                a.value.timestamp < b.value.timestamp
            }?.key
            
            if let oldestKey = oldestKey {
                cache.removeValue(forKey: oldestKey)
            }
        }
        
        cache[key] = (value, Date())
    }
    
    func clear() {
        cache.removeAll()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let memoryWarning = Notification.Name("memoryWarning")
    static let performanceWarning = Notification.Name("performanceWarning")
}