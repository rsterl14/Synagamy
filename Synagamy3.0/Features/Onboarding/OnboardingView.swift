//
//  OnboardingView.swift
//  Synagamy3.0
//
//  Comprehensive onboarding flow for first-time users.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    var body: some View {
        ZStack {
            // Solid background to block app content
            Color.white
                .ignoresSafeArea()
            
            // Background gradient overlay
            LinearGradient(
                colors: [
                    Brand.ColorSystem.primary.opacity(0.1),
                    Brand.ColorSystem.secondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                progressBar
                
                // Content
                if onboardingManager.currentStep == .disclaimer {
                    // Show disclaimer without TabView to prevent swiping
                    stepContent(for: .disclaimer)
                } else {
                    // Normal TabView for other steps
                    TabView(selection: $onboardingManager.currentStep) {
                        ForEach(OnboardingManager.OnboardingStep.allCases, id: \.self) { step in
                            stepContent(for: step)
                                .tag(step)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.spring(), value: onboardingManager.currentStep)
                }
                
                // Navigation Controls (hidden during disclaimer step)
                if onboardingManager.currentStep != .disclaimer {
                    navigationControls
                }
            }
        }
        .onAppear {
            AccessibilityAnnouncement.announceScreenChanged()
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(onboardingManager.currentStep.rawValue + 1) of \(OnboardingManager.OnboardingStep.allCases.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Brand.ColorSystem.secondary)
                
                Spacer()
                
                .font(.caption.weight(.medium))
                .foregroundColor(Brand.ColorSystem.primary)
                .opacity((onboardingManager.isLastStep || onboardingManager.currentStep == .disclaimer) ? 0 : 1)
            }
            
            ProgressView(value: onboardingManager.progress, total: 1.0)
                .tint(Brand.ColorSystem.primary)
                .scaleEffect(y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private func stepContent(for step: OnboardingManager.OnboardingStep) -> some View {
        if step == .disclaimer {
            // Full-screen disclaimer view
            stepSpecificContent(for: step)
        } else {
            // Standard step content layout
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)
                    
                    // Icon
                    Image(systemName: step.systemImage)
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(Brand.ColorSystem.primary)
                        .accessibility(hidden: true)
                    
                    // Title and Subtitle
                    VStack(spacing: 12) {
                        Text(step.title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(step.subtitle)
                            .font(.title3)
                            .foregroundColor(Brand.ColorSystem.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)
                    
                    // Step-specific content
                    stepSpecificContent(for: step)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    @ViewBuilder
    private func stepSpecificContent(for step: OnboardingManager.OnboardingStep) -> some View {
        switch step {
        case .welcome:
            welcomeContent
        case .features:
            featuresContent
        case .disclaimer:
            OnboardingDisclaimerWrapper()
        case .permissions:
            permissionsContent
        case .complete:
            completeContent
        }
    }
    
    // MARK: - Step-Specific Content
    
    private var welcomeContent: some View {
        VStack(spacing: 24) {
            Text("Synagamy combines evidence-based medical research with user-friendly tools to help you understand and navigate your fertility journey.")
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureHighlight(
                    icon: "graduationcap.fill",
                    title: "Educational Focus",
                    description: "Based on population data, scentific research, and medical guidelines"
                )
                
                FeatureHighlight(
                    icon: "shield.fill",
                    title: "Privacy First",
                    description: "Your data stays on your device - no cloud storage"
                )
                
                FeatureHighlight(
                    icon: "stethoscope",
                    title: "Medical Grade",
                    description: "Developed by a Reproductive Specialist"
                )
            }
        }
    }
    
    private var featuresContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(OnboardingFeature.features) { feature in
                FeatureCard(feature: feature)
            }
        }
    }
    
    
    private var permissionsContent: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                PrivacyPoint(
                    icon: "lock.fill",
                    title: "Local Storage Only",
                    description: "Your cycle data and preferences are stored locally on your device.",
                    status: "Secure"
                )
                
                PrivacyPoint(
                    icon: "wifi.slash",
                    title: "No Data Transmission",
                    description: "No personal health information is sent to external servers.",
                    status: "Private"
                )
                
                PrivacyPoint(
                    icon: "eye.slash.fill",
                    title: "No Analytics Tracking",
                    description: "We don't track your usage or collect personal analytics.",
                    status: "Anonymous"
                )
            }
        }
    }
    
    private var completeContent: some View {
        VStack(spacing: 24) {
            Text("You're ready to start using Synagamy! Here are some quick tips to get started:")
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                QuickTip(
                    number: "1",
                    title: "Start with Education",
                    description: "Explore the education section to understand fertility basics"
                )
                
                QuickTip(
                    number: "2",
                    title: "Try the Predictor",
                    description: "Use the outcome predictor with lab values from your doctor"
                )
                
                QuickTip(
                    number: "3",
                    title: "Track Your Cycle",
                    description: "Use the timed intercourse tracker for optimal timing for natural conception"
                )
            }
        }
    }
    
    // MARK: - Navigation Controls
    
    private var navigationControls: some View {
        HStack(spacing: 16) {
            if !onboardingManager.isFirstStep {
                Button("Back") {
                    onboardingManager.previousStep()
                }
                .font(.headline.weight(.medium))
                .foregroundColor(Brand.ColorSystem.primary)
                .accessibilityHint("Go to previous step")
            }
            
            Spacer()
            
            Button(onboardingManager.nextButtonTitle) {
                if onboardingManager.currentStep == .disclaimer {
                    onboardingManager.acceptDisclaimer()
                }
                
                if onboardingManager.isLastStep {
                    onboardingManager.completeOnboarding()
                } else {
                    onboardingManager.nextStep()
                }
            }
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.ColorSystem.primary)
            )
            .accessibilityHint(onboardingManager.isLastStep ? "Complete onboarding and start using the app" : "Continue to next step")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Supporting Views

private struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Brand.ColorSystem.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Brand.ColorSystem.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FeatureCard: View {
    let feature: OnboardingFeature
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: feature.systemImage)
                .font(.title2)
                .foregroundColor(feature.color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }
}


private struct PrivacyPoint: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.green.opacity(0.1))
                        )
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct QuickTip: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Brand.ColorSystem.primary)
                    .frame(width: 24, height: 24)
                
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Onboarding Disclaimer Wrapper

private struct OnboardingDisclaimerWrapper: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    var body: some View {
        MedicalDisclaimerView(isFirstTime: true)
            .onReceive(NotificationCenter.default.publisher(for: .disclaimerAccepted)) { _ in
                onboardingManager.acceptDisclaimer()
                onboardingManager.nextStep()
            }
    }
}


#Preview {
    OnboardingView()
}
