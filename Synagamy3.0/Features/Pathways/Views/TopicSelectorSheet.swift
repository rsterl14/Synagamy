//
//  TopicSelectorSheet.swift
//  Synagamy3.0
//
//  Bottom sheet that appears after tapping a pathway step.
//  Shows the step header (with optional overview), a topic selector (if >1 match),
//  and the selected topic’s details.
//
//  This refactor:
//   • Adds stronger bounds checks around selection index.
//   • Handles empty topic lists with a friendly empty state.
//   • Uses defensive state updates (no force-unwraps).
//   • Improves accessibility and keeps UI consistent with the design system.
//
//  Prereqs:
//   • UI/Components: BrandCard, EmptyStateView
//   • UI/Components: TopicDetailContent (renders EducationTopic details)
//

import SwiftUI

struct TopicSelectorSheet: View {
    // MARK: - Inputs
    let step: PathwayStep                 // The step the user tapped
    let topics: [EducationTopic]          // Matched topics for this step (may be empty)

    // MARK: - UI State
    @State private var selectionIndex: Int = 0            // Which topic is selected in the picker
    // REMOVED: @State private var errorMessage: String? = nil        // User-visible alert text
    // REMOVED: @State private var showingErrorAlert = false          // Controls error alert presentation
    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived
    /// Safely retrieves the current topic based on `selectionIndex`.
    private var selectedTopic: EducationTopic? {
        guard topics.indices.contains(selectionIndex) else { return nil }
        return topics[selectionIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if topics.isEmpty {
                    // No topic matches for this step — give a friendly explanation.
                    EmptyStateView(
                        icon: "book",
                        title: "No linked topics",
                        message: "This step has no matching topics in Education."
                    )
                    .padding(.horizontal)
                    .padding(.top, 24)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {

                            // STEP HEADER matching TopicDetailContent style
                            VStack(alignment: .leading, spacing: 12) {
                                // Category badge
                                HStack {
                                    Image(systemName: "list.bullet.clipboard")
                                        .font(.caption2)
                                    
                                    Text("STEP INFORMATION")
                                        .font(.caption2.weight(.bold))
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
                                
                                // Step title
                                Text(step.step)
                                    .font(.largeTitle.bold())
                                    .foregroundColor(Brand.Color.primary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityLabel(Text("Step: \(step.step)"))
                            }
                            .padding(.bottom, 4)
                            
                            // Divider
                            Rectangle()
                                .fill(Brand.Color.primary.opacity(0.2))
                                .frame(height: 1)
                                .padding(.bottom, 4)
                            
                            // Step overview if available
                            if let overview = step.overview,
                               !overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.body)
                                            .foregroundColor(Brand.Color.primary)
                                        
                                        Text("Overview")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Brand.Color.primary)
                                    }
                                    
                                    Text(overview)
                                        .font(Brand.Typography.bodySmall)
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
                                                        .strokeBorder(Brand.Color.hairline, lineWidth: 1)
                                                )
                                        )
                                }
                            }

                            // COMPACT TOPIC SELECTION
                            if !topics.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "text.book.closed.fill")
                                            .font(.body)
                                            .foregroundColor(Brand.Color.primary)
                                        
                                        Text(topics.count > 1 ? "Related Topics (\(topics.count))" : "Related Topic")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Brand.Color.primary)
                                    }
                                    
                                    VStack(spacing: 8) {
                                        ForEach(topics.indices, id: \.self) { idx in
                                            Button {
                                                selectionIndex = idx
                                            } label: {
                                                HStack(spacing: 12) {
                                                    // Selection indicator
                                                    Circle()
                                                        .fill(selectionIndex == idx ? Brand.Color.primary : Brand.Color.primary.opacity(0.2))
                                                        .frame(width: 20, height: 20)
                                                        .overlay(
                                                            Image(systemName: "checkmark")
                                                                .font(.system(size: 10, weight: .bold))
                                                                .foregroundColor(.white)
                                                                .opacity(selectionIndex == idx ? 1 : 0)
                                                        )
                                                    
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(topics[idx].topic)
                                                            .font(.body.weight(.medium))
                                                            .foregroundColor(.primary)
                                                            .multilineTextAlignment(.leading)
                                                        
                                                        Text(topics[idx].category)
                                                            .font(.caption)
                                                            .foregroundColor(Brand.Color.secondary)
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(selectionIndex == idx ? Brand.Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                                .strokeBorder(
                                                                    selectionIndex == idx ? Brand.Color.primary.opacity(0.3) : Brand.Color.hairline.opacity(0.5),
                                                                    lineWidth: 1
                                                                )
                                                        )
                                                )
                                            }
                                            .buttonStyle(.plain)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectionIndex)
                                        }
                                    }
                                }
                            }

                            // COMPACT TOPIC PREVIEW
                            if let t = selectedTopic {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.body)
                                            .foregroundColor(Brand.Color.primary)
                                        
                                        Text("Quick Preview")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Brand.Color.primary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Topic title and category
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(t.topic)
                                                .font(.title3.bold())
                                                .foregroundColor(Brand.Color.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "folder.fill")
                                                    .font(.caption2)
                                                Text(t.category)
                                                    .font(.caption)
                                            }
                                            .foregroundColor(Brand.Color.secondary)
                                        }
                                        
                                        // Lay explanation preview
                                        if !t.layExplanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            Text(t.layExplanation)
                                                .font(Brand.Typography.bodySmall)
                                                .foregroundColor(.primary.opacity(0.9))
                                                .lineSpacing(3)
                                                .lineLimit(4)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(.ultraThinMaterial)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                                .strokeBorder(Brand.Color.hairline.opacity(0.5), lineWidth: 1)
                                                        )
                                                )
                                        }
                                        
                                        // View full details button
                                        NavigationLink {
                                            ScrollView {
                                                TopicDetailContent(topic: t)
                                                    .padding()
                                            }
                                            .navigationBarTitleDisplayMode(.inline)
                                        } label: {
                                            HStack(spacing: 8) {
                                                Text("View Full Details")
                                                    .font(.subheadline.weight(.medium))
                                                Image(systemName: "arrow.right.circle.fill")
                                                    .font(.subheadline)
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(Brand.Color.primary)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(Brand.Color.hairline, lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            // NAV
        }
        .tint(Brand.Color.primary)

        // Keep selection index valid for current topics list at key moments.
        .onAppear(perform: clampSelection)
        .onChange(of: topics.count) { _, _ in clampSelection() }
        .onChange(of: selectionIndex) { _, _ in clampSelection() }

        // Unified error handling for any issues with topic loading or navigation
        .unifiedErrorHandling(
            viewContext: "TopicSelectorSheet",
            onRetry: { /* No specific retry action for this view */ }
        )
    }

    // MARK: - Helpers
    /// Ensures `selectionIndex` is always within `topics.indices` or 0 when possible.
    private func clampSelection() {
        guard !topics.isEmpty else {
            selectionIndex = 0
            return
        }
        if !topics.indices.contains(selectionIndex) {
            selectionIndex = topics.indices.first ?? 0
        }
    }
}
