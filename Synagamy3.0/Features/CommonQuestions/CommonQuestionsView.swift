//
//  CommonQuestionsView.swift
//  Synagamy3.0
//
//  Displays a list of common questions. Tapping a question opens an answer sheet
//  with related topics and references. This refactor:
//   • Uses the shared OnChangeHeightModifier (no local duplicates).
//   • Adds friendly empty-state handling + user-facing alerts for recoverable issues.
//   • Avoids force-unwraps and fragile assumptions.
//   • Improves accessibility labels.
//
//  Prereqs:
//   • UI/Modifiers/OnChangeHeightModifier.swift
//   • UI/Components/{BrandTile,BrandCard,EmptyStateView,HomeButton,FloatingLogoHeader}.swift
//

import SwiftUI

struct CommonQuestionsView: View {
    // MARK: - UI state
    @State private var questions: [CommonQuestion] = []     // loaded onAppear
    @State private var selected: CommonQuestion? = nil      // drives the sheet
    // REMOVED: @State private var errorMessage: String? = nil          // user-friendly alert text
    // REMOVED: @State private var showingErrorAlert = false
    @State private var expandedRelatedTopics: Set<String> = []  // tracks which related topics are expanded
    @State private var showReferences = false  // tracks if references section is expanded
    @State private var isLoading = false

    @StateObject private var networkManager = NetworkStatusManager.shared
    @StateObject private var remoteDataService = RemoteDataService.shared
    // REMOVED: @StateObject private var networkManager = NetworkStatusManager.shared
    // REMOVED: @StateObject private var remoteDataService = RemoteDataService.shared

    // MARK: - Data Loading

    private func loadCommonQuestions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            questions = await remoteDataService.loadCommonQuestions()

            if questions.isEmpty {
                // Handle empty state - could show message to user
            }
        } catch {
            // Handle error - could show message to user
        }
    }

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "CommonQuestionsLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    // Header Section
                    VStack(spacing: 12) {
                        CategoryBadge(
                            text: "FAQ Center",
                            icon: "questionmark.bubble.fill",
                            color: Brand.Color.primary
                        )
                        
                        Text("Common Questions")
                            .font(Brand.Typography.headlineMedium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Find answers to frequently asked questions")
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(Brand.Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: - Network Status Check
                    if !networkManager.isOnline && questions.isEmpty {
                        ContentLoadingErrorView(
                            title: "Questions Unavailable",
                            message: "Common questions require an internet connection to access the latest answers and guidance."
                        ) {
                            Task { await loadCommonQuestions() }
                        }
                        .padding(.top, 20)
                        .fertilityAccessibility(
                            label: "Questions unavailable",
                            hint: "Internet connection required. Double tap to retry loading questions",
                            traits: [.isButton]
                        )
                    } else if isLoading {
                        LoadingStateView(
                            message: "Loading questions...",
                            showProgress: true
                        )
                        .padding(.top, 20)
                    } else if questions.isEmpty {
                        EmptyStateView(
                            icon: "questionmark.circle",
                            title: "No questions available",
                            message: "Please check back later."
                        )
                        .padding(.top, 40)
                        .fertilityAccessibility(
                            label: "No questions available",
                            value: "Please check back later",
                            traits: [.isStaticText]
                        )
                    } else {
                        EnhancedContentBlock(
                            title: "Browse Questions",
                            icon: "questionmark.bubble.fill"
                        ) {
                            VStack(spacing: Brand.Spacing.md) {
                                ForEach(questions, id: \.id) { question in
                                    Button {
                                        selected = question
                                        AccessibilityAnnouncement.announce("Opening question: \(question.question)")
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Icon
                                            ZStack {
                                                Circle()
                                                    .fill(Brand.Color.primary.opacity(0.1))
                                                    .frame(width: 36, height: 36)

                                                Image(systemName: "questionmark")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(Brand.Color.primary)
                                            }
                                            .accessibilityHidden(true) // Decorative icon

                                            // Question text
                                            Text(question.question)
                                                .font(Brand.Typography.bodySmall)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(3)

                                            Spacer()

                                            // Chevron
                                            Image(systemName: "chevron.right")
                                                .font(Brand.Typography.labelSmall)
                                                .foregroundColor(Brand.Color.secondary)
                                                .accessibilityHidden(true) // Decorative arrow
                                        }
                                        .padding(Brand.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Brand.Color.hairline.opacity(0.5), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .fertilityAccessibility(
                                        label: "Question: \(question.question)",
                                        hint: "Double tap to read the detailed answer",
                                        traits: [.isButton]
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, Brand.Spacing.lg)
            }
        }
        
        // Unified error handling with recovery options
        // Error handling would go here

        // Load data once. We guard against surprises and surface a friendly message on failure.
        .task {
            await loadCommonQuestions()
        }
        .onDynamicTypeChange { size in
            // Handle dynamic type changes for better accessibility
            #if DEBUG
            print("CommonQuestionsView: Dynamic Type size changed to \(size)")
            #endif
        }
        .onAppear {
            AccessibilityAnnouncement.announce("Common questions section loaded. Browse frequently asked fertility questions.")
        }

        // Q&A detail sheet
        .sheet(item: $selected) { q in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Enhanced header
                        VStack(alignment: .leading, spacing: 12) {
                            // Category badge
                            CategoryBadge(
                                text: "FAQ",
                                icon: "questionmark.bubble.fill",
                                color: Brand.Color.primary
                            )
                            
                            // Main question
                            Text(q.question)
                                .font(Brand.Typography.headlineLarge)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Brand.Color.primary, Brand.Color.primary.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                        }
                        .padding(.bottom, 4)
                        
                        // Divider
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Brand.Color.primary.opacity(0.3), Brand.Color.primary.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1)
                            .padding(.bottom, 4)

                        // MARK: - Answer content
                        VStack(alignment: .leading, spacing: 10) {
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
                                
                                Text("Answer")
                                    .font(Brand.Typography.headlineMedium)
                                    .foregroundColor(Brand.Color.primary)
                            }
                            
                            Text(q.detailedAnswer)
                                .font(Brand.Typography.bodySmall)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                                .padding(Brand.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [Brand.Color.hairline, Brand.Color.hairline.opacity(0.3)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }

                        // Related topics with enhanced design
                        if !q.relatedTopics.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "link.circle.fill")
                                        .font(.body)
                                        .foregroundColor(Brand.Color.primary)
                                    
                                    Text("Related Topics")
                                        .font(Brand.Typography.headlineMedium)
                                        .foregroundColor(Brand.Color.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(q.relatedTopics, id: \.self) { topic in
                                        VStack(alignment: .leading, spacing: 8) {
                                            // Expandable topic button
                                            Button {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    if expandedRelatedTopics.contains(topic) {
                                                        expandedRelatedTopics.remove(topic)
                                                    } else {
                                                        expandedRelatedTopics.insert(topic)
                                                    }
                                                }
                                            } label: {
                                                HStack(alignment: .center, spacing: 12) {
                                                    Circle()
                                                        .fill(Brand.Color.primary.opacity(0.15))
                                                        .frame(width: 32, height: 32)
                                                        .overlay(
                                                            Image(systemName: "arrow.turn.down.right")
                                                                .font(.caption)
                                                                .foregroundColor(Brand.Color.primary)
                                                        )
                                                    
                                                    Text(topic)
                                                        .font(Brand.Typography.bodyMedium)
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: expandedRelatedTopics.contains(topic) ? "chevron.up.circle.fill" : "chevron.down.circle")
                                                        .font(.body)
                                                        .foregroundStyle(Brand.Color.primary)
                                                        .animation(.spring(response: 0.3), value: expandedRelatedTopics.contains(topic))
                                                }
                                                .padding(Brand.Spacing.md)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(Brand.Color.primary.opacity(0.05))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                .strokeBorder(Brand.Color.hairline.opacity(0.5), lineWidth: 1)
                                                        )
                                                )
                                            }
                                            .buttonStyle(.plain)
                                            
                                            // Expanded content with lay explanation
                                            if expandedRelatedTopics.contains(topic) {
                                                if let relatedTopic = AppData.topics.first(where: { $0.topic == topic }) {
                                                    VStack(alignment: .leading, spacing: 12) {
                                                        Text(relatedTopic.layExplanation)
                                                            .font(Brand.Typography.bodySmall)
                                                            .foregroundColor(.primary.opacity(0.8))
                                                            .lineSpacing(3)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                            .padding(Brand.Spacing.md)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                    .fill(.ultraThinMaterial)
                                                                    .overlay(
                                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                            .strokeBorder(Brand.Color.hairline.opacity(0.3), lineWidth: 1)
                                                                    )
                                                            )
                                                        
                                                        // View Topic Details button
                                                        NavigationLink {
                                                            ScrollView {
                                                                TopicDetailContent(topic: relatedTopic)
                                                                    .padding()
                                                            }
                                                            .navigationBarTitleDisplayMode(.inline)
                                                        } label: {
                                                            HStack(spacing: 8) {
                                                                Text("View Topic Details")
                                                                    .font(Brand.Typography.labelMedium)
                                                                Image(systemName: "arrow.right.circle.fill")
                                                                    .font(Brand.Typography.labelMedium)
                                                            }
                                                            .foregroundColor(.white)
                                                            .frame(maxWidth: .infinity)
                                                            .padding(.vertical, Brand.Spacing.sm)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                                    .fill(Brand.Color.primary)
                                                            )
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                    .padding(.leading, 8)
                                                    .transition(.asymmetric(
                                                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).combined(with: .offset(y: -10)),
                                                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                                                    ))
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(Brand.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(Brand.Color.hairline, lineWidth: 1)
                                        )
                                )
                            }
                        }

                        // References using ExpandableSection component
                        if !q.reference.isEmpty {
                            ExpandableSection(
                                title: "References",
                                subtitle: "\(q.reference.count) source\(q.reference.count == 1 ? "" : "s")",
                                icon: "doc.text.magnifyingglass",
                                isExpanded: $showReferences
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(q.reference, id: \.self) { link in
                                        if let url = URL(string: link) {
                                            Link(destination: url) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "link")
                                                        .font(.caption)
                                                        .foregroundColor(Brand.Color.primary)
                                                    
                                                    Text(link)
                                                        .font(Brand.Typography.bodyMedium)
                                                        .foregroundColor(Brand.Color.primary)
                                                        .underline()
                                                        .lineLimit(2)
                                                        .truncationMode(.middle)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                        } else {
                                            HStack(spacing: 8) {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(Brand.Typography.labelSmall)
                                                    .foregroundColor(.orange)
                                                
                                                Text(link)
                                                    .font(Brand.Typography.bodyMedium)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                                    .truncationMode(.middle)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }
                                    }
                                }
                                .padding(Brand.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(Brand.Color.hairline, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .tint(Brand.Color.primary)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
