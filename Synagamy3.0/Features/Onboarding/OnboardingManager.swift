//
//  OnboardingManager.swift
//  Synagamy3.0
//
//  Manages the onboarding flow and user preferences.
//

import SwiftUI

class OnboardingManager: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    @AppStorage("onboardingVersion") private var onboardingVersion = 0
    
    private let currentOnboardingVersion = 1
    
    // MARK: - Published Properties
    
    @Published var shouldShowOnboarding: Bool = false
    @Published var shouldShowDisclaimer: Bool = false
    @Published var currentStep: OnboardingStep = .welcome
    
    // MARK: - Onboarding Steps
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case features = 1
        case disclaimer = 2
        case permissions = 3
        case complete = 4
        
        var title: String {
            switch self {
            case .welcome:
                return "Welcome to Synagamy"
            case .features:
                return "Powerful Fertility Tools"
            case .disclaimer:
                return "Important Information"
            case .permissions:
                return "Privacy & Permissions"
            case .complete:
                return "You're All Set!"
            }
        }
        
        var subtitle: String {
            switch self {
            case .welcome:
                return "Your Comprehensive Fertility Education Companion"
            case .features:
                return "Explore Evidence-based Fertility Tools and Education"
            case .disclaimer:
                return "Understanding the Educational Purpose of This App"
            case .permissions:
                return "Your Data Stays Private and Secure"
            case .complete:
                return "Start Exploring Your Fertility Journey"
            }
        }
        
        var systemImage: String {
            switch self {
            case .welcome:
                return "heart.circle.fill"
            case .features:
                return "star.circle.fill"
            case .disclaimer:
                return "info.circle.fill"
            case .permissions:
                return "lock.shield.fill"
            case .complete:
                return "checkmark.circle.fill"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        checkOnboardingStatus()
    }
    
    // MARK: - Public Methods
    
    func checkOnboardingStatus() {
        shouldShowOnboarding = !hasCompletedOnboarding || onboardingVersion < currentOnboardingVersion
        shouldShowDisclaimer = !hasAcceptedDisclaimer
    }
    
    func nextStep() {
        guard currentStep.rawValue < OnboardingStep.allCases.count - 1 else {
            completeOnboarding()
            return
        }
        
        withAnimation(.spring()) {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .complete
        }
    }
    
    func previousStep() {
        guard currentStep.rawValue > 0 else { return }
        
        withAnimation(.spring()) {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        onboardingVersion = currentOnboardingVersion
        
        withAnimation(.spring()) {
            shouldShowOnboarding = false
        }
    }
    
    func acceptDisclaimer() {
        hasAcceptedDisclaimer = true
        shouldShowDisclaimer = false
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasAcceptedDisclaimer = false
        onboardingVersion = 0
        currentStep = .welcome
        checkOnboardingStatus()
    }
    
    // MARK: - Computed Properties
    
    var isFirstStep: Bool {
        currentStep == .welcome
    }
    
    var isLastStep: Bool {
        currentStep == .complete
    }
    
    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
    
    var nextButtonTitle: String {
        switch currentStep {
        case .disclaimer:
            return "Accept & Continue"
        case .complete:
            return "Start Using Synagamy"
        default:
            return "Continue"
        }
    }
}

// MARK: - Onboarding Feature Data

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    
    static let features: [OnboardingFeature] = [
        OnboardingFeature(
            title: "IVF Outcome Predictor",
            description: "Get personalized predictions based on population data",
            systemImage: "chart.bar.fill",
            color: .blue
        ),
        OnboardingFeature(
            title: "Timed Intercourse Tracker",
            description: "Optimize conception timing with fertility window tracking",
            systemImage: "heart.circle.fill",
            color: .pink
        ),
        OnboardingFeature(
            title: "Educational Resources",
            description: "Evidence-based fertility education backed by scentific research",
            systemImage: "book.fill",
            color: .green
        ),
        OnboardingFeature(
            title: "Treatment Pathways",
            description: "Personalized learning paths based on your situation",
            systemImage: "map.fill",
            color: .orange
        ),
        OnboardingFeature(
            title: "Clinical Resources",
            description: "Find fertility clinics and access professional resources",
            systemImage: "building.2.fill",
            color: .purple
        )
    ]
}
