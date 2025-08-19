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
    @State private var headerHeight: CGFloat = 64           // reserved for floating header
    @State private var errorMessage: String? = nil          // user-friendly alert text

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if questions.isEmpty {
                    // Empty state explains what's happening rather than showing a blank screen.
                    EmptyStateView(
                        icon: "questionmark.circle",
                        title: "No questions yet",
                        message: "Please check back later or explore Education topics."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(questions, id: \.id) { q in
                            Button {
                                selected = q // safe state update to present the sheet
                            } label: {
                                BrandTile(
                                    title: q.question,
                                    subtitle: nil,
                                    systemIcon: "questionmark.circle.fill",
                                    assetIcon: nil
                                )
                                .scrollFadeScale()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .accessibilityLabel(Text("\(q.question). Tap to view the answer."))
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }
        // MARK: - Global nav style for this screen
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HomeButton()
            }
        }

        // Keep space for the floating header
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: headerHeight)
        }

        // Floating header with auto-measured height (shared modifier keeps it in sync)
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "CommonQuestionsLogo")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { headerHeight = geo.size.height }
                            .modifier(OnChangeHeightModifier(currentHeight: $headerHeight,
                                                             height: geo.size.height))
                    }
                )
        }

        // Friendly non-technical alert for recoverable issues
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Load data once. We guard against surprises and surface a friendly message on failure.
        .task {
            do {
                // If AppData.questions could ever throw, wrap here. It’s static now,
                // but we still defensively handle the “empty” case and unusual states.
                let loaded = AppData.questions
                if loaded.isEmpty {
                    // Not an error per se, but we can optionally inform the user elsewhere.
                    // We keep UI responsive with the empty-state card above.
                }
                questions = loaded
            } catch {
                // In case you switch to async/throwing loading in the future, this is ready.
                errorMessage = "We couldn’t load questions right now."
            }
        }

        // Q&A detail sheet
        .sheet(item: $selected) { q in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Question title
                        Text(q.question)
                            .font(.title2.bold())
                            .foregroundColor(Color("BrandPrimary"))

                        // Detailed answer body
                        Text(q.detailedAnswer)
                            .fixedSize(horizontal: false, vertical: true)

                        // Related topics (read-only list; could be upgraded to tappable later)
                        if !q.relatedTopics.isEmpty {
                            Divider().opacity(0.15)
                            Text("Related topics").font(.headline)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(q.relatedTopics, id: \.self) { topic in
                                    Text("• \(topic)")
                                }
                            }
                        }

                        // References (safe URL handling)
                        if !q.reference.isEmpty {
                            Divider().opacity(0.15)
                            Text("References").font(.headline)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(q.reference, id: \.self) { link in
                                    if let url = URL(string: link) {
                                        Link(link, destination: url)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                            .font(.footnote)
                                    } else {
                                        // If malformed, still show the text so users can copy it.
                                        Text(link).font(.footnote).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Answer")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
