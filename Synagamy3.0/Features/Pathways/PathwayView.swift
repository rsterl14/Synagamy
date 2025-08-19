//
//  PathwayView.swift
//  Synagamy3.0
//
//  Presents pathway categories (e.g., Infertility Treatment, Fertility Preservation),
//  drills into a list of specific pathways, and then shows each pathway’s steps in a
//  vertical flow diagram. This refactor:
//   • Uses the shared OnChangeHeightModifier (no local duplicates).
//   • Adds safe, App Store–friendly error and empty-state handling at each level.
//   • Avoids force-unwraps and fragile assumptions.
//   • Keeps comments to clarify intent.
//
//  Prereqs:
//   • OnChangeHeightModifier in UI/Modifiers/OnChangeHeightModifier.swift
//   • BrandTile / BrandCard / FloatingLogoHeader / EmptyStateView / FlowDiagramView exist
//   • AppData.pathways and AppData.topics are available
//

import SwiftUI

// MARK: - Top-level category picker (e.g., Infertility Treatment / Fertility Preservation)

struct PathwayView: View {
    // MARK: - Data sources
    private let categories = AppData.pathways           // [PathwayCategory]
    private let educationTopics = AppData.topics        // [EducationTopic] for step sheets

    // MARK: - UI state
    @State private var headerHeight: CGFloat = 64       // reserved space for floating header
    @State private var errorMessage: String? = nil      // user-friendly error presentation

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // If *no* categories are available, show a helpful empty state up front.
                if categories.isEmpty {
                    EmptyStateView(
                        icon: "map",
                        title: "No pathways available",
                        message: "Please check back later or explore Education topics."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 75) {
                        ForEach(categories) { category in
                            NavigationLink {
                                PathListView(category: category, educationTopics: educationTopics)
                                    .toolbar(.hidden, for: .tabBar) // hide tab bar on push
                            } label: {
                                BrandTile(
                                    title: category.title,
                                    subtitle: nil,
                                    systemIcon: iconForCategory(category.id),
                                    assetIcon: nil
                                )
                            }
                            .buttonStyle(.plain)
                            .vanishIntoPage(vanishDistance: 350,
                                            minScale: 0.88,
                                            maxBlur: 2.5,
                                            topInset: 0,
                                            blurKickIn: 14)
                            .accessibilityLabel(Text("\(category.title). Tap to view pathways."))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { HomeButton() }
        }

        // Reserve space equal to the floating header height
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: headerHeight)
        }

        // Floating header + dynamic height sync (rotation, dynamic type, etc.)
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "PathwayLogo")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { headerHeight = geo.size.height }
                            .modifier(OnChangeHeightModifier(currentHeight: $headerHeight,
                                                             height: geo.size.height))
                    }
                )
        }

        // Friendly, non-technical alert for recoverable errors
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })
    }

    // MARK: - Icon mapping for categories
    private func iconForCategory(_ id: String) -> String {
        switch id {
        case "infertility_treatment": return "stethoscope"
        case "fertility_preservation": return "snowflake"
        default: return "square.grid.2x2"
        }
    }
}

// MARK: - Path list for a selected category (e.g., IUI, IVF, Donor Oocytes…)

struct PathListView: View {
    let category: PathwayCategory              // Selected category container
    let educationTopics: [EducationTopic]     // Passed down for step-detail sheets

    @State private var headerHeight: CGFloat = 64
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    // Category title (safe for empty or long text)
                    Text(category.title.isEmpty ? "Pathways" : category.title)
                        .font(.title2.bold())
                        .foregroundColor(Color("BrandSecondary"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        .accessibilityLabel(Text(category.title.isEmpty ? "Pathways" : category.title))

                    if category.paths.isEmpty {
                        // If no paths for this category, show a helpful empty state
                        EmptyStateView(
                            icon: "square.grid.2x2",
                            title: "No pathways in this section",
                            message: "Try another section or return to Home."
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    } else {
                        LazyVStack(spacing: 75) {
                            ForEach(category.paths) { path in
                                NavigationLink {
                                    StepListView(path: path, educationTopics: educationTopics)
                                } label: {
                                    BrandTile(
                                        title: path.title,
                                        subtitle: nil,
                                        systemIcon: iconForPath(path.id),
                                        assetIcon: nil
                                    )
                                }
                                .buttonStyle(.plain)
                                .vanishIntoPage(vanishDistance: 350,
                                                minScale: 0.88,
                                                maxBlur: 2.5,
                                                topInset: 0,
                                                blurKickIn: 14)
                                .accessibilityLabel(Text("\(path.title). Tap to view steps."))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { HomeButton() }
        }

        .safeAreaInset(edge: .top) { Color.clear.frame(height: headerHeight) }

        .overlay(alignment: .top) {
            // You can use either the Pathway or Education logo here. Using Education
            // pairs nicely with the detailed context users are about to see.
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

        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })
    }

    // MARK: - Icon mapping for individual paths
    private func iconForPath(_ id: String) -> String {
        switch id {
        // Infertility treatment
        case "iui_partner": return "person.2"
        case "iui_donor_sperm": return "drop.fill"
        case "personal_gametes_ivf": return "testtube.2"
        case "donor_sperm_ivf": return "person.3.sequence"
        case "donor_oocytes": return "circle.dashed"
        case "double_donation": return "square.stack.3d.up"
        case "reciprocal_ivf": return "arrow.2.squarepath"
        case "gestational_carrier": return "figure.pregnant"
        case "genetic_indications": return "dna"

        // Fertility preservation
        case "male_preservation": return "shield"
        case "female_oocyte_freezing", "female_embryo_freezing",
             "ovarian_tissue_freezing": return "snowflake"
        case "prepubertal_preservation": return "figure.child"
        case "oncofertility_fast_track", "oncofertility_fasttrack": return "bolt.heart"

        default: return "square.grid.2x2"
        }
    }
}

// MARK: - Step list for a selected path (renders the flow diagram + topic sheets)

struct StepListView: View {
    let path: PathwayPath                      // Concrete path containing ordered steps
    let educationTopics: [EducationTopic]      // Supplied to FlowDiagramView for matching

    @State private var headerHeight: CGFloat = 64
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    Text(path.title.isEmpty ? "Steps" : path.title)
                        .font(.title2.bold())
                        .foregroundColor(Color("BrandSecondary"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        .accessibilityLabel(Text(path.title.isEmpty ? "Steps" : path.title))

                    // Defensive check: if steps are missing or empty, show a clear message
                    if path.steps.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: "No steps found",
                            message: "This pathway has no steps yet."
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    } else {
                        // Flow diagram renders each step with a tappable row;
                        // tapping opens a sheet with related topics pulled from Education_Topics.
                        FlowDiagramView(steps: path.steps, educationTopics: educationTopics)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { HomeButton() }
        }

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

        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })
    }
}
