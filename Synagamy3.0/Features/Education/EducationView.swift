//
//  EducationView.swift
//  Synagamy3.0
//
//  Categories → Topics flow.
//  • Lists unique categories as BrandTiles (with topic counts).
//  • Tapping a category navigates to TopicListView scoped to that category.
//

import SwiftUI

struct EducationView: View {
    // MARK: - Data
    @State private var allTopics: [EducationTopic] = []

    // MARK: - UI State
    @State private var errorMessage: String? = nil
    @State private var isSearching = false
    @State private var searchText = ""

    // MARK: - Derived: categories + lookup
    private var searchResults: (exact: [EducationTopic], partial: [EducationTopic], explanation: [EducationTopic], category: [EducationTopic]) {
        if searchText.isEmpty {
            return ([], [], [], [])
        }
        
        let search = searchText.lowercased()
        
        // Separate exact title matches from other matches
        var exactTitleMatches: [EducationTopic] = []
        var partialTitleMatches: [EducationTopic] = []
        var layExplanationMatches: [EducationTopic] = []
        var categoryMatches: [EducationTopic] = []
        
        for topic in allTopics {
            let topicTitle = topic.topic.lowercased()
            
            if topicTitle == search {
                // Exact title match
                exactTitleMatches.append(topic)
            } else if topicTitle.contains(search) {
                // Partial title match
                partialTitleMatches.append(topic)
            } else if topic.layExplanation.lowercased().contains(search) {
                // Found in lay explanation
                layExplanationMatches.append(topic)
            } else if topic.category.lowercased().contains(search) {
                // Found in category
                categoryMatches.append(topic)
            }
        }
        
        return (exactTitleMatches, partialTitleMatches, layExplanationMatches, categoryMatches)
    }
    
    private var filteredTopics: [EducationTopic] {
        if searchText.isEmpty {
            return allTopics
        }
        let results = searchResults
        return results.exact + results.partial + results.explanation + results.category
    }
    
    private var categories: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: filteredTopics, by: { $0.category })
        // Preserve the original order from the JSON by using the first occurrence of each category
        var seen = Set<String>()
        var orderedCategories: [(name: String, count: Int)] = []
        
        for topic in filteredTopics {
            if !seen.contains(topic.category) {
                seen.insert(topic.category)
                let count = grouped[topic.category]?.count ?? 0
                orderedCategories.append((topic.category, count))
            }
        }
        
        return orderedCategories
    }

    private var topicsByCategory: [String: [EducationTopic]] {
        Dictionary(grouping: filteredTopics, by: { $0.category })
    }

    var body: some View {
        ZStack {
            StandardPageLayout(
                primaryImage: "SynagamyLogoTwo",
                secondaryImage: "EducationLogo",
                showHomeButton: true,
                usePopToRoot: true
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    // Search bar when searching
                    if isSearching {
                        EducationSearchBar(searchText: $searchText)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSearching)
                    }
                    
                    if allTopics.isEmpty {
                        EmptyStateView(
                            icon: "book",
                            title: "No topics available",
                            message: "Please check back later. You can still explore Pathways."
                        )
                        .padding(.top, 8)
                    } else if filteredTopics.isEmpty && !searchText.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No results found",
                            message: "Try searching with different keywords"
                        )
                        .padding(.top, 40)
                    } else if !searchText.isEmpty {
                        // Search results view with section headers
                        let results = searchResults
                        
                        LazyVStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                            // Exact matches section
                            if !results.exact.isEmpty {
                                SearchResultSection(title: "Exact Match", topics: results.exact)
                            }
                            
                            // Partial title matches section
                            if !results.partial.isEmpty {
                                SearchResultSection(title: "Title Matches", topics: results.partial)
                            }
                            
                            // Explanation matches section
                            if !results.explanation.isEmpty {
                                SearchResultSection(title: "Found in Explanation", topics: results.explanation)
                            }
                            
                            // Category matches section
                            if !results.category.isEmpty {
                                SearchResultSection(title: "Category Matches", topics: results.category)
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        // Normal category view
                        LazyVStack(spacing: Brand.Spacing.xl) {
                            ForEach(categories, id: \.name) { cat in
                                NavigationLink {
                                    TopicListView(
                                        title: cat.name,
                                        topics: topicsByCategory[cat.name] ?? []
                                    )
                                } label: {
                                    BrandTile(
                                        title: cat.name,
                                        subtitle: "\(cat.count) topic\(cat.count == 1 ? "" : "s")",
                                        systemIcon: "square.grid.2x2.fill",
                                        assetIcon: nil,
                                        isCompact: true
                                    )
                                }
                                .buttonStyle(BrandTileButtonStyle())
                                .accessibilityLabel(Text("\(cat.name). \(cat.count) topics. Tap to view."))
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            
            // Floating search button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingSearchButton(isSearching: $isSearching)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }

        // MARK: - Alerts
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: { Text(errorMessage ?? "Please try again.") })

        // MARK: - Load data once
        .task {
            // Keep original order from JSON
            allTopics = AppData.topics
        }
        
        // Clear search when closing
        .onChange(of: isSearching) { _, newValue in
            if !newValue {
                searchText = ""
            }
        }
    }
}

// MARK: - Search Result Section Component

private struct SearchResultSection: View {
    let title: String
    let topics: [EducationTopic]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Brand.ColorSystem.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            // Topic list
            VStack(spacing: Brand.Spacing.sm) {
                ForEach(topics, id: \.id) { topic in
                    NavigationLink {
                        ScrollView {
                            TopicDetailContent(topic: topic)
                                .padding()
                        }
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic.topic)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(topic.category)
                                    .font(.caption)
                                    .foregroundColor(Brand.ColorSystem.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}