//
//  SearchEngine.swift
//  Synagamy3.0
//
//  High-performance search engine with debouncing, caching, and optimized
//  string matching algorithms. Reduces CPU usage and improves search responsiveness.
//

import Foundation
import SwiftUI
import Combine

/// High-performance search engine with debouncing and result caching
@MainActor
final class SearchEngine: ObservableObject {
    
    // MARK: - Search Configuration
    private let debounceDelay: TimeInterval = 0.3
    private var searchCancellable: AnyCancellable?
    private var searchCache: [String: SearchResults] = [:]
    
    // MARK: - Search Models
    struct SearchResults {
        let exact: [EducationTopic]
        let partial: [EducationTopic]
        let explanation: [EducationTopic]
        let category: [EducationTopic]
        let timestamp: Date
        
        var isEmpty: Bool {
            exact.isEmpty && partial.isEmpty && explanation.isEmpty && category.isEmpty
        }
        
        var all: [EducationTopic] {
            exact + partial + explanation + category
        }
    }
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var searchResults: SearchResults = SearchResults(exact: [], partial: [], explanation: [], category: [], timestamp: Date())
    @Published var isSearching: Bool = false
    
    // MARK: - Data Source
    private var topics: [EducationTopic] = []
    
    init() {
        setupDebouncing()
    }
    
    // MARK: - Public Interface
    func configure(with topics: [EducationTopic]) {
        self.topics = topics
        // Pre-process search data for better performance
        preprocessSearchData()
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        isSearching = !text.isEmpty
    }
    
    // MARK: - Private Implementation
    private func setupDebouncing() {
        searchCancellable = $searchText
            .debounce(for: .seconds(debounceDelay), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
    }
    
    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = SearchResults(exact: [], partial: [], explanation: [], category: [], timestamp: Date())
            return
        }
        
        // Check cache first
        let cacheKey = query.lowercased()
        if let cached = searchCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < 30 { // 30 second cache
            searchResults = cached
            return
        }
        
        // Perform search
        let results = search(query: query)
        
        // Cache results
        searchCache[cacheKey] = results
        cleanupSearchCache()
        
        searchResults = results
    }
    
    private func search(query: String) -> SearchResults {
        let lowercasedQuery = query.lowercased()
        
        var exact: [EducationTopic] = []
        var partial: [EducationTopic] = []
        var explanation: [EducationTopic] = []
        var category: [EducationTopic] = []
        
        // Optimized single-pass search
        for topic in topics {
            let titleLower = topic.searchableTitle
            
            // Check exact match first (highest priority)
            if titleLower == lowercasedQuery {
                exact.append(topic)
                continue
            }
            
            // Check partial title match
            if titleLower.contains(lowercasedQuery) {
                partial.append(topic)
                continue
            }
            
            // Check lay explanation (cached lowercased)
            if topic.layExplanation.lowercased().contains(lowercasedQuery) {
                explanation.append(topic)
                continue
            }
            
            // Check category
            if topic.category.lowercased().contains(lowercasedQuery) {
                category.append(topic)
            }
        }
        
        return SearchResults(
            exact: exact,
            partial: partial,
            explanation: explanation,
            category: category,
            timestamp: Date()
        )
    }
    
    private func preprocessSearchData() {
        // Pre-compute searchable titles for better performance
        // This is already handled by the EducationTopic.searchableTitle property
    }
    
    private func cleanupSearchCache() {
        // Keep cache size manageable
        if searchCache.count > 50 {
            let cutoffTime = Date().addingTimeInterval(-60) // Remove entries older than 1 minute
            searchCache = searchCache.filter { $0.value.timestamp > cutoffTime }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        searchCancellable?.cancel()
    }
}

// MARK: - SwiftUI Integration
extension View {
    func withSearchEngine(_ searchEngine: SearchEngine) -> some View {
        environmentObject(searchEngine)
    }
}