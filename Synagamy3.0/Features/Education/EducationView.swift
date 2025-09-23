//
//  EducationView.swift
//  Synagamy3.0
//
//  Interactive education explorer with step-by-step navigation
//  Similar UI style to PathwayView for consistency
//

import SwiftUI

// MARK: - Model Imports
import Foundation // For model types

// MARK: - UI Component Imports
// Note: These components must be available in the project
// Assuming they exist based on project structure

// MARK: - Education Data Source

enum EducationDataSource {
    case loading
    case remote([EducationTopic])
    case offline([EducationTopic])
    case bundled([EducationTopic])
    case error(String)

    var topics: [EducationTopic] {
        switch self {
        case .loading:
            return []
        case .remote(let topics), .offline(let topics), .bundled(let topics):
            return topics
        case .error:
            return []
        }
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var displayText: String {
        switch self {
        case .loading:
            return "Loading education content..."
        case .remote:
            return "Latest education content"
        case .offline:
            return "Offline education content"
        case .bundled:
            return "Essential education content"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    var icon: String {
        switch self {
        case .loading:
            return "arrow.clockwise"
        case .remote:
            return "cloud.fill"
        case .offline:
            return "arrow.down.circle.fill"
        case .bundled:
            return "book.closed.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .loading:
            return .blue
        case .remote:
            return .green
        case .offline:
            return .orange
        case .bundled:
            return .purple
        case .error:
            return .red
        }
    }
}

struct EducationView: View {
    @StateObject private var viewModel = EducationViewModel()
    @StateObject private var networkManager = NetworkStatusManager.shared
    @StateObject private var remoteDataService = RemoteDataService.shared
    @StateObject private var offlineManager = OfflineDataManager.shared
    @State private var showingTopicDetails = false
    @State private var selectedTopic: EducationTopic?
    @State private var isLearningPathExpanded = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var topics: [EducationTopic] = []
    @State private var dataSource: EducationDataSource = .loading
    
    // MARK: - Search Logic
    private var searchResults: (exact: [EducationTopic], partial: [EducationTopic], explanation: [EducationTopic], category: [EducationTopic]) {
        let allTopics = dataSource.topics
        
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
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo",
            showHomeButton: true,
            usePopToRoot: true,
            showBackButton: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Data source status indicator
                dataSourceStatusView

                // Handle different data source states
                if dataSource.isLoading {
                    LoadingStateView(
                        message: "Loading education topics...",
                        showProgress: true
                    )
                    .padding(.top, 20)
                } else if case .error(let message) = dataSource {
                    ContentLoadingErrorView(
                        title: "Education Content Unavailable",
                        message: message
                    ) {
                        Task { await loadEducationTopics() }
                    }
                    .padding(.top, 20)
                } else {
                    // Search bar when searching
                    if isSearching {
                        EducationSearchBar(searchText: $searchText)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSearching)
                            .accessibilityLabel("Search education topics")
                            .accessibilityHint("Enter keywords to find relevant fertility education content")
                            .onAppear {
                                AccessibilityAnnouncement.announce("Search field appeared. Enter keywords to find education topics.")
                            }
                    }
                    
                    if !searchText.isEmpty {
                        // Search results view with section headers
                        let results = searchResults
                        
                        LazyVStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                            // Exact matches section
                            if !results.exact.isEmpty {
                                SearchResultSection(title: "Exact Match", topics: results.exact, selectedTopic: $selectedTopic)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityLabel("Exact matches section")
                                    .accessibilityValue("\(results.exact.count) exact matches found")
                            }

                            // Partial title matches section
                            if !results.partial.isEmpty {
                                SearchResultSection(title: "Title Matches", topics: results.partial, selectedTopic: $selectedTopic)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityLabel("Title matches section")
                                    .accessibilityValue("\(results.partial.count) title matches found")
                            }

                            // Explanation matches section
                            if !results.explanation.isEmpty {
                                SearchResultSection(title: "Found in Explanation", topics: results.explanation, selectedTopic: $selectedTopic)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityLabel("Explanation matches section")
                                    .accessibilityValue("\(results.explanation.count) topics with matching explanations")
                            }

                            // Category matches section
                            if !results.category.isEmpty {
                                SearchResultSection(title: "Category Matches", topics: results.category, selectedTopic: $selectedTopic)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityLabel("Category matches section")
                                    .accessibilityValue("\(results.category.count) category matches found")
                            }
                        }
                        .onAppear {
                            let totalResults = results.exact.count + results.partial.count + results.explanation.count + results.category.count
                            AccessibilityAnnouncement.announce("Search completed. \(totalResults) results found across \([results.exact, results.partial, results.explanation, results.category].filter { !$0.isEmpty }.count) sections.")
                        }
                        .padding(.top, 4)
                    } else {
                        ScrollView {
                            VStack(spacing: Brand.Spacing.xl) {
                                
                                // MARK: - Header Section
                                headerSection
                                
                                // MARK: - Current Selection Status
                                if viewModel.hasActiveSelection {
                                    currentSelectionSection
                                }
                                
                                // MARK: - Category Selection
                                if !viewModel.hasSelectedCategory {
                                    categorySelectionSection
                                }
                                
                                // MARK: - Topic Selection
                                if viewModel.hasSelectedCategory && viewModel.selectedTopic == nil {
                                    topicSelectionSection
                                }
                                
                                // MARK: - Topic Content
                                if let topic = viewModel.selectedTopic {
                                    topicContentSection(topic: topic)
                                }
                                
                                // MARK: - Learning Path
                                learningPathSection
                                
                                // MARK: - Reset Button
                                if viewModel.hasActiveSelection {
                                    resetButton
                                }
                            }
                            .padding(.vertical, Brand.Spacing.lg)
                        }
                    }
                }
            }
        }
        .overlay {
            // Floating search button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingSearchButton(isSearching: $isSearching)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .fertilityAccessibility(
                            label: isSearching ? "Close search" : "Search education topics",
                            hint: isSearching ? "Double tap to close search field" : "Double tap to open search field",
                            traits: [.isButton]
                        )
                }
            }
        }
        .sheet(item: $selectedTopic) { topic in
            ScrollView {
                TopicDetailContent(topic: topic, selectedTopic: $selectedTopic)
                    .padding()
            }
        }
        .onChange(of: isSearching) { _, newValue in
            if !newValue {
                searchText = ""
            }
        }
        .task {
            await loadEducationTopics()
        }
        .onChange(of: dataSource) { _, newDataSource in
            // Update ViewModel when data source changes
            viewModel.updateTopics(newDataSource.topics)
        }
        .onDynamicTypeChange { size in
            // Handle dynamic type changes for better accessibility
            #if DEBUG
            print("EducationView: Dynamic Type size changed to \(size)")
            #endif
        }
        .onAppear {
            AccessibilityAnnouncement.announce("Education section loaded. Browse categories and topics to learn about fertility.")
        }
    }
    
    // MARK: - Data Loading

    private func loadEducationTopics() async {
        dataSource = .loading

        // Check network status first
        if networkManager.isOnline {
            // Try to load remote data
            let remoteTopics = await remoteDataService.loadEducationTopics()

            if !remoteTopics.isEmpty {
                // Successfully loaded remote data
                dataSource = .remote(remoteTopics)
                topics = remoteTopics

                // Cache the remote data for offline use
                Task {
                    await offlineManager.cacheEducationContent(remoteTopics)
                }
            } else {
                // Remote failed, try offline cache
                await loadOfflineData()
            }
        } else {
            // No network, load offline data directly
            await loadOfflineData()
        }
    }

    private func loadOfflineData() async {
        // Try to load cached offline data
        let offlineTopics = await offlineManager.loadEducationTopics()

        if !offlineTopics.isEmpty {
            dataSource = .offline(offlineTopics)
            topics = offlineTopics
        } else {
            // Fall back to bundled data
            let bundledTopics = AppData.topics
            if !bundledTopics.isEmpty {
                dataSource = .bundled(bundledTopics)
                topics = bundledTopics
            } else {
                dataSource = .error("No education content available")
                topics = []
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            CategoryBadge(
                text: "Education Center",
                icon: "book.fill",
                color: Brand.Color.primary
            )
            .accessibilityLabel("Education Center")
            .accessibilityAddTraits(.isHeader)

            Text("Interactive Learning Journey")
                .font(Brand.Typography.headlineMedium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("Explore Fertility Topics Step by Step at Your Own Pace")
                .font(Brand.Typography.labelSmall)
                .foregroundColor(Brand.Color.secondary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isStaticText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Education Center. Interactive Learning Journey.")
        .accessibilityValue("Explore fertility topics step by step at your own pace")
        .accessibilityAddTraits(.isHeader)
    }
    
    // MARK: - Current Selection Section
    private var currentSelectionSection: some View {
        EnhancedContentBlock(
            title: "Your Learning Path",
            icon: "location.fill"
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                // Show current category
                if let category = viewModel.selectedCategory {
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.body.weight(.medium))
                            .foregroundColor(Brand.Color.primary)
                            .accessibilityHidden(true) // Decorative icon

                        Text(category)
                            .font(Brand.Typography.bodySmall)
                            .foregroundColor(.primary)

                        Spacer()

                        if viewModel.selectedTopic == nil {
                            Text("\(viewModel.topicsInCategory.count) topics")
                                .font(Brand.Typography.labelSmall)
                                .foregroundColor(Brand.Color.secondary)
                        }
                    }
                }
                
                // Show selected topic if any
                if let topic = viewModel.selectedTopic {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Brand.Color.success)
                        
                        Text(topic.topic)
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.leading, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Category Selection
    private var categorySelectionSection: some View {
        EnhancedContentBlock(
            title: "Select a Category",
            icon: "square.grid.2x2.fill"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                Text("What Would You Like to Learn About?")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: Brand.Spacing.md) {
                    ForEach(viewModel.categories, id: \.name) { category in
                        Button {
                            viewModel.selectCategory(category.name)
                            AccessibilityAnnouncement.announce("Selected \(category.name) category with \(category.count) topics")
                        } label: {
                            HStack(spacing: 12) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Brand.Color.primary.opacity(0.1))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: getCategoryIcon(for: category.name))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Brand.Color.primary)
                                }
                                .accessibilityHidden(true) // Decorative icon
                                
                                // Text
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name)
                                        .font(Brand.Typography.bodySmall)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text("\(category.count) topic\(category.count == 1 ? "" : "s") available")
                                        .font(Brand.Typography.labelSmall)
                                        .foregroundColor(Brand.Color.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                // Selection indicator
                                Image(systemName: "arrow.right.circle")
                                    .font(.body)
                                    .foregroundColor(Brand.Color.primary.opacity(0.4))
                                    .accessibilityHidden(true) // Decorative arrow
                            }
                            .padding(Brand.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                            .stroke(Brand.Color.hairline.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .fertilityAccessibility(
                            label: "\(category.name) category",
                            hint: "Double tap to explore \(category.count) topics in \(category.name)",
                            value: "\(category.count) topics available",
                            traits: [.isButton]
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Topic Selection
    private var topicSelectionSection: some View {
        EnhancedContentBlock(
            title: "Choose a Topic",
            icon: "book.circle"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                if let category = viewModel.selectedCategory {
                    Text("Topics in \(category)")
                        .font(Brand.Typography.headlineMedium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: Brand.Spacing.md) {
                    ForEach(viewModel.topicsInCategory, id: \.id) { topic in
                        Button {
                            viewModel.selectTopic(topic)
                        } label: {
                            HStack(spacing: 12) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Brand.Color.primary.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Brand.Color.primary)
                                }
                                
                                // Text
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(topic.topic)
                                        .font(Brand.Typography.bodySmall)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                    
                                    // Show a snippet of the lay explanation
                                    Text(String(topic.layExplanation.prefix(80)) + "...")
                                        .font(Brand.Typography.labelSmall)
                                        .foregroundColor(Brand.Color.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                // Selection indicator
                                Image(systemName: "arrow.right.circle")
                                    .font(.body)
                                    .foregroundColor(Brand.Color.primary.opacity(0.5))
                            }
                            .padding(Brand.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                            .stroke(Brand.Color.hairline, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Back to categories button
                Button {
                    viewModel.goBackToCategories()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.medium))
                        Text("Back to Categories")
                            .font(Brand.Typography.labelSmall)
                    }
                    .foregroundColor(Brand.Color.secondary)
                }
            }
        }
    }
    
    // MARK: - Topic Content Section
    private func topicContentSection(topic: EducationTopic) -> some View {
        EnhancedContentBlock(
            title: topic.topic,
            icon: "book.pages"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                // Category badge
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.caption2)
                    
                    Text(topic.category.uppercased())
                        .font(Brand.Typography.labelSmall)
                        .tracking(0.5)
                }
                .foregroundColor(Brand.Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Brand.Color.primary.opacity(0.12))
                        .overlay(
                            Capsule()
                                .strokeBorder(Brand.Color.primary.opacity(0.2), lineWidth: 1)
                        )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Lay explanation preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.body)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Quick Overview")
                            .font(Brand.Typography.labelLarge)
                            .foregroundColor(Brand.Color.primary)
                    }
                    
                    Text(String(topic.layExplanation.prefix(200)) + "...")
                        .font(Brand.Typography.bodySmall)
                        .foregroundColor(.primary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(Brand.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                        .strokeBorder(Brand.Color.hairline, lineWidth: 1)
                                )
                        )
                }
                
                // View Full Details Button
                Button {
                    selectedTopic = topic
                } label: {
                    HStack(spacing: 8) {
                        Text("Read Complete Topic")
                            .font(Brand.Typography.labelSmall)
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(Brand.Typography.labelSmall)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Brand.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                            .fill(Brand.Color.primary)
                    )
                }
                .buttonStyle(.plain)
                
                // Navigation buttons
                HStack(spacing: 12) {
                    Button {
                        viewModel.goBackToTopics()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.medium))
                            Text("Back to Topics")
                                .font(Brand.Typography.labelSmall)
                        }
                        .foregroundColor(Brand.Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Brand.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                        .stroke(Brand.Color.hairline, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if viewModel.hasNextTopic {
                        Button {
                            viewModel.selectNextTopic()
                        } label: {
                            HStack {
                                Text("Next Topic")
                                    .font(Brand.Typography.labelSmall)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Brand.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                    .fill(Brand.Color.primary)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Learning Path Section
    private var learningPathSection: some View {
        ExpandableSection(
            title: "Understanding Your Learning Journey",
            subtitle: "Tips for effective learning",
            icon: "lightbulb.circle",
            isExpanded: $isLearningPathExpanded
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Learning Tips")
                    .font(Brand.Typography.labelLarge)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 10) {
                    InfoPoint(
                        icon: "1.circle.fill",
                        title: "Start with Basics",
                        description: "Begin with fundamental concepts before moving to advanced topics"
                    )
                    
                    InfoPoint(
                        icon: "2.circle.fill",
                        title: "Take Your Time",
                        description: "There's no rush - absorb information at your own pace"
                    )
                    
                    InfoPoint(
                        icon: "3.circle.fill",
                        title: "Explore Related Topics",
                        description: "Each topic links to related concepts for deeper understanding"
                    )
                    
                    InfoPoint(
                        icon: "4.circle.fill",
                        title: "Consult Professionals",
                        description: "Use this knowledge to have informed discussions with your healthcare provider"
                    )
                }
            }
        }
    }
    
    // MARK: - Reset Button
    private var resetButton: some View {
        Button {
            viewModel.reset()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                Text("Start Over")
                    .font(Brand.Typography.labelLarge)
            }
            .foregroundColor(Brand.Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(Brand.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                            .stroke(Brand.Color.hairline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Source Status View
    private var dataSourceStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: dataSource.icon)
                .font(.caption)
                .foregroundColor(dataSource.color)

            Text(dataSource.displayText)
                .font(Brand.Typography.labelSmall)
                .foregroundColor(.secondary)

            Spacer()

            if case .offline(_) = dataSource {
                Button("Refresh") {
                    Task { await loadEducationTopics() }
                }
                .font(Brand.Typography.labelSmall)
                .foregroundColor(Brand.Color.primary)
            }
        }
        .padding(.horizontal, Brand.Spacing.md)
        .padding(.vertical, Brand.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.sm)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.sm)
                        .stroke(dataSource.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Helper Methods
    private func getCategoryIcon(for category: String) -> String {
        return "book.fill"
    }
}

// MARK: - Info Point Component (Reused from PathwayView)
private struct InfoPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(Brand.Color.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - View Model
@MainActor
class EducationViewModel: ObservableObject {
    @Published var selectedCategory: String?
    @Published var selectedTopic: EducationTopic?
    
    @Published var allTopics: [EducationTopic] = []
    
    var hasActiveSelection: Bool {
        selectedCategory != nil || selectedTopic != nil
    }
    
    var hasSelectedCategory: Bool {
        selectedCategory != nil
    }
    
    var categories: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: allTopics, by: { $0.category })
        var seen = Set<String>()
        var orderedCategories: [(name: String, count: Int)] = []
        
        for topic in allTopics {
            if !seen.contains(topic.category) {
                seen.insert(topic.category)
                let count = grouped[topic.category]?.count ?? 0
                orderedCategories.append((topic.category, count))
            }
        }
        
        return orderedCategories
    }
    
    var topicsInCategory: [EducationTopic] {
        guard let category = selectedCategory else { return [] }
        return allTopics.filter { $0.category == category }
    }
    
    var hasNextTopic: Bool {
        guard let currentTopic = selectedTopic else { return false }
        guard let currentIndex = topicsInCategory.firstIndex(where: { $0.id == currentTopic.id }) else { return false }
        return currentIndex < topicsInCategory.count - 1
    }
    
    func updateTopics(_ topics: [EducationTopic]) {
        allTopics = topics
    }

    func selectCategory(_ category: String) {
        selectedCategory = category
        selectedTopic = nil
    }
    
    func selectTopic(_ topic: EducationTopic) {
        selectedTopic = topic
    }
    
    func selectNextTopic() {
        guard let currentTopic = selectedTopic else { return }
        guard let currentIndex = topicsInCategory.firstIndex(where: { $0.id == currentTopic.id }) else { return }
        
        if currentIndex < topicsInCategory.count - 1 {
            selectedTopic = topicsInCategory[currentIndex + 1]
        }
    }
    
    func goBackToCategories() {
        selectedCategory = nil
        selectedTopic = nil
    }
    
    func goBackToTopics() {
        selectedTopic = nil
    }
    
    func reset() {
        selectedCategory = nil
        selectedTopic = nil
    }
}

// MARK: - Search Components

private struct SearchResultSection: View {
    let title: String
    let topics: [EducationTopic]
    @Binding var selectedTopic: EducationTopic?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text(title)
                .font(Brand.Typography.labelSmall)
                .fontWeight(.semibold)
                .foregroundColor(Brand.Color.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            // Topic list
            VStack(spacing: Brand.Spacing.sm) {
                ForEach(topics, id: \.id) { topic in
                    Button {
                        selectedTopic = topic
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic.topic)
                                    .font(Brand.Typography.headlineMedium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(topic.category)
                                    .font(Brand.Typography.labelSmall)
                                    .foregroundColor(Brand.Color.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary.opacity(0.5))
                        }
                        .padding(.vertical, Brand.Spacing.md)
                        .padding(.horizontal, Brand.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                        .stroke(Brand.Color.hairline, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EducationView()
    }
}
