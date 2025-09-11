//
//  RemoteDataService.swift
//  Synagamy3.0
//
//  Network service for loading JSON data from GitHub repository.
//  Provides caching, offline fallback, and automatic updates.
//

import Foundation
import SwiftUI

// MARK: - Remote Data Service

/// Service responsible for fetching and caching JSON data from GitHub
@MainActor
final class RemoteDataService: ObservableObject {
    static let shared = RemoteDataService()
    
    // MARK: - Properties
    
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdateDate: Date?
    @Published private(set) var connectionStatus: ConnectionStatus = .unknown
    
    private let session = URLSession.shared
    private let cacheManager = DataCacheManager.shared
    
    // MARK: - Configuration
    
    private enum Config {
        static let baseURL = "https://raw.githubusercontent.com/rsterl14/fertility-data/main/data"
        static let requestTimeout: TimeInterval = 30.0
        static let cacheExpirationTime: TimeInterval = 3600 // 1 hour
        static let retryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
    }
    
    enum ConnectionStatus: Equatable {
        case unknown
        case connected
        case offline
        case error(String)
    }
    
    // MARK: - Data URLs
    
    private enum DataEndpoints {
        static let educationTopics = "\(Config.baseURL)/Education_Topics.json"
        static let commonQuestions = "\(Config.baseURL)/CommonQuestions.json"
        static let infertilityInfo = "\(Config.baseURL)/infertility_info.json"
        static let pathways = "\(Config.baseURL)/Pathways.json"
        static let resources = "\(Config.baseURL)/resources.json"
    }
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        print("🌐 RemoteDataService: Initializing...")
        #endif
        
        // Check initial connectivity
        Task {
            await checkConnectivity()
        }
        
        #if DEBUG
        print("🌐 RemoteDataService: Init complete, starting connectivity check...")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Load education topics with network/cache fallback
    func loadEducationTopics() async -> [EducationTopic] {
        #if DEBUG
        print("🔍 RemoteDataService: Starting to load education topics...")
        print("📡 URL: \(DataEndpoints.educationTopics)")
        print("🌐 Connection Status: \(connectionStatus)")
        #endif
        
        let result: [EducationTopic] = await loadData(
            [EducationTopic].self,
            from: DataEndpoints.educationTopics,
            cacheKey: "education_topics",
            localFallback: "Education_Topics"
        )
        
        #if DEBUG
        print("✅ RemoteDataService: Loaded \(result.count) education topics")
        if result.isEmpty {
            print("⚠️ RemoteDataService: Education topics array is EMPTY - this indicates a loading failure")
        }
        #endif
        
        return result
    }
    
    /// Load common questions with network/cache fallback
    func loadCommonQuestions() async -> [CommonQuestion] {
        await loadData(
            [CommonQuestion].self,
            from: DataEndpoints.commonQuestions,
            cacheKey: "common_questions",
            localFallback: "CommonQuestions"
        )
    }
    
    /// Load pathways data with network/cache fallback
    func loadPathways() async -> PathwayData? {
        await loadData(
            PathwayData.self,
            from: DataEndpoints.pathways,
            cacheKey: "pathways",
            localFallback: "Pathways"
        )
    }
    
    /// Load infertility information
    func loadInfertilityInfo() async -> [InfertilityInfo] {
        await loadData(
            [InfertilityInfo].self,
            from: DataEndpoints.infertilityInfo,
            cacheKey: "infertility_info",
            localFallback: "infertility_info"
        )
    }
    
    /// Load resources data
    func loadResources() async -> [Resource] {
        await loadData(
            [Resource].self,
            from: DataEndpoints.resources,
            cacheKey: "resources",
            localFallback: "resources"
        )
    }
    
    /// Force refresh all data from network
    func refreshAllData() async {
        isLoading = true
        defer { isLoading = false }
        
        await checkConnectivity()
        
        // Load all data types concurrently
        async let topics = loadEducationTopics()
        async let questions = loadCommonQuestions()
        async let pathways = loadPathways()
        async let infertility = loadInfertilityInfo()
        async let resources = loadResources()
        
        // Wait for completion
        let _ = await (topics, questions, pathways, infertility, resources)
        
        lastUpdateDate = Date()
        
        #if DEBUG
        print("✅ RemoteDataService: All data refreshed successfully")
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Generic data loading with network/cache/local fallback
    private func loadData<T: Codable>(
        _ type: T.Type,
        from urlString: String,
        cacheKey: String,
        localFallback: String
    ) async -> T {
        #if DEBUG
        print("🔄 loadData: Attempting to load \(type) from \(urlString)")
        print("🔄 loadData: Cache key: \(cacheKey)")
        print("🔄 loadData: Connection status: \(connectionStatus)")
        #endif
        
        // First, try loading from network
        if connectionStatus == .connected || connectionStatus == .unknown {
            #if DEBUG
            print("🌐 loadData: Attempting network fetch...")
            #endif
            
            if let networkData = await fetchFromNetwork(type, from: urlString) {
                #if DEBUG
                print("✅ loadData: Successfully loaded from network")
                #endif
                // Cache the fresh data
                cacheManager.cache(networkData, forKey: cacheKey)
                return networkData
            } else {
                #if DEBUG
                print("❌ loadData: Network fetch failed")
                #endif
            }
        } else {
            #if DEBUG
            print("⚠️ loadData: Skipping network fetch due to connection status: \(connectionStatus)")
            #endif
        }
        
        // Next, try loading from cache
        #if DEBUG
        print("💾 loadData: Attempting to retrieve from cache...")
        #endif
        
        if let cachedData = cacheManager.retrieve(type, forKey: cacheKey) {
            #if DEBUG
            print("✅ loadData: Successfully loaded from cache for \(cacheKey)")
            #endif
            return cachedData
        } else {
            #if DEBUG
            print("❌ loadData: No cached data available for \(cacheKey)")
            #endif
        }
        
        // Finally, return empty data structures (no local files available)
        #if DEBUG
        print("📱 No local fallback available for \(localFallback), returning empty data")
        #endif
        
        if type == [EducationTopic].self {
            return [] as! T
        } else if type == [CommonQuestion].self {
            return [] as! T
        } else if type == PathwayData.self {
            return PathwayData(categories: [], paths: []) as! T
        } else if type == [InfertilityInfo].self {
            return [] as! T
        } else if type == [Resource].self {
            return [] as! T
        } else {
            // For unknown types, we'll have to fail gracefully
            #if DEBUG
            print("⚠️ Unable to provide empty fallback for unknown type \(type)")
            #endif
            fatalError("Unable to load data of type \(type) - no network, cache, or local fallback available")
        }
    }
    
    /// Fetch data from network with retry logic
    private func fetchFromNetwork<T: Codable>(_ type: T.Type, from urlString: String) async -> T? {
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("❌ Invalid URL: \(urlString)")
            #endif
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = Config.requestTimeout
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Synagamy-iOS", forHTTPHeaderField: "User-Agent")
        
        for attempt in 1...Config.retryAttempts {
            #if DEBUG
            print("🔄 fetchFromNetwork: Attempt \(attempt)/\(Config.retryAttempts) for \(url.lastPathComponent)")
            #endif
            
            do {
                let (data, response) = try await session.data(for: request)
                
                #if DEBUG
                print("📦 fetchFromNetwork: Received \(data.count) bytes")
                #endif
                
                // Check HTTP status
                if let httpResponse = response as? HTTPURLResponse {
                    #if DEBUG
                    print("📡 fetchFromNetwork: HTTP \(httpResponse.statusCode) for \(url.lastPathComponent)")
                    #endif
                    
                    guard httpResponse.statusCode == 200 else {
                        #if DEBUG
                        print("❌ fetchFromNetwork: HTTP \(httpResponse.statusCode) error for \(url.lastPathComponent)")
                        print("📄 fetchFromNetwork: Response headers: \(httpResponse.allHeaderFields)")
                        if data.count > 0 {
                            let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                            print("📄 fetchFromNetwork: Response body: \(responseBody.prefix(500))")
                        }
                        #endif
                        if attempt == Config.retryAttempts {
                            await updateConnectionStatus(.error("HTTP \(httpResponse.statusCode)"))
                        }
                        continue
                    }
                }
                
                // Decode JSON
                #if DEBUG
                print("🔧 fetchFromNetwork: Starting JSON decode for \(type)")
                #endif
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decodedData = try decoder.decode(type, from: data)
                
                #if DEBUG
                if let array = decodedData as? [Any] {
                    print("✅ fetchFromNetwork: Successfully decoded array with \(array.count) items")
                } else {
                    print("✅ fetchFromNetwork: Successfully decoded \(type)")
                }
                #endif
                
                // Update connection status on successful load
                await updateConnectionStatus(.connected)
                
                #if DEBUG
                print("✅ Successfully loaded \(url.lastPathComponent) from network (\(data.count) bytes)")
                #endif
                
                return decodedData
                
            } catch {
                #if DEBUG
                print("⚠️ fetchFromNetwork: Attempt \(attempt)/\(Config.retryAttempts) failed for \(url.lastPathComponent)")
                print("💥 fetchFromNetwork: Error: \(error)")
                if let decodingError = error as? DecodingError {
                    print("🔧 fetchFromNetwork: Decoding error details: \(decodingError)")
                }
                #endif
                
                if attempt == Config.retryAttempts {
                    #if DEBUG
                    print("🚫 fetchFromNetwork: All retry attempts exhausted for \(url.lastPathComponent)")
                    #endif
                    await updateConnectionStatus(.error(error.localizedDescription))
                } else {
                    #if DEBUG
                    print("⏱️ fetchFromNetwork: Waiting before retry attempt \(attempt + 1)...")
                    #endif
                    // Wait before retry
                    try? await Task.sleep(nanoseconds: UInt64(Config.retryDelay * 1_000_000_000 * Double(attempt)))
                }
            }
        }
        
        return nil
    }
    
    /// Check network connectivity
    private func checkConnectivity() async {
        #if DEBUG
        print("🔌 checkConnectivity: Testing connection to GitHub...")
        #endif
        
        guard let url = URL(string: DataEndpoints.educationTopics) else {
            #if DEBUG
            print("❌ checkConnectivity: Invalid base URL")
            #endif
            await updateConnectionStatus(.error("Invalid base URL"))
            return
        }
        
        #if DEBUG
        print("🔌 checkConnectivity: Testing URL: \(url)")
        #endif
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                #if DEBUG
                print("🔌 checkConnectivity: Received HTTP \(httpResponse.statusCode)")
                #endif
                if httpResponse.statusCode == 200 {
                    await updateConnectionStatus(.connected)
                    #if DEBUG
                    print("✅ checkConnectivity: Connection successful")
                    #endif
                } else {
                    await updateConnectionStatus(.offline)
                    #if DEBUG
                    print("⚠️ checkConnectivity: HTTP \(httpResponse.statusCode) - marking as offline")
                    #endif
                }
            } else {
                await updateConnectionStatus(.offline)
                #if DEBUG
                print("⚠️ checkConnectivity: No HTTP response - marking as offline")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ checkConnectivity: Connection failed: \(error)")
            #endif
            await updateConnectionStatus(.offline)
        }
    }
    
    /// Update connection status on main thread
    private func updateConnectionStatus(_ status: ConnectionStatus) async {
        await MainActor.run {
            connectionStatus = status
        }
    }
}

// MARK: - Data Cache Manager

/// Simple cache manager for storing fetched JSON data
final class DataCacheManager {
    static let shared = DataCacheManager()
    
    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheQueue = DispatchQueue(label: "datacache", qos: .utility)
    
    private init() {
        cache.countLimit = 20
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    /// Cache data with expiration
    func cache<T: Codable>(_ data: T, forKey key: String, expiration: TimeInterval = 3600) {
        cacheQueue.async {
            do {
                let jsonData = try JSONEncoder().encode(data)
                let entry = CacheEntry(data: jsonData, expiration: Date().addingTimeInterval(expiration))
                self.cache.setObject(entry, forKey: key as NSString, cost: jsonData.count)
                
                #if DEBUG
                print("💾 Cached \(key) (\(jsonData.count) bytes)")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to cache \(key): \(error)")
                #endif
            }
        }
    }
    
    /// Retrieve cached data if not expired
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let entry = cache.object(forKey: key as NSString) else {
            return nil
        }
        
        // Check expiration
        guard entry.expiration > Date() else {
            cache.removeObject(forKey: key as NSString)
            #if DEBUG
            print("🗑️ Expired cache entry removed: \(key)")
            #endif
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(type, from: entry.data)
        } catch {
            #if DEBUG
            print("❌ Failed to decode cached \(key): \(error)")
            #endif
            cache.removeObject(forKey: key as NSString)
            return nil
        }
    }
    
    /// Clear all cached data
    func clearAll() {
        cache.removeAllObjects()
        #if DEBUG
        print("🗑️ All cache cleared")
        #endif
    }
}

// MARK: - Cache Entry

private class CacheEntry {
    let data: Data
    let expiration: Date
    
    init(data: Data, expiration: Date) {
        self.data = data
        self.expiration = expiration
    }
}

// MARK: - Supporting Models

/// Model for infertility information items
struct InfertilityInfo: Codable, Identifiable {
    var id: String { title } // Use title as unique identifier
    
    let title: String
    let subtitle: String
    let systemIcon: String
    let description: String
    let keyPoints: [String]
    let references: [Reference]
    
    struct Reference: Codable, Equatable {
        let title: String
        let url: String
    }
}

// Note: Resource model is already defined in ResourceModels.swift