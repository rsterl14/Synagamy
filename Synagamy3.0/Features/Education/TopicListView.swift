//
//  TopicListView.swift
//  Synagamy3.0
//
//  Topics → Detail flow.
//  • Shows a list of topics (usually passed in for a selected category).
//  • Tapping a topic opens TopicDetailContent in a sheet.
//
//  Expects:
//  - BrandTile, EmptyStateView, HomeButton, FloatingLogoHeader
//  - OnChangeHeightModifier, .vanishIntoPage
//

import SwiftUI

struct TopicListView: View {
    // MARK: - Inputs

    /// Optional headline shown above the list (e.g., the category name).
    var title: String? = nil

    /// Provide the topic subset to show (recommended). If nil, will show all topics.
    var topics: [EducationTopic]? = nil


    // MARK: - Data & UI State

    @State private var working: [EducationTopic] = []      // list being displayed
    @State private var selected: EducationTopic? = nil     // drives detail sheet

    @State private var headerHeight: CGFloat = 64
    @State private var errorMessage: String? = nil


    // MARK: - Body

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if working.isEmpty {
                    EmptyStateView(
                        icon: "book",
                        title: "No topics available",
                        message: "Please check back later."
                    )
                    .padding(.top, 8)

                } else {
                    LazyVStack(spacing: Brand.Spacing.xl) {
                        ForEach(working, id: \.id) { t in
                            Button { selected = t } label: {
                                BrandTile(
                                    title: t.topic,            // first line
                                    subtitle: t.category,      // second line = category
                                    systemIcon: "book.fill",
                                    isCompact: true
                                )
                            }
                            .buttonStyle(BrandTileButtonStyle())
                            .accessibilityLabel(Text("\(t.topic). \(t.category). Tap to read."))
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }

        // MARK: - Alerts

        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: { Text(errorMessage ?? "Please try again.") })

        // MARK: - Load list

        .task {
            // Use provided subset or all topics
            let base = topics ?? AppData.topics
            working = base.sorted {
                $0.topic.localizedCaseInsensitiveCompare($1.topic) == .orderedAscending
            }
        }

        // MARK: - Detail sheet

        .sheet(item: $selected) { t in
            NavigationStack {
                ScrollView {
                    TopicDetailContent(topic: t)
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

