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
    @StateObject private var cycleManager = PersonalizedCycleManager()
    @State private var showingPathwayDetails = false
    @State private var selectedPathway: PathwayPath?
    @State private var isEducationExpanded = false
    @State private var showingSaveCycleDialog = false
    @State private var pathwayToSave: PathwayPath?
    @State private var cycleName: String = ""
    
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
        .alert("Save Your Cycle", isPresented: $showingSaveCycleDialog) {
            TextField("Name your cycle", text: $cycleName)
                .textInputAutocapitalization(.words)
            Button("Save") {
                if let pathway = pathwayToSave, !cycleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    saveCycle(pathway: pathway, name: cycleName)
                }
                resetSaveDialog()
            }
            Button("Cancel", role: .cancel) {
                resetSaveDialog()
            }
        } message: {
            Text("Give your personalized fertility cycle a memorable name to easily find it later.")
        }
        .onAppear {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Treatment pathway navigator loaded. Select a pathway category to begin."
                )
            }
        }
        .registerForAccessibilityAudit(
            viewName: "PathwayView",
            hasAccessibilityLabels: true,
            hasDynamicTypeSupport: true,
            hasVoiceOverSupport: true
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Brand.Spacing.lg) {
            VStack(spacing: Brand.Spacing.md) {
                CategoryBadge(
                    text: "Treatment Pathways",
                    icon: "map.fill",
                    color: Brand.Color.primary
                )
                
                Text("Personalized Treatment Navigator")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Answer a Few Questions to Discover a Infertility Treatment or Fertility Preservation Pathway.\n\n Fertility Pathways Can Vary Between Fertility Clinics")
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // My Cycles Navigation
            if !cycleManager.savedCycles.isEmpty {
                NavigationLink {
                    PersonalizedLearningView()
                } label: {
                    HStack(spacing: Brand.Spacing.sm) {
                        Image(systemName: "bookmark.fill")
                            .font(Brand.Typography.labelMedium)
                        Text("My Saved Cycles (\(cycleManager.savedCycles.count))")
                            .font(Brand.Typography.labelMedium.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(Brand.Typography.labelSmall)
                    }
                    .foregroundColor(Brand.Color.primary)
                    .padding(.horizontal, Brand.Spacing.lg)
                    .padding(.vertical, Brand.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                            .fill(Brand.Color.primary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                    .stroke(Brand.Color.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .fertilityAccessibility(
                    label: "My Saved Cycles. \(cycleManager.savedCycles.count) cycles saved",
                    hint: "Double tap to view your personalized treatment cycles",
                    traits: [.isButton]
                )
            }
        }
        .padding(.horizontal, Brand.Spacing.lg)
    }
    
    // MARK: - Current Selection Section
    private var currentSelectionSection: some View {
        EnhancedContentBlock(
            title: "Your Journey",
            icon: "location.fill"
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                // Show current path through questions
                if let category = viewModel.currentCategory {
                    HStack {
                        Image(systemName: category.icon)
                            .font(Brand.Typography.bodyMedium.weight(.medium))
                            .foregroundColor(Brand.Color.primary)
                        
                        Text(category.title)
                            .font(Brand.Typography.labelLarge.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                // Show answered questions
                ForEach(viewModel.answeredQuestions, id: \.question.id) { answer in
                    VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                        Text(answer.question.question)
                            .font(Brand.Typography.labelSmall.weight(.medium))
                            .foregroundColor(Brand.Color.secondary)
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(Brand.Typography.labelSmall)
                                .foregroundColor(Brand.Color.success)
                            
                            Text(answer.selectedOption.title)
                                .font(Brand.Typography.labelSmall.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .padding(.leading, Brand.Spacing.xl)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Category Selection
    private var categorySelectionSection: some View {
        EnhancedContentBlock(
            title: "Select Your Path",
            icon: "signpost.right.fill"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                Text("What Brings You Here Today?")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                ForEach(AppData.pathwayCategories, id: \.id) { category in
                    Button {
                        viewModel.selectCategory(category)
                    } label: {
                        HStack(spacing: Brand.Spacing.lg) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Brand.Color.primary.opacity(0.15))
                                    .frame(width: Brand.Spacing.spacing10, height: Brand.Spacing.spacing10)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: Brand.Typography.Size.xl, weight: Brand.Typography.Weight.medium))
                                    .foregroundColor(Brand.Color.primary)
                            }
                            
                            // Text
                            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                                Text(category.title)
                                    .font(Brand.Typography.bodySmall)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(category.description)
                                    .font(Brand.Typography.labelSmall)
                                    .foregroundColor(Brand.Color.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            // Chevron
                            Image(systemName: "chevron.right.circle.fill")
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.Color.primary.opacity(0.5))
                        }
                        .padding(Brand.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                                        .stroke(Brand.Color.hairline, lineWidth: 1)
                                )
                        )
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .fertilityAccessibility(
                        label: "\(category.title). \(category.description)",
                        hint: "Double tap to start pathway questions for \(category.title.lowercased())",
                        traits: [.isButton]
                    )
                }
            }
        }
    }
    
    // MARK: - Question Section
    private var questionSection: some View {
        Group {
            if let currentQuestion = viewModel.currentQuestion {
                questionContentView(for: currentQuestion)
            }
        }
    }

    private func questionContentView(for question: PathwayQuestion) -> some View {
        EnhancedContentBlock(
            title: "Question \(viewModel.questionNumber) of \(viewModel.totalQuestions ?? "?")",
            icon: "questionmark.circle"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                questionTextView(for: question)
                questionOptionsView(for: question)

                if viewModel.canGoBack {
                    backButton
                }
            }
        }
    }

    private func questionTextView(for question: PathwayQuestion) -> some View {
        VStack(spacing: Brand.Spacing.sm) {
            Text(question.question)
                .font(Brand.Typography.headlineMedium.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            if let description = question.description {
                Text(description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func questionOptionsView(for question: PathwayQuestion) -> some View {
        VStack(spacing: Brand.Spacing.md) {
            ForEach(question.options, id: \.id) { option in
                questionOptionButton(option: option, question: question)
            }
        }
    }

    private func questionOptionButton(option: PathwayOption, question: PathwayQuestion) -> some View {
        Button {
            viewModel.selectOption(option, for: question)
        } label: {
            optionButtonContent(for: option)
        }
        .buttonStyle(.plain)
        .fertilityAccessibility(
            label: "\(option.title). \(option.subtitle ?? "")",
            hint: "Double tap to select this pathway option",
            traits: [.isButton]
        )
    }

    private func optionButtonContent(for option: PathwayOption) -> some View {
        HStack(spacing: Brand.Spacing.md) {
            optionIconView(for: option)
            optionTextView(for: option)
            Spacer()
            selectionIndicator
        }
        .padding(Brand.Spacing.md)
        .background(optionBackgroundStyle)
    }

    @ViewBuilder
    private func optionIconView(for option: PathwayOption) -> some View {
        if let icon = option.icon {
            ZStack {
                Circle()
                    .fill(Brand.Color.primary.opacity(0.1))
                    .frame(width: Brand.Spacing.spacing9, height: Brand.Spacing.spacing9)

                Image(systemName: icon)
                    .font(.system(size: Brand.Typography.Size.lg, weight: Brand.Typography.Weight.medium))
                    .foregroundColor(Brand.Color.primary)
            }
        }
    }

    private func optionTextView(for option: PathwayOption) -> some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.spacing1) {
            Text(option.title)
                .font(Brand.Typography.labelMedium.weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            if let subtitle = option.subtitle {
                Text(subtitle)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private var selectionIndicator: some View {
        Image(systemName: "arrow.right.circle")
            .font(Brand.Typography.bodyMedium)
            .foregroundColor(Brand.Color.primary.opacity(0.5))
    }

    private var optionBackgroundStyle: some View {
        RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                    .stroke(Brand.Color.hairline, lineWidth: 1)
            )
    }

    private var backButton: some View {
        Button {
            viewModel.goBack()
        } label: {
            HStack {
                Image(systemName: "chevron.left")
                    .font(Brand.Typography.labelSmall.weight(.medium))
                Text("Previous Question")
                    .font(Brand.Typography.labelSmall.weight(.medium))
            }
            .foregroundColor(Brand.Color.secondary)
        }
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        EnhancedContentBlock(
            title: "Your Pathway Options",
            icon: "star.circle.fill"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                if viewModel.pathwayOptions.isEmpty {
                    Text("No pathways match your selections")
                        .font(Brand.Typography.labelMedium)
                        .foregroundColor(Brand.Color.secondary)
                } else {
                    ForEach(viewModel.pathwayOptions, id: \.id) { pathway in
                        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                            // Pathway Header
                            HStack {
                                VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                                    Text(pathway.title)
                                        .font(Brand.Typography.bodyMedium.weight(.semibold))
                                        .foregroundColor(.primary)
                                    
                                    if let description = pathway.description {
                                        Text(description)
                                            .font(Brand.Typography.labelSmall)
                                            .foregroundColor(Brand.Color.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(pathway.steps.count) steps")
                                    .font(Brand.Typography.labelSmall.weight(.medium))
                                    .foregroundColor(Brand.Color.primary)
                            }
                            
                            if let suitableFor = pathway.suitableFor {
                                HStack(spacing: Brand.Spacing.xs) {
                                    Image(systemName: "person.fill")
                                        .font(Brand.Typography.labelSmall)
                                    Text(suitableFor)
                                        .font(Brand.Typography.labelSmall)
                                }
                                .foregroundColor(Brand.Color.secondary)
                            }
                            
                            // Action Buttons
                            HStack(spacing: Brand.Spacing.sm) {
                                // View Details Button
                                Button {
                                    selectedPathway = pathway
                                } label: {
                                    HStack(spacing: Brand.Spacing.xs) {
                                        Text("View Steps")
                                            .font(Brand.Typography.labelSmall.weight(.semibold))
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(Brand.Typography.labelSmall)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                            .fill(Brand.Color.primary)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // Save Cycle Button
                                Button {
                                    pathwayToSave = pathway
                                    cycleName = generateDefaultCycleName(for: pathway)
                                    showingSaveCycleDialog = true
                                } label: {
                                    HStack(spacing: Brand.Spacing.xs) {
                                        Text("Save Cycle")
                                            .font(Brand.Typography.labelSmall.weight(.semibold))
                                        Image(systemName: "bookmark.fill")
                                            .font(Brand.Typography.labelSmall)
                                    }
                                    .foregroundColor(Brand.Color.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                            .stroke(Brand.Color.primary, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(Brand.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                        .stroke(Brand.Color.primary.opacity(0.2), lineWidth: 1)
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
            isExpanded: $isEducationExpanded
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Key Considerations")
                    .font(Brand.Typography.labelLarge.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
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
            HStack(spacing: Brand.Spacing.sm) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                Text("Start Over")
                    .font(.subheadline.weight(.medium))
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
}

// MARK: - Info Point Component
private struct InfoPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: icon)
                .font(Brand.Typography.labelSmall.weight(.bold))
                .foregroundColor(Brand.Color.primary)
                .frame(width: Brand.Spacing.xl)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.spacing1) {
                Text(title)
                    .font(Brand.Typography.labelSmall.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
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
                VStack(spacing: Brand.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        CategoryBadge(
                            text: "PATHWAY",
                            icon: "map.fill",
                            color: Brand.Color.primary
                        )
                        
                        Text(pathway.title)
                            .font(Brand.Typography.displayLarge.bold())
                            .foregroundColor(Brand.Color.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let description = pathway.description {
                            Text(description)
                                .font(Brand.Typography.labelMedium)
                                .foregroundColor(Brand.Color.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        if let suitableFor = pathway.suitableFor {
                            HStack(spacing: Brand.Spacing.xs) {
                                Image(systemName: "person.fill")
                                    .font(Brand.Typography.labelSmall)
                                Text("Suitable for: \(suitableFor)")
                                    .font(Brand.Typography.labelSmall)
                            }
                            .foregroundColor(Brand.Color.primary)
                            .padding(.top, Brand.Spacing.xs)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Brand.Spacing.lg)
                    
                    Divider()
                    
                    // Flow Diagram
                    if pathway.steps.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: "No steps found",
                            message: "This pathway has no steps yet."
                        )
                        .padding(.top, Brand.Spacing.md)
                    } else {
                        FlowDiagramView(steps: pathway.steps, educationTopics: educationTopics)
                            .padding(.top, Brand.Spacing.sm)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Brand.Color.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - PathwayView Helper Methods

extension PathwayView {
    private func saveCycle(pathway: PathwayPath, name: String) {
        let questionsAndAnswers = viewModel.answeredQuestions.map { qa in
            QuestionAnswer(
                questionId: qa.question.id,
                questionText: qa.question.question,
                selectedOptionId: qa.selectedOption.id,
                selectedOptionText: qa.selectedOption.title
            )
        }
        
        let categoryName = viewModel.currentCategory?.title ?? "Unknown"
        
        cycleManager.saveCycle(
            name: name,
            pathway: pathway,
            questionsAndAnswers: questionsAndAnswers,
            category: categoryName
        )
    }
    
    private func generateDefaultCycleName(for pathway: PathwayPath) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateString = dateFormatter.string(from: Date())
        
        return "My \(pathway.title) - \(dateString)"
    }
    
    private func resetSaveDialog() {
        showingSaveCycleDialog = false
        pathwayToSave = nil
        cycleName = ""
    }
}

// MARK: - View Model
@MainActor
class PathwayViewModel: ObservableObject {
    @Published var currentCategory: PathwayCategory?
    @Published var currentQuestion: PathwayQuestion?
    @Published var answeredQuestions: [(question: PathwayQuestion, selectedOption: PathwayOption)] = []
    @Published var pathwayOptions: [PathwayPath] = []
    
    private let pathwayData = AppData.pathways
    private let allPaths = AppData.pathwayPaths
    
    var hasStarted: Bool {
        currentCategory != nil
    }
    
    var hasActiveSelection: Bool {
        currentCategory != nil || !answeredQuestions.isEmpty
    }
    
    var isComplete: Bool {
        hasStarted && currentQuestion == nil && !pathwayOptions.isEmpty
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
        pathwayOptions = []
        
        // Start with first question if available
        if let firstQuestion = category.questions?.first {
            currentQuestion = firstQuestion
        } else if let directPaths = category.paths {
            // Category has direct paths without questions
            pathwayOptions = directPaths
            currentQuestion = nil
        }
    }
    
    func selectOption(_ option: PathwayOption, for question: PathwayQuestion) {
        // Store the answer
        answeredQuestions.append((question: question, selectedOption: option))
        
        // Check if option leads to paths
        if let pathIds = option.pathIds {
            // Find the matching paths
            let paths = allPaths.filter { pathIds.contains($0.id) }
            pathwayOptions.append(contentsOf: paths)
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
        if pathwayOptions.count > 0 {
            // Remove paths that were added by this question
            if let option = answeredQuestions.last?.selectedOption,
               let pathIds = option.pathIds {
                pathwayOptions.removeAll { pathIds.contains($0.id) }
            } else {
                pathwayOptions = []
            }
        }
    }
    
    func reset() {
        currentCategory = nil
        currentQuestion = nil
        answeredQuestions = []
        pathwayOptions = []
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
