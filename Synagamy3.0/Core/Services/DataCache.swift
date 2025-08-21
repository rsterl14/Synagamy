//
//  DataCache.swift
//  Synagamy3.0
//
//  High-performance data caching system to eliminate redundant JSON loading
//  and improve app startup time. Uses memory caching with automatic cleanup.
//

import Foundation
import SwiftUI

/// High-performance singleton cache for app data with automatic memory management
@MainActor
final class DataCache: ObservableObject {
    static let shared = DataCache()
    
    // MARK: - Cache Storage
    private var educationTopicsCache: [EducationTopic]?
    private var commonQuestionsCache: [CommonQuestion]?
    private var resourcesCache: [Resource]?
    private var pathwayStepsCache: [PathwayCategory]?
    
    // MARK: - Cache Timestamps for invalidation
    private var educationTopicsTimestamp: Date?
    private var commonQuestionsTimestamp: Date?
    private var resourcesTimestamp: Date?
    private var pathwayStepsTimestamp: Date?
    
    // MARK: - Configuration
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Education Topics
    func getEducationTopics() -> [EducationTopic] {
        if let cached = educationTopicsCache,
           let timestamp = educationTopicsTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            return cached
        }
        
        let topics = loadEducationTopicsFromDisk()
        educationTopicsCache = topics
        educationTopicsTimestamp = Date()
        return topics
    }
    
    private func loadEducationTopicsFromDisk() -> [EducationTopic] {
        guard let url = Bundle.main.url(forResource: "Education_Topics", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([EducationTopic].self, from: data)
        } catch {
            print("Error decoding education topics: \(error)")
            return []
        }
    }
    
    // MARK: - Common Questions
    func getCommonQuestions() -> [CommonQuestion] {
        if let cached = commonQuestionsCache,
           let timestamp = commonQuestionsTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            return cached
        }
        
        let questions = AppData.questions // Use existing static data
        commonQuestionsCache = questions
        commonQuestionsTimestamp = Date()
        return questions
    }
    
    // MARK: - Resources
    func getResources() -> [Resource] {
        if let cached = resourcesCache,
           let timestamp = resourcesTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            return cached
        }
        
        let resources = Resource.loadFromJSON()
        resourcesCache = resources
        resourcesTimestamp = Date()
        return resources
    }
    
    // MARK: - Pathway Categories
    func getPathwayCategories() -> [PathwayCategory] {
        if let cached = pathwayStepsCache,
           let timestamp = pathwayStepsTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            return cached
        }
        
        let categories = AppData.pathways // Use existing static data
        pathwayStepsCache = categories
        pathwayStepsTimestamp = Date()
        return categories
    }
    
    // MARK: - Cache Management
    func invalidateAllCaches() {
        educationTopicsCache = nil
        commonQuestionsCache = nil
        resourcesCache = nil
        pathwayStepsCache = nil
        
        educationTopicsTimestamp = nil
        commonQuestionsTimestamp = nil
        resourcesTimestamp = nil
        pathwayStepsTimestamp = nil
    }
    
    func invalidateEducationTopics() {
        educationTopicsCache = nil
        educationTopicsTimestamp = nil
    }
    
    func invalidateResources() {
        resourcesCache = nil
        resourcesTimestamp = nil
    }
    
    // MARK: - Memory Management
    func clearExpiredCaches() {
        let now = Date()
        
        if let timestamp = educationTopicsTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            educationTopicsCache = nil
            educationTopicsTimestamp = nil
        }
        
        if let timestamp = commonQuestionsTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            commonQuestionsCache = nil
            commonQuestionsTimestamp = nil
        }
        
        if let timestamp = resourcesTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            resourcesCache = nil
            resourcesTimestamp = nil
        }
        
        if let timestamp = pathwayStepsTimestamp,
           now.timeIntervalSince(timestamp) >= cacheTimeout {
            pathwayStepsCache = nil
            pathwayStepsTimestamp = nil
        }
    }
}

// MARK: - Convenient View Extensions
extension View {
    /// Provides optimized data access through DataCache
    func withDataCache() -> some View {
        environmentObject(DataCache.shared)
    }
}