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
    @State private var errorMessage: String? = nil        // User-visible alert text
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
                        VStack(alignment: .leading, spacing: 16) {

                            // STEP HEADER
                            BrandCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Step", systemImage: "list.bullet.rectangle")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)

                                    Text(step.step)
                                        .font(.headline)
                                        .foregroundColor(Color("BrandPrimary"))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityLabel(Text("Step: \(step.step)"))

                                    if let overview = step.overview,
                                       !overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(overview)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.top, 2)
                                    }
                                }
                            }

                            // TOPIC PICKER (only shown when >1 topic)
                            if topics.count > 1 {
                                BrandCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Select a Related Topic")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(Color("BrandSecondary"))

                                        // Small sets feel better segmented; larger sets use a menu.
                                        if topics.count <= 3 {
                                            Picker("Related Topic", selection: $selectionIndex) {
                                                ForEach(topics.indices, id: \.self) { idx in
                                                    Text(topics[idx].topic).tag(idx)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                            .accessibilityLabel(Text("Related Topic"))
                                        } else {
                                            Picker("Related Topic", selection: $selectionIndex) {
                                                ForEach(topics.indices, id: \.self) { idx in
                                                    Text(topics[idx].topic).tag(idx)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .labelsHidden()
                                            .accessibilityLabel(Text("Related Topic"))
                                        }
                                    }
                                }
                            }

                            // SELECTED TOPIC CONTENT
                            if let t = selectedTopic {
                                BrandCard {
                                    TopicDetailContent(topic: t)
                                }
                                .padding(.bottom, 8)
                            } else {
                                // Extremely rare: selection index out-of-range (e.g., dynamic update)
                                // Show a small, non-blocking hint instead of crashing.
                                if !topics.isEmpty {
                                    Text("Select a topic to view details.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 4)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(Color("BrandPrimary"))
                    .accessibilityLabel("Close")
                }
            }
        }
        .tint(Color("BrandPrimary"))

        // Keep selection index valid for current topics list at key moments.
        .onAppear(perform: clampSelection)
        .onChange(of: topics.count) { _, _ in clampSelection() }
        .onChange(of: selectionIndex) { _, _ in clampSelection() }

        // Friendly non-technical alert (placeholder; wire to any recoverable issues you surface)
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })
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
