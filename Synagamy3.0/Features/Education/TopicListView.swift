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

    /// Provide the topic subset to show (suggested). If nil, will show all topics.
    var topics: [EducationTopic]? = nil


    // MARK: - Data & UI State

    @State private var working: [EducationTopic] = []      // list being displayed
    @State private var selected: EducationTopic? = nil     // drives detail sheet
    @State private var isLoading = false

    @State private var headerHeight: CGFloat = 64
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert = false
    
    @StateObject private var remoteDataService = RemoteDataService.shared


    // MARK: - Body

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                if isLoading {
                    LoadingStateView(
                        message: "Loading education topics...",
                        showProgress: true
                    )
                } else if working.isEmpty {
                    // Show network-aware empty state
                    if remoteDataService.lastError != nil {
                        ContentLoadingErrorView(
                            title: "Topics Unavailable",
                            message: "Unable to load education topics"
                        ) {
                            Task {
                                await loadTopics()
                            }
                        }
                    } else {
                        EmptyStateView(
                            icon: "book",
                            title: "No topics available",
                            message: "Please check back later."
                        )
                        .padding(.top, 8)
                    }

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

        .alert("Something went wrong", isPresented: $showingErrorAlert, actions: {
            Button("OK", role: .cancel) { 
                showingErrorAlert = false
                errorMessage = nil 
            }
        }, message: { Text(errorMessage ?? "Please try again.") })

        // MARK: - Load list

        .networkAware()
        .task {
            await loadTopics()
        }

        // MARK: - Detail sheet

        .sheet(item: $selected) { t in
            NavigationStack {
                ScrollView {
                    TopicDetailContent(topic: t, selectedTopic: $selected)
                        .padding()
                }
            }
            .tint(Brand.Color.primary)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTopics() async {
        isLoading = true
        defer { isLoading = false }

        // Try to load from remote service first
        let remoteTopics = await remoteDataService.loadEducationTopics()

        if !remoteTopics.isEmpty {
            // Use remote data if available
            let base = topics ?? remoteTopics
            working = base.sorted {
                $0.topic.localizedCaseInsensitiveCompare($1.topic) == .orderedAscending
            }
        } else {
            // Fall back to local data if remote fails
            let base = topics ?? AppData.topics
            working = base.sorted {
                $0.topic.localizedCaseInsensitiveCompare($1.topic) == .orderedAscending
            }
        }
    }
}

