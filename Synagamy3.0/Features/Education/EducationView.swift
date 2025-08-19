//
//  EducationView.swift
//  Synagamy3.0
//
//  Browse all education topics (with local search). Tapping a row opens a detail sheet.
//  Matches the EducationTopic model (topic, category, layExplanation, expertSummary, reference, relatedTo).
//

import SwiftUI

struct EducationView: View {
    // MARK: - Data
    @State private var allTopics: [EducationTopic] = []       // loaded in .task
    @State private var searchText: String = ""                 // .searchable binding

    // MARK: - UI State
    @State private var headerHeight: CGFloat = 64              // reserved for floating header
    @State private var selectedTopic: EducationTopic? = nil    // drives detail sheet
    @State private var errorMessage: String? = nil             // user-facing alert text

    // MARK: - Derived filter (fast local search)
    private var filteredTopics: [EducationTopic] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allTopics }
        return allTopics.filter { t in
            t.topic.lowercased().contains(q)
            || t.category.lowercased().contains(q)
            || t.layExplanation.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if allTopics.isEmpty && searchText.isEmpty {
                    EmptyStateView(
                        icon: "book",
                        title: "No topics available",
                        message: "Please check back later. You can still explore Pathways."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                } else if filteredTopics.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "Try a different keyword or clear your search."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTopics, id: \.id) { topic in
                            Button { selectedTopic = topic } label: {
                                BrandTile(
                                    title: topic.topic,
                                    subtitle: topic.category,        // model has no subtitle; show category
                                    systemIcon: "book.fill",
                                    assetIcon: nil
                                )
                                .scrollFadeScale()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .accessibilityLabel(Text("\(topic.topic). \(topic.category). Tap to read."))
                        }
                    }
                    .padding(.vertical, 14)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }

        // MARK: - Nav & Toolbar
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HomeButton(usePopToRoot: true) } }

        // MARK: - Floating header space reservation
        .safeAreaInset(edge: .top) { Color.clear.frame(height: headerHeight) }
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "EducationLogo")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { headerHeight = geo.size.height }
                            .modifier(OnChangeHeightModifier(currentHeight: $headerHeight,
                                                             height: geo.size.height))
                    }
                )
        }

        // MARK: - Search
        .searchable(text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: Text("Search topics"))
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)

        // MARK: - Alerts
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: { Text(errorMessage ?? "Please try again.") })

        // MARK: - Load data once
        .task {
            let topics = AppData.topics.sorted {
                $0.topic.localizedCaseInsensitiveCompare($1.topic) == .orderedAscending
            }
            allTopics = topics
        }

        // MARK: - Detail Sheet
        .sheet(item: $selectedTopic) { t in
            NavigationStack {
                ScrollView {
                    TopicDetailContent(topic: t)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                .navigationTitle(t.topic)
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
