//
//  TopicListView.swift
//  Synagamy3.0
//
//  Compact list of Education topics (optionally filtered by a caller-provided subset).
//  Tapping a row opens the full details in a sheet.
//
//  Fixes in this version:
//   • Uses `topic.category` as the secondary line (model has no `subtitle`).
//   • Safe, App Store–friendly patterns: empty/error states, no force-unwraps.
//   • Keeps optional local search and the shared floating-header spacing.
//
import SwiftUI

struct TopicListView: View {
    // MARK: - Inputs

    /// Optional headline shown above the list (e.g., “Stimulation & Monitoring”).
    var title: String?

    /// Provide your own topic subset, or leave nil to use all topics.
    var topics: [EducationTopic]? = nil

    /// If provided, the local search bar appears. Default: true when using “all topics”.
    var enableSearch: Bool? = nil

    // MARK: - Data & UI State

    @State private var all: [EducationTopic] = []               // working set
    @State private var searchText: String = ""
    @State private var selected: EducationTopic? = nil          // drives detail sheet

    @State private var headerHeight: CGFloat = 64               // space for floating header
    @State private var errorMessage: String? = nil              // non-technical user alert

    // MARK: - Derived

    private var isSearchEnabled: Bool {
        if let enableSearch { return enableSearch }
        // Enable search by default when caller did not pass a custom subset.
        return topics == nil
    }

    private var filtered: [EducationTopic] {
        let base = all
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter { t in
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

                    // Optional section title
                    if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Color("BrandSecondary"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 2)
                            .accessibilityAddTraits(.isHeader)
                    }

                    // Empty / No matches states
                    if all.isEmpty && searchText.isEmpty {
                        EmptyStateView(
                            icon: "book",
                            title: "No topics available",
                            message: "Please check back later. You can still explore Pathways."
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
                        // List of compact tiles
                        LazyVStack(spacing: 10) {
                            ForEach(filtered, id: \.id) { t in
                                Button { selected = t } label: {
                                    BrandTile(
                                        title: t.topic,
                                        subtitle: t.category,          // ← show category
                                        systemIcon: "book.fill",
                                        assetIcon: nil,
                                        isCompact: true
                                    )
                                    .scrollFadeScale()
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

        // Reserve space for the floating header
        .safeAreaInset(edge: .top) { Color.clear.frame(height: headerHeight) }

        // Floating brand header (Education by default)
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "EducationLogo")
                .cloudyFloating()
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

        .modifier(SearchIfEnabled(isEnabled: isSearchEnabled, searchText: $searchText))

        // MARK: - Alert

        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: { Text(errorMessage ?? "Please try again.") })

        // MARK: - Load data

        .task {
            // Use caller-provided topics or fall back to all cached topics
            let base = topics ?? AppData.topics
            all = base.sorted {
                $0.topic.localizedCaseInsensitiveCompare($1.topic) == .orderedAscending
            }
        }

        // MARK: - Detail Sheet

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

// MARK: - Helper modifier to conditionally attach .searchable without branching body

private struct SearchIfEnabled: ViewModifier {
    let isEnabled: Bool
    @Binding var searchText: String

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: Text("Search topics"))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        } else {
            content
        }
    }
}
