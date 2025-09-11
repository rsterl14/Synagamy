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
    @State private var errorMessage: String? = nil          // user-friendly alert text
    @State private var showingErrorAlert = false
    @State private var expandedRelatedTopics: Set<String> = []  // tracks which related topics are expanded
    @State private var showReferences = false  // tracks if references section is expanded

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
                            color: Brand.ColorSystem.primary
                        )
                        
                        Text("Common Questions")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Find answers to frequently asked questions")
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                    // Questions List
                    if questions.isEmpty {
                        EmptyStateView(
                            icon: "questionmark.circle",
                            title: "No questions available",
                            message: "Please check back later."
                        )
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: Brand.Spacing.md) {
                            ForEach(questions, id: \.id) { question in
                                Button {
                                    selected = question
                                } label: {
                                    HStack(spacing: 12) {
                                        // Icon
                                        ZStack {
                                            Circle()
                                                .fill(Brand.ColorSystem.primary.opacity(0.1))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "questionmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(Brand.ColorSystem.primary)
                                        }
                                        
                                        // Question text
                                        Text(question.question)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(3)
                                        
                                        Spacer()
                                        
                                        // Chevron
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(Brand.ColorSystem.secondary)
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
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, Brand.Spacing.lg)
            }
        }
        
        // Friendly non-technical alert for recoverable issues
        .alert("Something went wrong", isPresented: $showingErrorAlert, actions: {
            Button("OK", role: .cancel) { 
                showingErrorAlert = false
                errorMessage = nil 
            }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Load data once. We guard against surprises and surface a friendly message on failure.
        .task {
            // Load questions from static data
            let loaded = AppData.questions
            if loaded.isEmpty {
                // Not an error per se, but we can optionally inform the user elsewhere.
                // We keep UI responsive with the empty-state card above.
            }
            questions = loaded
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
                                color: Brand.ColorSystem.primary
                            )
                            
                            // Main question
                            Text(q.question)
                                .font(.largeTitle.bold())
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Brand.ColorSystem.primary, Brand.ColorSystem.primary.opacity(0.8)],
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
                                colors: [Brand.ColorSystem.primary.opacity(0.3), Brand.ColorSystem.primary.opacity(0.05)],
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
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Brand.ColorSystem.primary)
                            }
                            
                            Text(q.detailedAnswer)
                                .font(.callout)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [Brand.ColorToken.hairline, Brand.ColorToken.hairline.opacity(0.3)],
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
                                        .foregroundColor(Brand.ColorSystem.primary)
                                    
                                    Text("Related Topics")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Brand.ColorSystem.primary)
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
                                                        .fill(Brand.ColorSystem.primary.opacity(0.15))
                                                        .frame(width: 32, height: 32)
                                                        .overlay(
                                                            Image(systemName: "arrow.turn.down.right")
                                                                .font(.caption)
                                                                .foregroundColor(Brand.ColorSystem.primary)
                                                        )
                                                    
                                                    Text(topic)
                                                        .font(.body.weight(.medium))
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: expandedRelatedTopics.contains(topic) ? "chevron.up.circle.fill" : "chevron.down.circle")
                                                        .font(.body)
                                                        .foregroundStyle(Brand.ColorSystem.primary)
                                                        .animation(.spring(response: 0.3), value: expandedRelatedTopics.contains(topic))
                                                }
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(Brand.ColorSystem.primary.opacity(0.05))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                .strokeBorder(Brand.ColorToken.hairline.opacity(0.5), lineWidth: 1)
                                                        )
                                                )
                                            }
                                            .buttonStyle(.plain)
                                            
                                            // Expanded content with lay explanation
                                            if expandedRelatedTopics.contains(topic) {
                                                if let relatedTopic = AppData.topics.first(where: { $0.topic == topic }) {
                                                    VStack(alignment: .leading, spacing: 12) {
                                                        Text(relatedTopic.layExplanation)
                                                            .font(.callout)
                                                            .foregroundColor(.primary.opacity(0.8))
                                                            .lineSpacing(3)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                            .padding(12)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                    .fill(.ultraThinMaterial)
                                                                    .overlay(
                                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                            .strokeBorder(Brand.ColorToken.hairline.opacity(0.3), lineWidth: 1)
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
                                                                    .font(.subheadline.weight(.medium))
                                                                Image(systemName: "arrow.right.circle.fill")
                                                                    .font(.subheadline)
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
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(Brand.ColorToken.hairline, lineWidth: 1)
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
                                                        .foregroundColor(Brand.ColorSystem.primary)
                                                    
                                                    Text(link)
                                                        .font(.callout)
                                                        .foregroundColor(Brand.ColorSystem.primary)
                                                        .underline()
                                                        .lineLimit(2)
                                                        .truncationMode(.middle)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                        } else {
                                            HStack(spacing: 8) {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                                
                                                Text(link)
                                                    .font(.callout)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                                    .truncationMode(.middle)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(Brand.ColorToken.hairline, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .tint(Brand.ColorSystem.primary)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
