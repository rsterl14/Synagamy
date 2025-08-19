//
//  TopicListView.swift
//  Synagamy3.0
//
//  Topics → Detail flow.
//  • Shows a list of topics (usually passed in for a selected category).
//  • Local search (optional) within the provided topic set.
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

    /// Enable/disable search UI.
    var enableSearch: Bool? = nil

    // MARK: - Data & UI State

    @State private var working: [EducationTopic] = []      // list being displayed
    @State private var searchText: String = ""
    @State private var selected: EducationTopic? = nil     // drives detail sheet

    @State private var headerHeight: CGFloat = 64
    @State private var errorMessage: String? = nil

    // MARK: - Derived

    private var isSearchEnabled: Bool {
        if let enableSearch { return enableSearch }
        // Default: enable search only when showing all topics
        return topics == nil
    }

    private var filtered: [EducationTopic] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return working }
        return working.filter { t in
            t.topic.lowercased().contains(q)
            || t.category.lowercased().contains(q)
            || t.layExplanation.lowercased().contains(q)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Optional title (usually the category)
                    if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Color("BrandSecondary"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 2)
                            .accessibilityAddTraits(.isHeader)
                    }

                    if working.isEmpty && searchText.isEmpty {
                        EmptyStateView(
                            icon: "book",
                            title: "No topics available",
                            message: "Please check back later."
                        )
                        .padding(.top, 8)

                    } else if filtered.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No matches",
                            message: "Try a different keyword or clear your search."
                        )
                        .padding(.top, 8)

                    } else {
                        LazyVStack(spacing: 75) {
                            ForEach(filtered, id: \.id) { t in
                                Button { selected = t } label: {
                                    BrandTile(
                                        title: t.topic,            // first line
                                        subtitle: t.category,      // second line = category
                                        systemIcon: "book.fill",
                                        assetIcon: nil,
                                        isCompact: true
                                    )
                                    .vanishIntoPage(
                                        vanishDistance: 350,
                                        minScale: 0.88,
                                        maxBlur: 2.5,
                                        topInset: 0,
                                        blurKickIn: 14
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("\(t.topic). \(t.category). Tap to read."))
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }

        // MARK: - Nav & Toolbar

        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { HomeButton(usePopToRoot: true) } }

        // MARK: - Floating header

        .safeAreaInset(edge: .top) { Color.clear.frame(height: headerHeight) }
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "EducationLogo")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { headerHeight = geo.size.height }
                            .modifier(OnChangeHeightModifier(
                                currentHeight: $headerHeight,
                                height: geo.size.height
                            ))
                    }
                )
        }

        // MARK: - Search

        .modifier(SearchIfEnabled(isEnabled: isSearchEnabled, searchText: $searchText))

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

// MARK: - Conditional search wrapper

private struct SearchIfEnabled: ViewModifier {
    let isEnabled: Bool
    @Binding var searchText: String

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: Text("Search topics")
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        } else {
            content
        }
    }
}
