//
//  HomeView.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  Landing page for the app. Shows the main navigation options
//  (Intro, Education, Pathways, Clinics, Resources, Questions, Community).
//
//  Improvements
//  ------------
//  • Uses consistent BrandTile styling.
//  • Clear accessibility labels.
//  • Safe NavigationLink destinations.
//  • Clean grid layout with spacing + padding.
//  • Floating logo header with reserved space.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Data model
    struct HomeItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemIcon: String
        let route: Route
    }

    enum Route: CaseIterable {
        case intro, education, pathways, clinics, outcome, resources, questions, community
    }

    // MARK: - Items
    private let items: [HomeItem] = [
        .init(title: "What is Infertility & Fertility Preservation",
              subtitle: "A Starting Point",
              systemIcon: "person.3.fill",
              route: .intro),
        .init(title: "Education",
              subtitle: "Learn",
              systemIcon: "book.fill",
              route: .education),
        .init(title: "Pathways",
              subtitle: "Explore Options",
              systemIcon: "map.fill",
              route: .pathways),
        .init(title: "Clinics",
              subtitle: "Find Clinics Near You",
              systemIcon: "building.2.fill",
              route: .clinics),
        .init(title: "Outcome Predictor",
              subtitle: "Managing Expectation for an Oocyte Retrevial",
              systemIcon: "building.2.fill",
              route: .clinics),
        .init(title: "Resources",
              subtitle: "Guides and Tools",
              systemIcon: "lightbulb.fill",
              route: .resources),
        .init(title: "Questions",
              subtitle: "Common Concerns",
              systemIcon: "questionmark.circle.fill",
              route: .questions),
        .init(title: "Community",
              subtitle: "Support",
              systemIcon: "person.2.wave.2.fill",
              route: .community)
    ]

    // MARK: - Layout
    @State private var headerHeight: CGFloat = 64

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 75) {
                        ForEach(items) { item in
                            NavigationLink(value: item.route) {
                                BrandTile(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    systemIcon: item.systemIcon,
                                    assetIcon: nil
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("\(item.title). \(item.subtitle). Tap to open."))
                            .padding(.horizontal, 16)
                            .vanishIntoPage(vanishDistance: 350,
                                            minScale: 0.88,
                                            maxBlur: 2.5,
                                            topInset: 0,
                                            blurKickIn: 14)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .scrollIndicators(.hidden)
            }

            // MARK: - Floating header
            .safeAreaInset(edge: .top) { Color.clear.frame(height: headerHeight) }
            .overlay(alignment: .top) {
                FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: nil)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { headerHeight = geo.size.height }
                                .modifier(OnChangeHeightModifier(currentHeight: $headerHeight,
                                                                 height: geo.size.height))
                        }
                    )
            }

            // MARK: - Navigation destinations
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .intro:
                    InfertilityView()
                case .education:
                    EducationView()
                case .pathways:
                    PathwayView()
                case .clinics:
                    ClinicFinderView()
                case .outcome:
                    OutcomePredictorView()
                case .resources:
                    ResourcesView()
                case .questions:
                    CommonQuestionsView()
                case .community:
                    CommunityView()
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview("HomeView Demo") {
    HomeView()
}
