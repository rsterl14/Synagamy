//
//  PerformanceMonitor.swift
//  Synagamy3.0
//
//  Development-time performance monitoring utilities to identify bottlenecks,
//  memory usage, and rendering performance issues in SwiftUI views.
//

import SwiftUI
import Combine
import os.log

/// Performance monitoring system for development builds
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    // MARK: - Configuration
    #if DEBUG
    private let isEnabled = true
    #else
    private let isEnabled = false
    #endif
    
    // MARK: - Metrics
    @Published var currentMetrics = PerformanceMetrics()
    private var viewRenderTimes: [String: CFTimeInterval] = [:]
    private var memoryWarningCount = 0
    
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.synagamy.app", category: "Performance")
    
    private init() {
        setupMemoryMonitoring()
    }
    
    // MARK: - Public Interface
    func startTiming(_ operation: String) -> CFTimeInterval {
        guard isEnabled else { return 0 }
        return CACurrentMediaTime()
    }
    
    func endTiming(_ operation: String, startTime: CFTimeInterval) {
        guard isEnabled else { return }
        let duration = CACurrentMediaTime() - startTime
        
        if duration > 0.016 { // Warn if operation takes longer than 1 frame (60fps)
            logger.warning("Slow operation '\(operation)': \(duration * 1000, format: .fixed(precision: 2))ms")
        }
        
        viewRenderTimes[operation] = duration
    }
    
    func measureBlock<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let startTime = startTiming(operation)
        defer { endTiming(operation, startTime: startTime) }
        return try block()
    }
    
    func measureAsyncBlock<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let startTime = startTiming(operation)
        defer { endTiming(operation, startTime: startTime) }
        return try await block()
    }
    
    // MARK: - Memory Monitoring
    private func setupMemoryMonitoring() {
        guard isEnabled else { return }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        // Periodic memory checks
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateMemoryMetrics()
        }
    }
    
    private func handleMemoryWarning() {
        memoryWarningCount += 1
        logger.critical("Memory warning received! Count: \(self.memoryWarningCount)")
        
        // Clear performance caches
        viewRenderTimes.removeAll()
        
        // Notify cache systems to clean up
        Task { @MainActor in
            DataCache.shared.clearExpiredCaches()
        }
    }
    
    private func updateMemoryMetrics() {
        let memoryUsage = getMemoryUsage()
        currentMetrics.memoryUsageMB = memoryUsage
        
        if memoryUsage > 100 { // Warn if over 100MB
            logger.warning("High memory usage: \(memoryUsage, format: .fixed(precision: 1))MB")
        }
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0
    }
    
    // MARK: - Render Performance
    func trackViewRender<Content: View>(_ viewName: String, @ViewBuilder content: () -> Content) -> AnyView {
        guard isEnabled else { return AnyView(content()) }
        
        return AnyView(
            content()
                .onAppear {
                    let startTime = CACurrentMediaTime()
                    DispatchQueue.main.async {
                        let renderTime = CACurrentMediaTime() - startTime
                        self.viewRenderTimes[viewName] = renderTime
                        
                        if renderTime > 0.016 {
                            self.logger.warning("Slow view render '\(viewName)': \(renderTime * 1000, format: .fixed(precision: 2))ms")
                        }
                    }
                }
        )
    }
    
    // MARK: - Diagnostics
    func printDiagnostics() {
        guard isEnabled else { return }
        
        logger.info("=== Performance Diagnostics ===")
        logger.info("Memory Usage: \(self.currentMetrics.memoryUsageMB, format: .fixed(precision: 1))MB")
        logger.info("Memory Warnings: \(self.memoryWarningCount)")
        
        if !viewRenderTimes.isEmpty {
            logger.info("Slow View Renders:")
            for (view, time) in viewRenderTimes.sorted(by: { $0.value > $1.value }).prefix(10) {
                if time > 0.016 {
                    logger.info("  \(view): \(time * 1000, format: .fixed(precision: 2))ms")
                }
            }
        }
    }
}

// MARK: - Performance Metrics Model
struct PerformanceMetrics {
    var memoryUsageMB: Double = 0
    var lastRenderTime: CFTimeInterval = 0
    var averageRenderTime: CFTimeInterval = 0
}

// MARK: - SwiftUI View Extensions
extension View {
    /// Tracks performance metrics for this view
    func trackPerformance(_ viewName: String) -> some View {
        PerformanceMonitor.shared.trackViewRender(viewName) {
            self
        }
    }
    
    /// Measures the time it takes to execute a closure
    func measureTime<T>(_ operation: String, _ closure: () -> T) -> T {
        PerformanceMonitor.shared.measureBlock(operation, block: closure)
    }
}

// MARK: - ViewModifier for Performance Tracking
struct PerformanceTrackingModifier: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content.trackPerformance(viewName)
    }
}

extension View {
    func performanceTracked(_ viewName: String) -> some View {
        modifier(PerformanceTrackingModifier(viewName: viewName))
    }
}