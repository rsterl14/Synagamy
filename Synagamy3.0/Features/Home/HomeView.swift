//
//  HomeView.swift
//  Synagamy3.0
//
//  Home screen with navigation to all main app features.
//  Refactored to use new architecture components for better maintainability.
//

import SwiftUI

#if DEBUG
// Import debug view for development builds
#endif

struct HomeView: View {
    #if DEBUG
    @State private var showingDataDebug = false
    @State private var debugTapCount = 0
    #endif
    
    // MARK: - Route Definition
    enum Route: CaseIterable, Hashable {
        case intro, education, pathways, clinics, timedIntercourse, outcome, embryoTransfer, resources, questions, feedback
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
            title: "Embryo Transfer Predictor",
            subtitle: "Pre-Transfer Success Rates",
            systemIcon: "waveform.path.ecg",
            route: .embryoTransfer
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
            title: "Feedback",
            subtitle: "Share Your Thoughts & Suggestions",
            systemIcon: "heart.text.square.fill",
            route: .feedback
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
            // Set up navigation accessibility
            Color.clear
                .accessibilityElement()
                .accessibilityLabel("Synagamy Home")
                .accessibilityAddTraits(.isHeader)
                .frame(height: 0)
            ZStack {
                StandardPageLayout(
                    primaryImage: "SynagamyLogoTwo",
                    secondaryImage: nil,
                    showHomeButton: false,
                    usePopToRoot: false,
                    showBackButton: false
                ) {
                    // Announce screen change for VoiceOver users
                    Color.clear
                        .accessibilityHidden(true)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                AccessibilityAnnouncement.announce("Synagamy fertility app home screen loaded. \(navigationItems.count) navigation options available.")
                            }
                        }
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
                                .id(item.route) // Optimize SwiftUI diffing
                                .fertilityAccessibility(
                                    label: "\(item.title). \(item.subtitle)",
                                    hint: "Navigate to \(item.title.lowercased()) section",
                                    traits: [.isButton]
                                )
                            }
                        }
                        .padding(.top, 4)
                        
                        // Medical Disclaimer
                        medicalDisclaimerSection
                            .padding(.top, Brand.Spacing.xl)
                    }
                }
            }

            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onDynamicTypeChange { size in
            // Handle dynamic type changes for better accessibility
            #if DEBUG
            print("HomeView: Dynamic Type size changed to \(size)")
            #endif
        }
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
        case .embryoTransfer:
            EmbryoTransferPredictorView()
        case .resources:
            ResourcesView()
        case .questions:
            CommonQuestionsView()
        case .feedback:
            FeedbackView()
        }
    }

    // MARK: - Medical Disclaimer Section
    private var medicalDisclaimerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true) // Icon is decorative, text conveys the meaning

                Text("Important Medical Disclaimer")
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Important Medical Disclaimer")
            .accessibilityAddTraits(.isHeader)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("This application is designed exclusively for educational and informational purposes. The content provided, including fertility tracking tools, prediction models, and educational materials, should never be used as a substitute for professional medical advice, diagnosis, or treatment.")
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
                    .accessibilityAddTraits(.isStaticText)

                Text("Always consult with qualified healthcare professionals, including reproductive endocrinologists, fertility specialists, or your primary care physician, for personalized medical guidance regarding fertility, reproductive health, and treatment decisions.")
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.primary)
                    .multilineTextAlignment(.leading)
                    .accessibilityAddTraits(.isStaticText)

                Text("This app is not a medical device and has not been evaluated by Health Canada, the FDA, or other regulatory bodies.")
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
                    .accessibilityAddTraits(.isStaticText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Medical disclaimer")
            .accessibilityValue("This application is for educational purposes only and should not replace professional medical advice. Always consult qualified healthcare professionals for fertility and reproductive health guidance. This app is not a medical device.")
        }
        .padding(Brand.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("HomeView Demo") {
    HomeView()
}
