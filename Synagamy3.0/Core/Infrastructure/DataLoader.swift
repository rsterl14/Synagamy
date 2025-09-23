//
//  DataLoader.swift
//  Synagamy3.0
//
//  JSON loading utilities + in‑memory cache for app content.
//  - AppStore‑safe: no force‑unwraps, friendly fallbacks.
//  - Eager load (init) so views see data on first render.
//  - DEBUG diagnostics to spot bundling/decoding issues fast.
//

import Foundation
import SwiftUI

// Import model types for consolidated data loading
// Note: These should be relative imports within the same module

// MARK: - DataLoader

enum DataLoader {
    enum LoadError: Error {
        case missingResource(String)          // file not in bundle
        case readFailed(URL, underlying: Error)
        case decodeFailed(resource: String, underlying: Error)
        case emptyData(resource: String)      // file exists but is empty
        case invalidFormat(resource: String)   // not valid JSON
    }

    /// Strict loader (throws). Useful for tests or explicit error flows.
    static func load<T: Decodable>(_ type: T.Type, named resource: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            #if DEBUG
            debugPrint("⚠️ DataLoader: missing resource \(resource).json in app bundle.")
            #endif
            // Don't trigger error handler for missing local files - this is expected
            // since we're using remote data now
            throw LoadError.missingResource(resource)
        }

        do {
            let data = try Data(contentsOf: url)
            
            // Check for empty data
            guard !data.isEmpty else {
                #if DEBUG
                debugPrint("⚠️ DataLoader: \(resource).json is empty.")
                #endif
                // Don't trigger UI error handler for data issues during load
                throw LoadError.emptyData(resource: resource)
            }
            
            // Validate JSON format before decoding
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                #if DEBUG
                debugPrint("⚠️ DataLoader: \(resource).json contains invalid JSON.")
                #endif
                // Don't trigger UI error handler for data issues during load
                throw LoadError.invalidFormat(resource: resource)
            }
            
            #if DEBUG
            debugPrint("ℹ️ DataLoader: \(resource).json found (\(data.count) bytes).")
            #endif
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            #if DEBUG
            debugPrint("❌ DataLoader: decode failed for \(resource).json — \(error)")
            #endif
            
            // Create detailed error message for different decoding failures
            let details = decodeErrorDetails(error)
            #if DEBUG
            debugPrint("❌ DataLoader: Decoding error - \(details)")
            #endif
            
            throw LoadError.decodeFailed(resource: resource, underlying: error)
            
        } catch let loadError as LoadError {
            // Re-throw our custom LoadError types
            throw loadError
            
        } catch {
            #if DEBUG
            debugPrint("❌ DataLoader: read failed for \(resource).json — \(error)")
            #endif
            
            throw LoadError.readFailed(url, underlying: error)
        }
    }

    /// Non‑throwing convenience that returns Result.
    static func loadResult<T: Decodable>(_ type: T.Type, named resource: String) -> Result<T, Error> {
        do { 
            return .success(try load(type, named: resource)) 
        } catch { 
            return .failure(error) 
        }
    }

    /// Silent‑fallback array loader (keeps UI resilient).
    /// In DEBUG it logs *why* you got an empty array.
    static func loadArray<T: Decodable>(_ type: [T].Type, named resource: String) -> [T] {
        switch loadResult(type, named: resource) {
        case .success(let array):
            #if DEBUG
            debugPrint("✅ DataLoader: \(resource).json decoded \(array.count) item(s).")
            #endif
            
            // Validate array content
            if array.isEmpty {
                #if DEBUG
                debugPrint("⚠️ DataLoader: \(resource).json decoded successfully but contains no items.")
                #endif
                // Don't trigger UI errors for empty data during initial load
            }
            
            return array
            
        case .failure(let error):
            #if DEBUG
            debugPrint("⚠️ DataLoader: returning [] for \(resource).json due to error: \(error)")
            #endif
            
            // Don't trigger UI errors during initial data load
            // The app will use remote data instead
            
            return []
        }
    }
    
    /// Safe loader with retry mechanism
    static func loadWithRetry<T: Decodable>(
        _ type: T.Type, 
        named resource: String, 
        maxRetries: Int = 3
    ) -> T? {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            switch loadResult(type, named: resource) {
            case .success(let result):
                #if DEBUG
                if attempt > 1 {
                    debugPrint("✅ DataLoader: \(resource).json loaded successfully on attempt \(attempt)")
                }
                #endif
                return result
                
            case .failure(let error):
                lastError = error
                #if DEBUG
                debugPrint("⚠️ DataLoader: attempt \(attempt)/\(maxRetries) failed for \(resource).json")
                #endif
                
                // Brief delay before retry (except on last attempt)
                if attempt < maxRetries {
                    Thread.sleep(forTimeInterval: 0.1 * Double(attempt))
                }
            }
        }
        
        // All retries failed
        #if DEBUG
        if let error = lastError {
            debugPrint("⚠️ DataLoader: All retries failed for \(resource): \(error)")
        }
        #endif
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    /// Extracts meaningful error details from DecodingError
    private static func decodeErrorDetails(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            return "Type mismatch: expected \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            
        case .valueNotFound(let type, let context):
            return "Missing required value of type \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            
        case .keyNotFound(let key, let context):
            return "Missing required key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            
        case .dataCorrupted(let context):
            return "Data corrupted at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)"
            
        @unknown default:
            return "Unknown decoding error: \(error.localizedDescription)"
        }
    }
    
    /// Validates data content before processing
    static func validateContent<T: Collection>(_ content: T, resource: String) -> Bool {
        guard !content.isEmpty else {
            #if DEBUG
            debugPrint("⚠️ DataLoader: Content is empty for \(resource)")
            #endif
            return false
        }
        return true
    }
}

// MARK: - AppData (facade) & AppDataStore (cache)

/// Simple facade so views can read static arrays without holding references.
enum AppData {
    /// Topics backing Education + Topic detail.
    @MainActor static var topics: [EducationTopic] { AppDataStore.shared.topics }
    /// Categories/paths/steps backing Pathways.
    @MainActor static var pathways: PathwayData { AppDataStore.shared.pathwayData }
    @MainActor static var pathwayCategories: [PathwayCategory] { AppDataStore.shared.pathwayData.categories }
    @MainActor static var pathwayPaths: [PathwayPath] { AppDataStore.shared.pathwayPaths }
    /// FAQ items backing Common Questions.
    @MainActor static var questions: [CommonQuestion] { AppDataStore.shared.questions }
    /// Resources for external tools and links.
    @MainActor static var resources: [Resource] { AppDataStore.shared.resources }
    /// Infertility information and guidance.
    // Note: InfertilityInfo temporarily commented out for compilation
    // @MainActor static var infertilityInfo: [InfertilityInfo] { AppDataStore.shared.infertilityInfo }

    /// Manual reload hook if you ever support pull‑to‑refresh or remote updates.
    @MainActor static func reload() { AppDataStore.shared.reloadAll() }
}

/// Singleton in‑memory cache. Now supports both local and remote data loading.
/// Maintains the same interface for existing views while adding network capabilities.
@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    // Cached content
    @Published private(set) var topics: [EducationTopic] = []
    @Published private(set) var questions: [CommonQuestion] = []
    @Published private(set) var pathwayData: PathwayData = PathwayData(categories: [], paths: [])
    @Published private(set) var pathwayPaths: [PathwayPath] = []
    @Published private(set) var resources: [Resource] = []
    // Note: InfertilityInfo temporarily commented out for compilation
    // @Published private(set) var infertilityInfo: [InfertilityInfo] = []

    // Cache timestamps for invalidation (merged from DataCache)
    private var topicsTimestamp: Date?
    private var questionsTimestamp: Date?
    private var pathwayDataTimestamp: Date?
    private var resourcesTimestamp: Date?
    // private var infertilityInfoTimestamp: Date?

    // Loading states
    @Published private(set) var isLoadingRemoteData = false
    @Published private(set) var lastRemoteUpdate: Date?
    @Published private(set) var useRemoteData = true // Can be toggled for testing

    // Cache configuration (merged from DataCache)
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    private let remoteDataService = RemoteDataService.shared

    // Restrict construction — everyone uses `shared`.
    private init() {
        #if DEBUG
        print("🏗️ AppDataStore: Initializing...")
        #endif
        
        // ✅ CRITICAL: eager‑load once so Education/Pathways/Questions are populated
        // before any view accesses AppData.* during initial render.
        // Defer to avoid publishing during object initialization
        DispatchQueue.main.async {
            Task {
                await self.loadAllData()
            }
        }

        #if DEBUG
        print("🏁 AppDataStore: Init complete, starting async data load...")
        #endif
    }

    /// Loads all data with network-first, then local fallback
    private func loadAllData() async {
        isLoadingRemoteData = true
        defer { isLoadingRemoteData = false }
        
        if useRemoteData {
            // Try loading from network first
            await loadFromRemote()
        } else {
            // Load from local bundle only
            loadFromLocal()
        }
        
        lastRemoteUpdate = Date()
        
        #if DEBUG
        print("🏁 AppDataStore data load complete. topics=\(topics.count), pathways=\(pathwayData.categories.count), questions=\(questions.count), resources=\(resources.count)")
        #endif
    }
    
    /// Load data from remote service (with local fallback built-in)
    private func loadFromRemote() async {
        #if DEBUG
        print("🚀 AppDataStore: Starting remote data load...")
        #endif
        
        // Start loading all data concurrently with timeout
        let loadingTask = Task {
            async let loadedTopics = remoteDataService.loadEducationTopics()
            async let loadedQuestions = remoteDataService.loadCommonQuestions()
            async let loadedPathwayData = remoteDataService.loadPathways()
            async let loadedResources = remoteDataService.loadResources()
            async let loadedInfertilityInfo = remoteDataService.loadInfertilityInfo()
            
            // Wait for all loads to complete
            return await (loadedTopics, loadedQuestions, loadedPathwayData, loadedResources, loadedInfertilityInfo)
        }
        
        // Add timeout to prevent infinite loading
        let results: (topics: [EducationTopic], questions: [CommonQuestion], pathwayData: PathwayData?, resources: [Resource], infertilityInfo: [InfertilityInfo])
        
        do {
            results = try await withTimeout(seconds: 30) {
                await loadingTask.value
            }
        } catch {
            #if DEBUG
            print("⚠️ AppDataStore: Remote loading timed out or failed, using cached/empty data")
            #endif
            // Use cached data if available, otherwise empty
            return
        }
        
        #if DEBUG
        print("📊 AppDataStore: Remote load results:")
        print("   - Topics: \(results.0.count)")
        print("   - Questions: \(results.1.count)")
        print("   - Pathways: \(results.2?.categories.count ?? 0) categories")
        print("   - Resources: \(results.3.count)")
        print("   - Infertility Info: \(results.4.count)")
        #endif
        
        topics = results.0
        topicsTimestamp = Date()

        questions = results.1
        questionsTimestamp = Date()

        resources = results.3
        resourcesTimestamp = Date()

        // infertilityInfo = results.4
        // infertilityInfoTimestamp = Date()
        
        #if DEBUG
        if topics.isEmpty {
            print("🚨 AppDataStore: CRITICAL - Education topics array is empty after remote load!")
        }
        if questions.isEmpty {
            print("⚠️ AppDataStore: Warning - Questions array is empty after remote load")
        }
        if resources.isEmpty {
            print("⚠️ AppDataStore: Warning - Resources array is empty after remote load")
        }
        // if infertilityInfo.isEmpty {
        //     print("⚠️ AppDataStore: Warning - Infertility info array is empty after remote load")
        // }
        #endif
        
        if let pathwayData = results.2 {
            self.pathwayData = pathwayData
            pathwayDataTimestamp = Date()

            // Extract all paths from the data structure for easy access
            var allPaths: [PathwayPath] = []
            // Add paths directly in categories
            for category in pathwayData.categories {
                if let paths = category.paths {
                    allPaths.append(contentsOf: paths)
                }
            }
            // Add paths referenced in the separate paths array
            if let paths = pathwayData.paths {
                allPaths.append(contentsOf: paths)
            }
            pathwayPaths = allPaths
        } else {
            self.pathwayData = PathwayData(categories: [], paths: [])
            pathwayDataTimestamp = Date()
            pathwayPaths = []
        }
        
        validate()
    }

    /// Legacy method for local-only loading (kept for compatibility and offline fallback)
    func reloadAll() {
        Task {
            await loadAllData()
        }
    }
    
    /// Load from local bundle only (used as fallback or when remote is disabled)
    /// Note: Local JSON files have been removed - this returns empty data
    private func loadFromLocal() {
        #if DEBUG
        print("⚠️ AppDataStore: Local JSON files not available, returning empty data")
        #endif
        
        // Return empty data structures since local files are removed
        let loadedTopics: [EducationTopic] = []
        let loadedQuestions: [CommonQuestion] = []
        let loadedResources: [Resource] = []
        // let _: [InfertilityInfo] = [] // Placeholder for future infertility info
        
        // Set empty pathway data
        pathwayData = PathwayData(categories: [], paths: [])
        pathwayPaths = []

        // Assign empty arrays to cache and set timestamps
        topics = loadedTopics
        topicsTimestamp = Date()

        questions = loadedQuestions
        questionsTimestamp = Date()

        resources = loadedResources
        resourcesTimestamp = Date()

        // infertilityInfo = loadedInfertilityInfo
        // infertilityInfoTimestamp = Date()

        // Optional sanity logging
        #if DEBUG
        if topics.isEmpty { debugPrint("🔍 AppDataStore: topics is EMPTY") }
        if pathwayData.categories.isEmpty { debugPrint("🔍 AppDataStore: pathways is EMPTY") }
        if questions.isEmpty { debugPrint("🔍 AppDataStore: questions is EMPTY") }
        #endif

        validate()
    }
    
    /// Force refresh from remote (for pull-to-refresh)
    func refreshFromRemote() async {
        guard useRemoteData else { return }
        await loadFromRemote()
    }
    
    /// Toggle between remote and local data (for debugging/testing)
    func setUseRemoteData(_ enabled: Bool) {
        useRemoteData = enabled
        Task {
            await loadAllData()
        }
    }

    // MARK: - Cache Management (merged from DataCache)

    /// Check if cached data is still valid based on timestamp
    private func isCacheValid(timestamp: Date?) -> Bool {
        guard let timestamp = timestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheTimeout
    }

    /// Get cached topics if valid, otherwise trigger reload
    func getCachedTopics() -> [EducationTopic] {
        if isCacheValid(timestamp: topicsTimestamp) {
            return topics
        }
        // Cache expired, trigger reload
        Task { await loadAllData() }
        return topics // Return current data while reloading
    }

    /// Get cached questions if valid, otherwise trigger reload
    func getCachedQuestions() -> [CommonQuestion] {
        if isCacheValid(timestamp: questionsTimestamp) {
            return questions
        }
        Task { await loadAllData() }
        return questions
    }

    /// Get cached resources if valid, otherwise trigger reload
    func getCachedResources() -> [Resource] {
        if isCacheValid(timestamp: resourcesTimestamp) {
            return resources
        }
        Task { await loadAllData() }
        return resources
    }

    /// Get cached pathway categories if valid, otherwise trigger reload
    func getCachedPathwayCategories() -> [PathwayCategory] {
        if isCacheValid(timestamp: pathwayDataTimestamp) {
            return pathwayData.categories
        }
        Task { await loadAllData() }
        return pathwayData.categories
    }

    /// Invalidate all caches and force reload
    func invalidateAllCaches() {
        topicsTimestamp = nil
        questionsTimestamp = nil
        pathwayDataTimestamp = nil
        resourcesTimestamp = nil
        // infertilityInfoTimestamp = nil

        Task { await loadAllData() }
    }

    /// Invalidate specific data type caches
    func invalidateTopicsCache() {
        topicsTimestamp = nil
        Task { await loadAllData() }
    }

    func invalidateQuestionsCache() {
        questionsTimestamp = nil
        Task { await loadAllData() }
    }

    func invalidateResourcesCache() {
        resourcesTimestamp = nil
        Task { await loadAllData() }
    }

    func invalidatePathwaysCache() {
        pathwayDataTimestamp = nil
        Task { await loadAllData() }
    }

    /// Clear expired caches without triggering reload
    func clearExpiredCaches() {
        let now = Date()

        if let timestamp = topicsTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            topicsTimestamp = nil
        }

        if let timestamp = questionsTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            questionsTimestamp = nil
        }

        if let timestamp = pathwayDataTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            pathwayDataTimestamp = nil
        }

        if let timestamp = resourcesTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            resourcesTimestamp = nil
        }

        // if let timestamp = infertilityInfoTimestamp,
        //    now.timeIntervalSince(timestamp) >= cacheTimeout {
        //     infertilityInfoTimestamp = nil
        // }
    }

    /// Validate content assumptions and log (never crash in production).
    func validate() {
        #if DEBUG
        // Example: warn on duplicate topic IDs (topic names must be unique).
        let topicIDs = topics.map { $0.id }
        let dupTopicIDs = Dictionary(grouping: topicIDs, by: { $0 }).filter { $1.count > 1 }.keys
        if !dupTopicIDs.isEmpty {
            debugPrint("⚠️ AppDataStore.validate: duplicate topic IDs → \(dupTopicIDs.joined(separator: ", "))")
        }

        for c in pathwayData.categories {
            if c.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                debugPrint("⚠️ AppDataStore.validate: empty category title for id=\(c.id)")
            }
            if let paths = c.paths {
                for p in paths {
                    if p.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        debugPrint("⚠️ AppDataStore.validate: empty path title for id=\(p.id)")
                    }
                    if p.steps.isEmpty {
                        debugPrint("⚠️ AppDataStore.validate: path has 0 steps for id=\(p.id)")
                    }
                }
            }
        }
        #endif
    }
}

// MARK: - Convenient View Extensions (merged from DataCache)

extension View {
    /// Provides optimized data access through the unified AppDataStore
    func withUnifiedDataLoader() -> some View {
        environmentObject(AppDataStore.shared)
    }
}
