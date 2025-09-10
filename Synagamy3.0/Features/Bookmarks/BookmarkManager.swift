//
//  BookmarkManager.swift
//  Synagamy3.0
//
//  Manages bookmarked educational content and user favorites.
//

import SwiftUI

@MainActor
class BookmarkManager: ObservableObject {
    @AppStorage("bookmarkedTopics") private var bookmarkedTopicsData = Data()
    @AppStorage("bookmarkedResources") private var bookmarkedResourcesData = Data()
    @AppStorage("bookmarkedPathways") private var bookmarkedPathwaysData = Data()
    
    @Published private(set) var bookmarkedTopics: Set<String> = []
    @Published private(set) var bookmarkedResources: Set<String> = []
    @Published private(set) var bookmarkedPathways: Set<String> = []
    
    @Published var recentlyViewed: [RecentItem] = []
    
    private let maxRecentItems = 20
    
    struct RecentItem: Identifiable, Codable {
        var id = UUID()
        let title: String
        let type: ContentType
        let identifier: String
        let viewedAt: Date
        
        enum ContentType: String, Codable {
            case topic, resource, pathway
            
            var displayName: String {
                switch self {
                case .topic: return "Educational Topic"
                case .resource: return "Resource"
                case .pathway: return "Treatment Pathway"
                }
            }
            
            var icon: String {
                switch self {
                case .topic: return "book.fill"
                case .resource: return "link"
                case .pathway: return "map.fill"
                }
            }
        }
    }
    
    init() {
        loadBookmarks()
        loadRecentItems()
    }
    
    // MARK: - Topic Bookmarks
    
    func isTopicBookmarked(_ topicId: String) -> Bool {
        bookmarkedTopics.contains(topicId)
    }
    
    func toggleTopicBookmark(_ topic: EducationTopic) {
        if bookmarkedTopics.contains(topic.topic) {
            bookmarkedTopics.remove(topic.topic)
        } else {
            bookmarkedTopics.insert(topic.topic)
        }
        saveBookmarks()
        
        // Add to recent items
        addRecentItem(
            title: topic.topic,
            type: .topic,
            identifier: topic.topic
        )
    }
    
    func getBookmarkedTopics(from allTopics: [EducationTopic]) -> [EducationTopic] {
        return allTopics.filter { bookmarkedTopics.contains($0.topic) }
    }
    
    // MARK: - Resource Bookmarks
    
    func isResourceBookmarked(_ resourceId: String) -> Bool {
        bookmarkedResources.contains(resourceId)
    }
    
    func toggleResourceBookmark(_ resource: Resource) {
        if bookmarkedResources.contains(resource.title) {
            bookmarkedResources.remove(resource.title)
        } else {
            bookmarkedResources.insert(resource.title)
        }
        saveBookmarks()
        
        // Add to recent items
        addRecentItem(
            title: resource.title,
            type: .resource,
            identifier: resource.title
        )
    }
    
    // MARK: - Pathway Bookmarks
    
    func isPathwayBookmarked(_ pathwayId: String) -> Bool {
        bookmarkedPathways.contains(pathwayId)
    }
    
    func togglePathwayBookmark(_ pathway: PathwayPath) {
        if bookmarkedPathways.contains(pathway.title) {
            bookmarkedPathways.remove(pathway.title)
        } else {
            bookmarkedPathways.insert(pathway.title)
        }
        saveBookmarks()
        
        // Add to recent items
        addRecentItem(
            title: pathway.title,
            type: .pathway,
            identifier: pathway.title
        )
    }
    
    // MARK: - Recent Items
    
    func addRecentItem(title: String, type: RecentItem.ContentType, identifier: String) {
        let item = RecentItem(
            title: title,
            type: type,
            identifier: identifier,
            viewedAt: Date()
        )
        
        // Remove existing item if present
        recentlyViewed.removeAll { $0.identifier == identifier && $0.type == type }
        
        // Add to beginning
        recentlyViewed.insert(item, at: 0)
        
        // Limit size
        if recentlyViewed.count > maxRecentItems {
            recentlyViewed = Array(recentlyViewed.prefix(maxRecentItems))
        }
        
        saveRecentItems()
    }
    
    func clearRecentItems() {
        recentlyViewed.removeAll()
        saveRecentItems()
    }
    
    func removeRecentItem(_ item: RecentItem) {
        recentlyViewed.removeAll { $0.id == item.id }
        saveRecentItems()
    }
    
    // MARK: - Statistics
    
    var totalBookmarks: Int {
        bookmarkedTopics.count + bookmarkedResources.count + bookmarkedPathways.count
    }
    
    var topCategories: [String] {
        // Would analyze bookmarked content to find most common categories
        ["Reproductive Cycle & Natural Conception", "IVF & ART", "Male Fertility"]
    }
    
    var bookmarkingStreak: Int {
        // Calculate days of consecutive bookmarking activity
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        while streak < 30 { // Check last 30 days
            let dayItems = recentlyViewed.filter { item in
                calendar.isDate(item.viewedAt, inSameDayAs: currentDate)
            }
            
            if dayItems.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    // MARK: - Data Persistence
    
    private func loadBookmarks() {
        // Load topics
        if let topics = try? JSONDecoder().decode(Set<String>.self, from: bookmarkedTopicsData) {
            bookmarkedTopics = topics
        }
        
        // Load resources
        if let resources = try? JSONDecoder().decode(Set<String>.self, from: bookmarkedResourcesData) {
            bookmarkedResources = resources
        }
        
        // Load pathways
        if let pathways = try? JSONDecoder().decode(Set<String>.self, from: bookmarkedPathwaysData) {
            bookmarkedPathways = pathways
        }
    }
    
    private func saveBookmarks() {
        // Save topics
        if let topicsData = try? JSONEncoder().encode(bookmarkedTopics) {
            bookmarkedTopicsData = topicsData
        }
        
        // Save resources
        if let resourcesData = try? JSONEncoder().encode(bookmarkedResources) {
            bookmarkedResourcesData = resourcesData
        }
        
        // Save pathways
        if let pathwaysData = try? JSONEncoder().encode(bookmarkedPathways) {
            bookmarkedPathwaysData = pathwaysData
        }
    }
    
    private func loadRecentItems() {
        if let data = UserDefaults.standard.data(forKey: "recentItems"),
           let items = try? JSONDecoder().decode([RecentItem].self, from: data) {
            recentlyViewed = items
        }
    }
    
    private func saveRecentItems() {
        if let data = try? JSONEncoder().encode(recentlyViewed) {
            UserDefaults.standard.set(data, forKey: "recentItems")
        }
    }
}

// MARK: - Bookmark Extensions

extension View {
    func bookmarkable<T>(
        item: T,
        isBookmarked: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        self.overlay(
            Button(action: onToggle) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(isBookmarked ? .yellow : .secondary)
                    .font(.headline)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 32, height: 32)
                    )
            }
            .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark"),
            alignment: .topTrailing
        )
    }
}

// MARK: - Smart Suggestions

extension BookmarkManager {
    func getSuggestedContent(from allTopics: [EducationTopic]) -> [EducationTopic] {
        // Analyze bookmarked content to suggest related topics
        let bookmarkedTopicObjects = getBookmarkedTopics(from: allTopics)
        var suggestedTopics: [EducationTopic] = []
        
        // Find topics with related keywords
        let relatedKeywords = Set(bookmarkedTopicObjects.compactMap { $0.relatedTo }.flatMap { $0 })
        
        let candidates = allTopics.filter { topic in
            !bookmarkedTopics.contains(topic.topic) &&
            !(Set(topic.relatedTo ?? []).intersection(relatedKeywords).isEmpty)
        }
        
        // Score by relevance
        let scoredCandidates = candidates.map { topic in
            let score = Set(topic.relatedTo ?? []).intersection(relatedKeywords).count
            return (topic, score)
        }
        
        // Return top suggestions
        suggestedTopics = scoredCandidates
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }
        
        return suggestedTopics
    }
}