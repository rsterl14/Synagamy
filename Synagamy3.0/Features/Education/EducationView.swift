//
//  EducationView.swift
//  Synagamy3.0
//
//  Interactive education explorer with step-by-step navigation
//  Similar UI style to PathwayView for consistency
//

import SwiftUI

struct EducationView: View {
    @StateObject private var viewModel = EducationViewModel()
    @State private var showingTopicDetails = false
    @State private var selectedTopic: EducationTopic?
    @State private var isLearningPathExpanded = false
    @State private var isSearching = false
    @State private var searchText = ""
    
    // MARK: - Search Logic
    private var searchResults: (exact: [EducationTopic], partial: [EducationTopic], explanation: [EducationTopic], category: [EducationTopic]) {
        let allTopics = AppData.topics
        
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
                // Search bar when searching
                if isSearching {
                    EducationSearchBar(searchText: $searchText)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSearching)
                }
                
                if !searchText.isEmpty {
                    // Search results view with section headers
                    let results = searchResults
                    
                    LazyVStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                        // Exact matches section
                        if !results.exact.isEmpty {
                            SearchResultSection(title: "Exact Match", topics: results.exact, selectedTopic: $selectedTopic)
                        }
                        
                        // Partial title matches section
                        if !results.partial.isEmpty {
                            SearchResultSection(title: "Title Matches", topics: results.partial, selectedTopic: $selectedTopic)
                        }
                        
                        // Explanation matches section
                        if !results.explanation.isEmpty {
                            SearchResultSection(title: "Found in Explanation", topics: results.explanation, selectedTopic: $selectedTopic)
                        }
                        
                        // Category matches section
                        if !results.category.isEmpty {
                            SearchResultSection(title: "Category Matches", topics: results.category, selectedTopic: $selectedTopic)
                        }
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
        .overlay {
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
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            CategoryBadge(
                text: "Education Center",
                icon: "book.fill",
                color: Brand.ColorSystem.primary
            )
            
            Text("Interactive Learning Journey")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Explore Fertility Topics Step by Step at Your Own Pace")
                .font(.caption)
                .foregroundColor(Brand.ColorSystem.secondary)
                .multilineTextAlignment(.center)
        }
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
                            .foregroundColor(Brand.ColorSystem.primary)
                        
                        Text(category)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if viewModel.selectedTopic == nil {
                            Text("\(viewModel.topicsInCategory.count) topics")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                    }
                }
                
                // Show selected topic if any
                if let topic = viewModel.selectedTopic {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.success)
                        
                        Text(topic.topic)
                            .font(.caption.weight(.semibold))
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
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: Brand.Spacing.md) {
                    ForEach(viewModel.categories, id: \.name) { category in
                        Button {
                            viewModel.selectCategory(category.name)
                        } label: {
                            HStack(spacing: 12) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Brand.ColorSystem.primary.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: getCategoryIcon(for: category.name))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Brand.ColorSystem.primary)
                                }
                                
                                // Text
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text("\(category.count) topic\(category.count == 1 ? "" : "s") available")
                                        .font(.caption)
                                        .foregroundColor(Brand.ColorSystem.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                // Selection indicator
                                Image(systemName: "arrow.right.circle")
                                    .font(.body)
                                    .foregroundColor(Brand.ColorSystem.primary.opacity(0.4))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Brand.ColorToken.hairline.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
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
                        .font(.headline.weight(.semibold))
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
                                        .fill(Brand.ColorSystem.primary.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Brand.ColorSystem.primary)
                                }
                                
                                // Text
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(topic.topic)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                    
                                    // Show a snippet of the lay explanation
                                    Text(String(topic.layExplanation.prefix(80)) + "...")
                                        .font(.caption)
                                        .foregroundColor(Brand.ColorSystem.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                // Selection indicator
                                Image(systemName: "arrow.right.circle")
                                    .font(.body)
                                    .foregroundColor(Brand.ColorSystem.primary.opacity(0.5))
                            }
                            .padding(12)
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
                
                // Back to categories button
                Button {
                    viewModel.goBackToCategories()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.medium))
                        Text("Back to Categories")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(Brand.ColorSystem.secondary)
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
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                }
                .foregroundColor(Brand.ColorSystem.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Brand.ColorSystem.primary.opacity(0.12))
                        .overlay(
                            Capsule()
                                .strokeBorder(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
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
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Brand.ColorSystem.primary)
                    }
                    
                    Text(String(topic.layExplanation.prefix(200)) + "...")
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Brand.ColorToken.hairline, lineWidth: 1)
                                )
                        )
                }
                
                // View Full Details Button
                Button {
                    selectedTopic = topic
                } label: {
                    HStack(spacing: 8) {
                        Text("Read Complete Topic")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.ColorSystem.primary)
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
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(Brand.ColorSystem.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
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
                                    .font(.caption.weight(.medium))
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Brand.ColorSystem.primary)
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
                    .font(.subheadline.weight(.semibold))
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
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(Brand.ColorSystem.secondary)
            .frame(maxWidth: .infinity)
            .padding()
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
                .foregroundColor(Brand.ColorSystem.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - View Model
class EducationViewModel: ObservableObject {
    @Published var selectedCategory: String?
    @Published var selectedTopic: EducationTopic?
    
    private let allTopics = AppData.topics
    
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
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Brand.ColorSystem.secondary)
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

#Preview {
    NavigationStack {
        EducationView()
    }
}

