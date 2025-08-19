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
                    LazyVStack(alignment: .leading, spacing: 0) {
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
                    .padding(.horizontal, 0)
                    .padding(.vertical, 6) // tighter outer vertical padding (requested earlier)
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

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 8) {
                // Left-side vertical rail + node circle (timeline visual)
                TimelineRail(isFirst: isFirst, isLast: isLast)

                // Main text/content container
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Image(systemName: "book")
                        Text("Tap to view related topics")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    // Subtle card stroke to fit the brand style
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color("BrandPrimary").opacity(0.08), lineWidth: 1)
                )
            }
            .contentShape(Rectangle()) // ensures full-row hit target
            .padding(.vertical, 4)     // compact inter-row spacing
        }
        .buttonStyle(.plain)
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
                .fill(Color.secondary.opacity(isFirst ? 0 : 0.22))
                .frame(width: 2)
                .frame(maxHeight: .infinity, alignment: .bottom)

            // Node (white inner, branded ring, filled dot)
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 16, height: 16)
                Circle()
                    .stroke(Color("BrandSecondary"), lineWidth: 2)
                    .frame(width: 16, height: 16)
                Circle()
                    .fill(Color("BrandSecondary"))
                    .frame(width: 5, height: 5)
            }
            .padding(.vertical, 1)

            // Lower rail (hidden for last item)
            Rectangle()
                .fill(Color.secondary.opacity(isLast ? 0 : 0.22))
                .frame(width: 2)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 18)        // slimmer gutter
        .padding(.vertical, 4)   // compact vertical padding around node
        .accessibilityHidden(true)
    }
}
