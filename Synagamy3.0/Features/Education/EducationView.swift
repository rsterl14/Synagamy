//
//  EducationView.swift
//  Synagamy3.0
//
//  Categories → Topics flow.
//  • Lists unique categories as BrandTiles (with topic counts).
//  • Tapping a category navigates to TopicListView scoped to that category.
//  • Keeps floating header, vanish effect, and empty/error states.
//
//  Expects:
//  - AppData.topics : [EducationTopic]
//  - BrandTile, EmptyStateView, HomeButton, FloatingLogoHeader
//  - OnChangeHeightModifier, .vanishIntoPage
//

import SwiftUI

struct EducationView: View {
    // MARK: - Data
    @State private var allTopics: [EducationTopic] = []   // loaded in .task

    // MARK: - UI State
    @State private var headerHeight: CGFloat = 64
    @State private var errorMessage: String? = nil

    // MARK: - Derived: categories + lookup
    private var categories: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: allTopics, by: { $0.category })
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { a, b in
                a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
    }

    private var topicsByCategory: [String: [EducationTopic]] {
        Dictionary(grouping: allTopics, by: { $0.category })
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if allTopics.isEmpty {
                    EmptyStateView(
                        icon: "book",
                        title: "No topics available",
                        message: "Please check back later. You can still explore Pathways."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 75) {
                        ForEach(categories, id: \.name) { cat in
                            // Push into TopicListView scoped to this category
                            NavigationLink {
                                TopicListView(
                                    title: cat.name,
                                    topics: topicsByCategory[cat.name] ?? [],
                                    enableSearch: true
                                )
                            } label: {
                                BrandTile(
                                    title: cat.name,
                                    subtitle: "\(cat.count) topic\(cat.count == 1 ? "" : "s")",
                                    systemIcon: "square.grid.2x2.fill",
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
                            .padding(.horizontal, 16)
                            .accessibilityLabel(Text("\(cat.name). \(cat.count) topics. Tap to view."))
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HomeButton(usePopToRoot: true)
            }
        }

        // MARK: - Floating header space reservation
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
    }
}
