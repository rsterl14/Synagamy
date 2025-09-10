//
//  PersonalizedCycleDetailView.swift
//  Synagamy3.0
//
//  Detailed view for saved fertility cycles showing step-by-step learning experience
//  with organized educational topics for each pathway step.
//

import SwiftUI

struct PersonalizedCycleDetailView: View {
    let cycle: SavedCycle
    let cycleManager: PersonalizedCycleManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var expandedSteps: Set<String> = []
    @State private var selectedTopic: EducationTopic?
    @State private var showingTopicDetail = false
    
    private var stepsWithTopics: [StepWithTopics] {
        cycleManager.getStepsWithTopics(for: cycle)
    }
    
    var body: some View {
        NavigationStack {
            StandardPageLayout(
                primaryImage: "SynagamyLogoTwo",
                secondaryImage: "PathwayLogo",
                showHomeButton: false,
                usePopToRoot: false,
                showBackButton: false
            ) {
                ScrollView {
                    VStack(spacing: Brand.Spacing.lg) {
                        
                        // MARK: - Header
                        headerSection
                        
                        // MARK: - Your Journey Summary
                        journeySummarySection
                        
                        // MARK: - Step-by-Step Learning
                        learningStepsSection
                    }
                    .padding(.vertical, Brand.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
        .sheet(item: $selectedTopic) { topic in
            NavigationStack {
                ScrollView {
                    TopicDetailContent(topic: topic, selectedTopic: $selectedTopic)
                        .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            selectedTopic = nil
                        }
                        .foregroundColor(Brand.ColorSystem.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CategoryBadge(
                text: "My Cycle",
                icon: "bookmark.fill",
                color: Brand.ColorSystem.primary
            )
            
            Text(cycle.name)
                .font(.largeTitle.bold())
                .foregroundColor(Brand.ColorSystem.primary)
                .multilineTextAlignment(.leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(cycle.pathway.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                if let description = cycle.pathway.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Brand.ColorSystem.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Created \(cycle.formattedDateCreated)")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                        Text("\(stepsWithTopics.count) learning steps")
                            .font(.caption)
                    }
                }
                .foregroundColor(Brand.ColorSystem.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Journey Summary
    private var journeySummarySection: some View {
        EnhancedContentBlock(
            title: "Your Journey Summary",
            icon: "map.fill"
        ) {
            VStack(spacing: Brand.Spacing.md) {
                ForEach(Array(cycle.questionsAndAnswers.enumerated()), id: \.offset) { index, qa in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number
                        ZStack {
                            Circle()
                                .fill(Brand.ColorSystem.primary.opacity(0.15))
                                .frame(width: 24, height: 24)
                            
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Brand.ColorSystem.primary)
                        }
                        
                        // Q&A Content
                        VStack(alignment: .leading, spacing: 4) {
                            Text(qa.questionText)
                                .font(.caption.weight(.medium))
                                .foregroundColor(Brand.ColorSystem.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Text(qa.selectedOptionText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    if index < cycle.questionsAndAnswers.count - 1 {
                        Divider()
                            .padding(.leading, 36)
                    }
                }
            }
        }
    }
    
    // MARK: - Learning Steps Section
    private var learningStepsSection: some View {
        EnhancedContentBlock(
            title: "Step-by-Step Learning Experience",
            icon: "graduationcap.fill"
        ) {
            VStack(spacing: Brand.Spacing.md) {
                ForEach(Array(stepsWithTopics.enumerated()), id: \.offset) { index, stepWithTopics in
                    StepLearningCard(
                        stepNumber: index + 1,
                        stepWithTopics: stepWithTopics,
                        isExpanded: expandedSteps.contains(stepWithTopics.id),
                        onToggleExpanded: {
                            if expandedSteps.contains(stepWithTopics.id) {
                                expandedSteps.remove(stepWithTopics.id)
                            } else {
                                expandedSteps.insert(stepWithTopics.id)
                            }
                        },
                        onTopicTap: { topic in
                            selectedTopic = topic
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Step Learning Card

private struct StepLearningCard: View {
    let stepNumber: Int
    let stepWithTopics: StepWithTopics
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    let onTopicTap: (EducationTopic) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onToggleExpanded()
                }
            } label: {
                HStack(spacing: 12) {
                    // Step number with timeline
                    VStack(spacing: 0) {
                        // Upper line (hidden for first step)
                        Rectangle()
                            .fill(Brand.ColorSystem.primary.opacity(stepNumber == 1 ? 0 : 0.3))
                            .frame(width: 2, height: 16)
                        
                        // Step circle
                        ZStack {
                            Circle()
                                .fill(Brand.ColorSystem.primary)
                                .frame(width: 28, height: 28)
                            
                            Text("\(stepNumber)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                        
                        // Lower line
                        Rectangle()
                            .fill(Brand.ColorSystem.primary.opacity(0.3))
                            .frame(width: 2, height: 16)
                    }
                    
                    // Step content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stepWithTopics.step.step)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let overview = stepWithTopics.step.overview,
                           !overview.isEmpty {
                            Text(overview)
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        // Topic count
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption2)
                            Text("\(stepWithTopics.matchedTopics.count) related topics")
                                .font(.caption)
                        }
                        .foregroundColor(Brand.ColorSystem.primary)
                    }
                    
                    Spacer()
                    
                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(Brand.ColorSystem.primary)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                    if stepWithTopics.matchedTopics.isEmpty {
                        HStack {
                            Spacer()
                            Text("No related topics found")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(stepWithTopics.matchedTopics, id: \.id) { topic in
                                TopicLearningCard(
                                    topic: topic,
                                    onTap: { onTopicTap(topic) }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Brand.ColorSystem.primary.opacity(0.05))
                        .padding(.horizontal, 8)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                )
        )
    }
}

// MARK: - Topic Learning Card

private struct TopicLearningCard: View {
    let topic: EducationTopic
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 10) {
                // Topic icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Brand.ColorSystem.primary.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Brand.ColorSystem.primary)
                }
                
                // Topic info
                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.topic)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(topic.category)
                            .font(.caption)
                    }
                    .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                Spacer()
                
                // Read indicator
                Image(systemName: "arrow.right.circle.fill")
                    .font(.body)
                    .foregroundColor(Brand.ColorSystem.primary.opacity(0.6))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Brand.ColorToken.hairline.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // Create a sample saved cycle for preview
    let samplePathway = PathwayPath(
        id: "sample_pathway",
        title: "IVF with Fresh Embryo Transfer",
        description: "Complete IVF cycle with fresh embryo transfer",
        suitableFor: "Couples with various fertility issues",
        steps: [
            PathwayStep(
                step: "Initial Consultation",
                overview: "Comprehensive fertility evaluation",
                topicRefs: ["Female Fertility Evaluation", "Male Fertility Evaluation"]
            ),
            PathwayStep(
                step: "Ovarian Stimulation",
                overview: "Stimulate egg production",
                topicRefs: ["Controlled Ovarian Stimulation", "FSH (Follicle Stimulating Hormone)"]
            )
        ]
    )
    
    let sampleCycle = SavedCycle(
        id: "sample",
        name: "My IVF Journey",
        pathway: samplePathway,
        dateCreated: Date(),
        lastAccessed: Date(),
        questionsAndAnswers: [
            QuestionAnswer(questionId: "q1", questionText: "Treatment goal?", selectedOptionId: "ivf", selectedOptionText: "IVF Treatment"),
            QuestionAnswer(questionId: "q2", questionText: "Embryo source?", selectedOptionId: "own", selectedOptionText: "Own Eggs")
        ],
        category: "IVF Treatment"
    )
    
    PersonalizedCycleDetailView(
        cycle: sampleCycle,
        cycleManager: PersonalizedCycleManager()
    )
}