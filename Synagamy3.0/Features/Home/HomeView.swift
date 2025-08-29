//
//  HomeView.swift
//  Synagamy3.0
//
//  Home screen with navigation to all main app features.
//  Refactored to use new architecture components for better maintainability.
//

import SwiftUI

struct HomeView: View {
    @State private var showingWalkthrough = false
    
    // MARK: - Route Definition
    enum Route: CaseIterable, Hashable {
        case intro, education, pathways, clinics, timedIntercourse, outcome, resources, questions
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
            ZStack {
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
                        
                        // Medical Disclaimer
                        medicalDisclaimerSection
                            .padding(.top, Brand.Spacing.xl)
                    }
                }
                
                // Floating Info Button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            showingWalkthrough = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.regularMaterial)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Brand.ColorSystem.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 16)
                        .padding(.top, 60) // Position it below the header
                    }
                    
                    Spacer()
                }
            }

            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if showingWalkthrough {
                AppWalkthroughView(isShowing: $showingWalkthrough)
            }
        }
    }
    
    // MARK: - Medical Disclaimer Section
    private var medicalDisclaimerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Important Medical Disclaimer")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("This application is designed for educational and informational purposes only. The content provided, including fertility tracking tools, prediction models, and educational materials, should not be used as a substitute for professional medical advice, diagnosis, or treatment.")
                    .font(.caption2)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.leading)
                
                Text("Always consult with qualified healthcare professionals, including reproductive endocrinologists or fertility specialists, for personalized medical guidance regarding fertility, reproductive health, and treatment decisions.")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Brand.ColorSystem.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
        }
    }
}

#Preview("HomeView Demo") {
    HomeView()
}
