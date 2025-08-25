//
//  HomeView.swift
//  Synagamy3.0
//
//  Home screen with navigation to all main app features.
//  Refactored to use new architecture components for better maintainability.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Route Definition
    enum Route: CaseIterable, Hashable {
        case intro, education, pathways, clinics, timedIntercourse, outcome, resources, questions, community
    }

    // MARK: - Navigation Items
    private let navigationItems: [HomeItem] = [
        HomeItem(
            title: "A Starting Point",
            subtitle: "Understanding Infertility & Fertility Preservation",
            systemIcon: "person.3.fill",
            route: .intro
        ),
        HomeItem(
            title: "Education",
            subtitle: "Learn About Reproduction",
            systemIcon: "book.fill",
            route: .education
        ),
        HomeItem(
            title: "Pathway Explorer",
            subtitle: "Treatment & Preservation Pathways",
            systemIcon: "map.fill",
            route: .pathways
        ),
        HomeItem(
            title: "Timed Intercourse",
            subtitle: "Optimize Timing for Conception",
            systemIcon: "heart.circle.fill",
            route: .timedIntercourse
        ),
        HomeItem(
            title: "Outcome Predictor",
            subtitle: "Managing Expectation in IVF",
            systemIcon: "chart.line.uptrend.xyaxis",
            route: .outcome
        ),
        HomeItem(
            title: "Clinics",
            subtitle: "Find Fertility Clinics Near You",
            systemIcon: "building.2.fill",
            route: .clinics
        ),
        HomeItem(
            title: "Resources",
            subtitle: "Helpful Resources & Information",
            systemIcon: "lightbulb.fill",
            route: .resources
        ),
        HomeItem(
            title: "Questions",
            subtitle: "Frequently Asked Questions",
            systemIcon: "questionmark.circle.fill",
            route: .questions
        ),
        HomeItem(
            title: "Community",
            subtitle: "You are Not Alone",
            systemIcon: "person.2.wave.2.fill",
            route: .community
        )
    ]
    
    struct HomeItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemIcon: String
        let route: Route
    }

    var body: some View {
        NavigationStack {
            StandardPageLayout(
                primaryImage: "SynagamyLogoTwo",
                secondaryImage: nil,
                showHomeButton: false,
                usePopToRoot: false,
                showBackButton: false
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVStack(spacing: Brand.Spacing.xl) {
                        ForEach(navigationItems, id: \.id) { item in
                            NavigationLink(value: item.route) {
                                BrandTile(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    systemIcon: item.systemIcon,
                                    isCompact: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
            }

            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    // MARK: - Navigation Destinations
    
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .intro:
            InfertilityView()
        case .education:
            EducationView()
        case .pathways:
            PathwayView()
        case .clinics:
            ClinicFinderView()
        case .timedIntercourse:
            TimedIntercourseView()
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

#Preview("HomeView Demo") {
    HomeView()
}
