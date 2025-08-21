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
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "PathwayLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if categories.isEmpty {
                    EmptyStateView(
                        icon: "map",
                        title: "No pathways available",
                        message: "Please check back later."
                    )
                    .padding(.top, 8)
                } else {
                    LazyVStack(spacing: Brand.Spacing.xl) {
                        ForEach(categories, id: \.id) { category in
                            NavigationLink {
                                PathListView(category: category, educationTopics: educationTopics)
                                    .toolbar(.hidden, for: .tabBar)
                            } label: {
                                BrandTile(
                                    title: category.title,
                                    subtitle: "Explore treatment options",
                                    systemIcon: iconForCategory(category.id),
                                    isCompact: true
                                )
                            }
                            .buttonStyle(BrandTileButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            }
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

    @State private var errorMessage: String? = nil

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "PathwayLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if category.paths.isEmpty {
                    // If no paths for this category, show a helpful empty state
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No pathways in this section",
                        message: "Try another section or return to Home."
                    )
                    .padding(.top, 8)
                } else {
                    LazyVStack(spacing: Brand.Spacing.xl) {
                        ForEach(category.paths) { path in
                            NavigationLink {
                                StepListView(path: path, educationTopics: educationTopics)
                            } label: {
                                BrandTile(
                                    title: path.title,
                                    subtitle: category.title,
                                    systemIcon: iconForPath(path.id),
                                    isCompact: true
                                )
                            }
                            .buttonStyle(BrandTileButtonStyle())
                            .accessibilityLabel(Text("\(path.title). Tap to view steps."))
                        }
                    }
                    .padding(.top, 4)
                }
            }
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

    @State private var errorMessage: String? = nil

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(spacing: 16) {
                // Enhanced title header matching TopicDetailContent style
                VStack(alignment: .leading, spacing: 8) {
                    // Category badge
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.caption2)
                        
                        Text("PATHWAY")
                            .font(.caption2.weight(.bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(Brand.ColorSystem.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Brand.ColorSystem.primary.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // Main title
                    Text(path.title.isEmpty ? "Steps" : path.title)
                        .font(.largeTitle.bold())
                        .foregroundColor(Brand.ColorSystem.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(Text(path.title.isEmpty ? "Steps" : path.title))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                
                // Divider
                Rectangle()
                    .fill(Brand.ColorSystem.primary.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                // Defensive check: if steps are missing or empty, show a clear message
                if path.steps.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No steps found",
                        message: "This pathway has no steps yet."
                    )
                    .padding(.top, 12)
                } else {
                    // Flow diagram renders each step with a tappable row;
                    // tapping opens a sheet with related topics pulled from Education_Topics.
                    FlowDiagramView(steps: path.steps, educationTopics: educationTopics)
                        .padding(.top, 8)
                }
            }
        }

        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })
    }
}
