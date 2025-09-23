//
//  AppEnvironment.swift
//  Synagamy3.0
//
//  Centralized app environment that manages shared services and reduces
//  memory pressure from multiple @StateObject instances.
//
//  Features:
//  - Single instances of shared services
//  - Environment injection for better performance
//  - Memory pressure monitoring
//  - Lifecycle management for services
//

import SwiftUI
import Combine
import os.log

// MARK: - App Environment

@MainActor
final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()

    // MARK: - Shared Services (Single Instances)

    let networkManager = NetworkStatusManager.shared
    let remoteDataService = RemoteDataService.shared
    let unifiedErrorManager = UnifiedErrorManager.shared
    let memoryManager = MemoryManager.shared
    let offlineDataManager = OfflineDataManager.shared

    // Medical data services
    let consentManager = MedicalDataConsentManager.shared
    let persistenceService = PredictionPersistenceService.shared

    // MARK: - Performance Monitoring

    @Published private(set) var memoryUsage: Double = 0.0
    @Published private(set) var isLowMemoryMode = false
    @Published private(set) var performanceStats = PerformanceStats()

    // MARK: - Service Status

    @Published private(set) var servicesInitialized = false
    @Published private(set) var criticalServicesReady = false

    private let logger = Logger(subsystem: "com.synagamy.app", category: "AppEnvironment")
    private var cancellables = Set<AnyCancellable>()
    private var memoryTimer: Timer?

    struct PerformanceStats {
        var memoryUsageBytes: UInt64 = 0
        var cpuUsage: Double = 0.0
        var activeViewCount: Int = 0
        var networkOperationsCount: Int = 0
        var lastMemoryWarning: Date?

        var memoryUsageMB: Double {
            Double(memoryUsageBytes) / (1024 * 1024)
        }
    }

    private init() {
        setupPerformanceMonitoring()
        initializeServices()
    }

    // MARK: - Service Management

    private func initializeServices() {
        logger.info("🚀 AppEnvironment: Initializing shared services...")

        // Start with critical services
        initializeCriticalServices()

        // Then initialize secondary services
        Task {
            await initializeSecondaryServices()
        }
    }

    private func initializeCriticalServices() {
        // Network monitoring (critical for offline handling)
        _ = networkManager

        // Error handling (critical for user experience)
        _ = unifiedErrorManager

        // Memory management (critical for performance)
        _ = memoryManager

        criticalServicesReady = true

        logger.info("✅ AppEnvironment: Critical services initialized")
    }

    private func initializeSecondaryServices() async {
        // Data services (can be lazy loaded)
        _ = remoteDataService
        _ = offlineDataManager

        // Medical data services (user-dependent)
        _ = consentManager
        _ = persistenceService

        await MainActor.run {
            servicesInitialized = true
            logger.info("✅ AppEnvironment: All services initialized")
        }
    }

    // MARK: - Performance Monitoring

    private func setupPerformanceMonitoring() {
        // Monitor memory usage every 5 seconds
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.updateMemoryStats()
            }
        }

        // Listen for memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.handleMemoryWarning()
                }
            }
            .store(in: &cancellables)

        // Monitor app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.handleAppBackgrounded()
                }
            }
            .store(in: &cancellables)
    }

    private func updateMemoryStats() {
        let memoryInfo = MemoryManager.getMemoryInfo()
        memoryUsage = Double(memoryInfo.used) / Double(memoryInfo.total)

        performanceStats.memoryUsageBytes = memoryInfo.used

        // Enable low memory mode if usage > 80%
        let newLowMemoryMode = memoryUsage > 0.8
        if newLowMemoryMode != isLowMemoryMode {
            isLowMemoryMode = newLowMemoryMode

            if isLowMemoryMode {
                logger.warning("⚠️ AppEnvironment: Entering low memory mode (\(String(format: "%.1f", self.memoryUsage * 100))%)")
                handleLowMemoryCondition()
            } else {
                logger.info("✅ AppEnvironment: Exiting low memory mode")
            }
        }
    }

    private func handleMemoryWarning() {
        logger.warning("🚨 AppEnvironment: Memory warning received")

        performanceStats.lastMemoryWarning = Date()
        isLowMemoryMode = true

        // Aggressive memory cleanup
        handleLowMemoryCondition()

        // Clear caches using available methods
        URLCache.shared.removeAllCachedResponses()
        Task {
            await offlineDataManager.clearOfflineData()
        }

        // Trigger memory optimization through existing memory manager
        // The MemoryManager already handles memory pressure automatically
    }

    private func handleLowMemoryCondition() {
        logger.info("🧹 AppEnvironment: Performing memory optimization...")

        // Clear non-essential caches
        URLCache.shared.removeAllCachedResponses()
        ImageCache.shared.enableLowMemoryMode()
        PredictionCache.shared.clearOldPredictions()

        // Notify services to reduce memory usage
        NotificationCenter.default.post(name: .lowMemoryMode, object: nil)
    }

    private func handleAppBackgrounded() {
        logger.info("📱 AppEnvironment: App backgrounded, optimizing memory...")

        // Proactive memory cleanup when app goes to background
        ImageCache.shared.clearUnusedImages()
        PredictionCache.shared.clearOldPredictions()

        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: - View Lifecycle Tracking

    func viewDidAppear(_ viewName: String) {
        performanceStats.activeViewCount += 1
        logger.debug("📱 View appeared: \(viewName) (Active: \(self.performanceStats.activeViewCount))")
    }

    func viewDidDisappear(_ viewName: String) {
        performanceStats.activeViewCount = max(0, performanceStats.activeViewCount - 1)
        logger.debug("📱 View disappeared: \(viewName) (Active: \(self.performanceStats.activeViewCount))")
    }

    func networkOperationStarted() {
        performanceStats.networkOperationsCount += 1
    }

    func networkOperationCompleted() {
        performanceStats.networkOperationsCount = max(0, performanceStats.networkOperationsCount - 1)
    }

    // MARK: - Debug Information

    func getPerformanceReport() -> String {
        return """
        📊 App Environment Performance Report

        Memory Usage: \(String(format: "%.1f", memoryUsage * 100))%
        Memory (MB): \(String(format: "%.1f", performanceStats.memoryUsageMB))
        Low Memory Mode: \(isLowMemoryMode ? "YES" : "NO")
        Active Views: \(performanceStats.activeViewCount)
        Network Operations: \(performanceStats.networkOperationsCount)

        Services Status:
        - Critical Services: \(criticalServicesReady ? "✅" : "❌")
        - All Services: \(servicesInitialized ? "✅" : "❌")

        Last Memory Warning: \(performanceStats.lastMemoryWarning?.formatted() ?? "None")
        """
    }

    deinit {
        memoryTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Environment Extensions

extension AppEnvironment {
    /// Get shared service instances optimized for performance
    nonisolated var sharedServices: SharedServices {
        SharedServices(
            networkManager: networkManager,
            remoteDataService: remoteDataService,
            unifiedErrorManager: unifiedErrorManager,
            memoryManager: memoryManager,
            offlineDataManager: offlineDataManager,
            consentManager: consentManager,
            persistenceService: persistenceService
        )
    }
}

struct SharedServices {
    let networkManager: NetworkStatusManager
    let remoteDataService: RemoteDataService
    let unifiedErrorManager: UnifiedErrorManager
    let memoryManager: MemoryManager
    let offlineDataManager: OfflineDataManager
    let consentManager: MedicalDataConsentManager
    let persistenceService: PredictionPersistenceService
}

// MARK: - Environment Keys

struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.shared
}

struct SharedServicesKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.shared.sharedServices
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }

    var sharedServices: SharedServices {
        get { self[SharedServicesKey.self] }
        set { self[SharedServicesKey.self] = newValue }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let lowMemoryMode = Notification.Name("lowMemoryMode")
    static let performanceStatsUpdated = Notification.Name("performanceStatsUpdated")
}

// MARK: - View Modifiers

struct PerformanceTracking: ViewModifier {
    let viewName: String
    @Environment(\.appEnvironment) private var appEnvironment

    func body(content: Content) -> some View {
        content
            .onAppear {
                appEnvironment.viewDidAppear(viewName)
            }
            .onDisappear {
                appEnvironment.viewDidDisappear(viewName)
            }
    }
}

extension View {
    func trackPerformance(viewName: String) -> some View {
        modifier(PerformanceTracking(viewName: viewName))
    }
}