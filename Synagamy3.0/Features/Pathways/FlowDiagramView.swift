//
//  FlowDiagramView.swift
//  Synagamy3.0
//
//  Renders a vertical “timeline” of ordered steps for a pathway. Each row is tappable;
//  tapping opens a sheet that lets the user pick/view related Education topics.
//  This refactor focuses on safety and App Store–readiness:
//   • Removes Identifiable conformance on PathwayStep (avoids duplicate-ID crashes).
//   • Uses stable indices for row identity and for the sheet selection (no force-unwraps).
//   • Handles empty/invalid input with friendly UI (EmptyStateView) instead of crashing.
//   • Adds accessibility labels and comments to clarify intent.
//
//  Prereqs:
//   • TopicSelectorSheet (shows step header + related topics).
//   • TopicMatcher (resolves topic_refs into EducationTopic objects).
//   • EmptyStateView / Brand styles already exist.
//
//  Notes:
//   • We intentionally *do not* make PathwayStep : Identifiable here because some “step”
//     strings can repeat across different pathways (e.g., “Luteal Support”), causing
//     duplicate IDs if the text were used as an ID. Using stable indices is safer.
//

import SwiftUI

struct FlowDiagramView: View {
    // MARK: - Inputs
    /// Ordered steps for a given pathway. May be empty (we guard for this).
    let steps: [PathwayStep]

    /// All education topics, used for resolving `topic_refs` via TopicMatcher.
    let educationTopics: [EducationTopic]

    // MARK: - UI state
    /// The index of the step currently selected (drives the detail sheet).
    @State private var selectedStepIndex: Int? = nil

    // MARK: - Body
    var body: some View {
        Group {
            if steps.isEmpty {
                // Friendly, branded empty state if a pathway has no steps.
                EmptyStateView(
                    icon: "map",
                    title: "No steps found",
                    message: "Check your Pathways.json or try another pathway."
                )
                .padding(.horizontal, 12)
                .padding(.top, 16)

            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        // Use indices as stable identity — avoids duplicate-ID issues.
                        ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                            StepRowCard(
                                title: step.step,
                                isFirst: idx == 0,
                                isLast: idx == steps.count - 1
                            ) {
                                // Always set selection via the index (never the value),
                                // so the sheet can safely dereference even with duplicates.
                                selectedStepIndex = idx
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text("\(step.step). Tap to view related topics."))
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.hidden)
            }
        }

        // MARK: - Step detail sheet (safe index-based selection)
        .sheet(isPresented: Binding(
            get: { selectedStepIndex != nil },
            set: { if !$0 { selectedStepIndex = nil } }
        )) {
            // Extra safety: validate index before dereferencing to avoid out-of-bounds.
            if let i = selectedStepIndex, steps.indices.contains(i) {
                let s = steps[i]

                // Build a topic index once per presentation (cheap) and resolve refs robustly.
                let index = TopicMatcher.index(topics: educationTopics)
                let matchedTopics = TopicMatcher.match(stepRefs: s.topic_refs, index: index)

                TopicSelectorSheet(step: s, topics: matchedTopics)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(.systemBackground))
                    // If desired, you could add .interactiveDismissDisabled(false)
                    // to prevent accidental dismissal while reading.
            } else {
                // In the extremely rare case the index is invalid (race/async), show a safe fallback.
                NavigationStack {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Step unavailable",
                        message: "Please try selecting the step again."
                    )
                    .padding()
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Step row card (the tappable item in the timeline list)

private struct StepRowCard: View {
    let title: String
    let isFirst: Bool
    let isLast: Bool

    /// Called when the row is tapped.
    var action: () -> Void
    
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Left-side vertical rail + node circle (timeline visual)
                TimelineRail(isFirst: isFirst, isLast: isLast)

                // Main text/content container with enhanced styling
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 4) {
                            Image(systemName: "text.book.closed.fill")
                                .font(.caption2)
                            Text("View related topics")
                                .font(.caption)
                        }
                        .foregroundColor(Brand.ColorSystem.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right.circle")
                        .font(.body)
                        .foregroundColor(Brand.ColorSystem.primary.opacity(0.6))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Brand.ColorToken.hairline, lineWidth: 1)
                        )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Timeline glyph (rail + node) used at the left of each step

private struct TimelineRail: View {
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Upper rail (hidden for first item)
            Rectangle()
                .fill(Brand.ColorSystem.primary.opacity(isFirst ? 0 : 0.3))
                .frame(width: 3)
                .frame(maxHeight: .infinity, alignment: .bottom)

            // Enhanced node with BrandPrimary
            ZStack {
                // Outer glow
                Circle()
                    .fill(Brand.ColorSystem.primary.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .blur(radius: 2)
                
                // Main circle
                Circle()
                    .fill(Brand.ColorSystem.primary)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
                
                // Inner dot
                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)
            }
            .padding(.vertical, 2)

            // Lower rail (hidden for last item)
            Rectangle()
                .fill(Brand.ColorSystem.primary.opacity(isLast ? 0 : 0.3))
                .frame(width: 3)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 22)
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }
}
