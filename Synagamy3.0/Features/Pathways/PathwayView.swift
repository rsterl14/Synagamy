//
//  PathwayView.swift
//  Synagamy3.0
//
//  Interactive pathway selection with questionnaire flow
//  Similar UI style to TimedIntercourse and OutcomePredictor
//

import SwiftUI

struct PathwayView: View {
    @StateObject private var viewModel = PathwayViewModel()
    @State private var showingPathwayDetails = false
    @State private var selectedPathway: PathwayPath?
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "PathwayLogo",
            showHomeButton: true,
            usePopToRoot: true,
            showBackButton: true
        ) {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    
                    // MARK: - Header Section
                    headerSection
                    
                    // MARK: - Current Selection Status
                    if viewModel.hasActiveSelection {
                        currentSelectionSection
                    }
                    
                    // MARK: - Category Selection
                    if !viewModel.hasStarted {
                        categorySelectionSection
                    }
                    
                    // MARK: - Question Flow
                    if viewModel.hasStarted && !viewModel.isComplete {
                        questionSection
                    }
                    
                    // MARK: - Results
                    if viewModel.isComplete {
                        resultsSection
                    }
                    
                    // MARK: - Educational Content
                    educationalSection
                    
                    // MARK: - Reset Button
                    if viewModel.hasStarted {
                        resetButton
                    }
                }
                .padding(.vertical, Brand.Spacing.lg)
            }
        }
        .sheet(item: $selectedPathway) { pathway in
            PathwayDetailSheet(pathway: pathway, educationTopics: AppData.topics)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            CategoryBadge(
                text: "Treatment Pathways",
                icon: "map.fill",
                color: Brand.ColorSystem.primary
            )
            
            Text("Personalized Treatment Navigator")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Answer a few questions to discover your optimal fertility pathway")
                .font(.caption)
                .foregroundColor(Brand.ColorSystem.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Current Selection Section
    private var currentSelectionSection: some View {
        EnhancedContentBlock(
            title: "Your Journey",
            icon: "location.fill"
        ) {
            VStack(spacing: Brand.Spacing.md) {
                // Show current path through questions
                if let category = viewModel.currentCategory {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.body.weight(.medium))
                            .foregroundColor(Brand.ColorSystem.primary)
                        
                        Text(category.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                // Show answered questions
                ForEach(viewModel.answeredQuestions, id: \.question.id) { answer in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(answer.question.question)
                            .font(.caption.weight(.medium))
                            .foregroundColor(Brand.ColorSystem.secondary)
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.success)
                            
                            Text(answer.selectedOption.title)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
    
    // MARK: - Category Selection
    private var categorySelectionSection: some View {
        EnhancedContentBlock(
            title: "Select Your Path",
            icon: "signpost.right.fill"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                Text("What brings you here today?")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                ForEach(AppData.pathwayCategories, id: \.id) { category in
                    Button {
                        viewModel.selectCategory(category)
                    } label: {
                        HStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Brand.ColorSystem.primary.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Brand.ColorSystem.primary)
                            }
                            
                            // Text
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(category.description)
                                    .font(.caption)
                                    .foregroundColor(Brand.ColorSystem.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            // Chevron
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title3)
                                .foregroundColor(Brand.ColorSystem.primary.opacity(0.5))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                                )
                        )
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Question Section
    private var questionSection: some View {
        Group {
            if let currentQuestion = viewModel.currentQuestion {
                EnhancedContentBlock(
                    title: "Question \(viewModel.questionNumber) of \(viewModel.totalQuestions ?? "?")",
                    icon: "questionmark.circle"
                ) {
                    VStack(spacing: Brand.Spacing.lg) {
                        // Question Text
                        VStack(spacing: 8) {
                            Text(currentQuestion.question)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            if let description = currentQuestion.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(Brand.ColorSystem.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Options
                        VStack(spacing: Brand.Spacing.md) {
                            ForEach(currentQuestion.options, id: \.id) { option in
                                Button {
                                    viewModel.selectOption(option, for: currentQuestion)
                                } label: {
                                    HStack(spacing: 12) {
                                        // Icon
                                        if let icon = option.icon {
                                            ZStack {
                                                Circle()
                                                    .fill(Brand.ColorSystem.primary.opacity(0.1))
                                                    .frame(width: 36, height: 36)
                                                
                                                Image(systemName: icon)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(Brand.ColorSystem.primary)
                                            }
                                        }
                                        
                                        // Text
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(option.title)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            if let subtitle = option.subtitle {
                                                Text(subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(Brand.ColorSystem.secondary)
                                                    .multilineTextAlignment(.leading)
                                            }
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
                        
                        // Back button if not first question
                        if viewModel.canGoBack {
                            Button {
                                viewModel.goBack()
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.caption.weight(.medium))
                                    Text("Previous Question")
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundColor(Brand.ColorSystem.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        EnhancedContentBlock(
            title: "Your Recommended Pathways",
            icon: "star.circle.fill"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                if viewModel.recommendedPaths.isEmpty {
                    Text("No pathways match your selections")
                        .font(.subheadline)
                        .foregroundColor(Brand.ColorSystem.secondary)
                } else {
                    ForEach(viewModel.recommendedPaths, id: \.id) { pathway in
                        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                            // Pathway Header
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pathway.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.primary)
                                    
                                    if let description = pathway.description {
                                        Text(description)
                                            .font(.caption2)
                                            .foregroundColor(Brand.ColorSystem.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(pathway.steps.count) steps")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Brand.ColorSystem.primary)
                            }
                            
                            if let recommendedFor = pathway.recommendedFor {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.fill")
                                        .font(.caption2)
                                    Text(recommendedFor)
                                        .font(.caption2)
                                }
                                .foregroundColor(Brand.ColorSystem.secondary)
                            }
                            
                            // View Details Button
                            Button {
                                selectedPathway = pathway
                            } label: {
                                HStack(spacing: 8) {
                                    Text("View Pathway Steps")
                                        .font(.caption.weight(.semibold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Brand.ColorSystem.primary)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Educational Section
    private var educationalSection: some View {
        ExpandableSection(
            title: "Understanding Treatment Pathways",
            subtitle: "Learn about your options",
            icon: "book.circle",
            isExpanded: .constant(false)
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Key Considerations")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 10) {
                    InfoPoint(
                        icon: "1.circle.fill",
                        title: "Personal Factors",
                        description: "Age, medical history, and diagnosis affect treatment options"
                    )
                    
                    InfoPoint(
                        icon: "2.circle.fill",
                        title: "Success Rates",
                        description: "Different pathways have varying success rates based on your situation"
                    )
                    
                    InfoPoint(
                        icon: "3.circle.fill",
                        title: "Timeline",
                        description: "Some treatments take longer but may have higher success rates"
                    )
                    
                    InfoPoint(
                        icon: "4.circle.fill",
                        title: "Cost Considerations",
                        description: "Treatment complexity affects both time and financial investment"
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
}

// MARK: - Info Point Component
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

// MARK: - Pathway Detail Sheet
struct PathwayDetailSheet: View {
    let pathway: PathwayPath
    let educationTopics: [EducationTopic]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            StandardPageLayout(
                primaryImage: "SynagamyLogoTwo",
                secondaryImage: "PathwayLogo",
                showHomeButton: false,
                usePopToRoot: false,
                showBackButton: false
            ) {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        CategoryBadge(
                            text: "PATHWAY",
                            icon: "map.fill",
                            color: Brand.ColorSystem.primary
                        )
                        
                        Text(pathway.title)
                            .font(.largeTitle.bold())
                            .foregroundColor(Brand.ColorSystem.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let description = pathway.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(Brand.ColorSystem.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        if let recommendedFor = pathway.recommendedFor {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                Text("Recommended for: \(recommendedFor)")
                                    .font(.caption)
                            }
                            .foregroundColor(Brand.ColorSystem.primary)
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    Divider()
                    
                    // Flow Diagram
                    if pathway.steps.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: "No steps found",
                            message: "This pathway has no steps yet."
                        )
                        .padding(.top, 12)
                    } else {
                        FlowDiagramView(steps: pathway.steps, educationTopics: educationTopics)
                            .padding(.top, 8)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Brand.ColorSystem.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - View Model
class PathwayViewModel: ObservableObject {
    @Published var currentCategory: PathwayCategory?
    @Published var currentQuestion: PathwayQuestion?
    @Published var answeredQuestions: [(question: PathwayQuestion, selectedOption: PathwayOption)] = []
    @Published var recommendedPaths: [PathwayPath] = []
    
    private let pathwayData = AppData.pathways
    private let allPaths = AppData.pathwayPaths
    
    var hasStarted: Bool {
        currentCategory != nil
    }
    
    var hasActiveSelection: Bool {
        currentCategory != nil || !answeredQuestions.isEmpty
    }
    
    var isComplete: Bool {
        hasStarted && currentQuestion == nil && !recommendedPaths.isEmpty
    }
    
    var canGoBack: Bool {
        !answeredQuestions.isEmpty
    }
    
    var questionNumber: Int {
        answeredQuestions.count + 1
    }
    
    var totalQuestions: String? {
        // This is approximate since it depends on the path taken
        if let category = currentCategory {
            if let questions = category.questions {
                return "\(questions.count)"
            }
        }
        return nil
    }
    
    func selectCategory(_ category: PathwayCategory) {
        currentCategory = category
        answeredQuestions = []
        recommendedPaths = []
        
        // Start with first question if available
        if let firstQuestion = category.questions?.first {
            currentQuestion = firstQuestion
        } else if let directPaths = category.paths {
            // Category has direct paths without questions
            recommendedPaths = directPaths
            currentQuestion = nil
        }
    }
    
    func selectOption(_ option: PathwayOption, for question: PathwayQuestion) {
        // Store the answer
        answeredQuestions.append((question: question, selectedOption: option))
        
        // Check if option leads to paths
        if let pathIds = option.pathIds {
            // Find the recommended paths
            let paths = allPaths.filter { pathIds.contains($0.id) }
            recommendedPaths.append(contentsOf: paths)
            currentQuestion = nil
        }
        // Check if option leads to next question
        else if let nextQuestionId = option.nextQuestion {
            // Find next question
            currentQuestion = findQuestion(withId: nextQuestionId)
        }
        // No next step - complete
        else {
            currentQuestion = nil
        }
    }
    
    func goBack() {
        guard !answeredQuestions.isEmpty else { return }
        
        // Remove last answer
        let removed = answeredQuestions.removeLast()
        
        // Reset to that question
        currentQuestion = removed.question
        
        // Clear any paths that were set
        if recommendedPaths.count > 0 {
            // Remove paths that were added by this question
            if let option = answeredQuestions.last?.selectedOption,
               let pathIds = option.pathIds {
                recommendedPaths.removeAll { pathIds.contains($0.id) }
            } else {
                recommendedPaths = []
            }
        }
    }
    
    func reset() {
        currentCategory = nil
        currentQuestion = nil
        answeredQuestions = []
        recommendedPaths = []
    }
    
    private func findQuestion(withId id: String) -> PathwayQuestion? {
        guard let category = currentCategory,
              let questions = category.questions else { return nil }
        
        return questions.first { $0.id == id }
    }
}

#Preview {
    NavigationStack {
        PathwayView()
    }
}