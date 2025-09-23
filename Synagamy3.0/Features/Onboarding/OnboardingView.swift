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
            Brand.Color.surfaceBase
                .ignoresSafeArea()
            
            // Background gradient overlay
            LinearGradient(
                colors: [
                    Brand.Color.primary.opacity(0.1),
                    Brand.Color.secondary.opacity(0.05)
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
                    .animation(Brand.Motion.springGentle, value: onboardingManager.currentStep)
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
        VStack(spacing: Brand.Spacing.sm) {
            HStack {
                Text("Step \(onboardingManager.currentStep.rawValue + 1) of \(OnboardingManager.OnboardingStep.allCases.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Brand.Color.secondary)
                
                Spacer()
                
                .font(.caption.weight(.medium))
                .foregroundColor(Brand.Color.primary)
                .opacity((onboardingManager.isLastStep || onboardingManager.currentStep == .disclaimer) ? 0 : 1)
            }
            
            ProgressView(value: onboardingManager.progress, total: 1.0)
                .tint(Brand.Color.primary)
                .scaleEffect(y: 2)
        }
        .padding(.horizontal, Brand.Spacing.xl)
        .padding(.vertical, Brand.Spacing.md)
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
                VStack(spacing: Brand.Spacing.xxl) {
                    Spacer(minLength: Brand.Spacing.xl)
                    
                    // Icon
                    Image(systemName: step.systemImage)
                        .font(.system(size: Brand.Typography.Size.xxxl * 2, weight: Brand.Typography.Weight.light))
                        .foregroundColor(Brand.Color.primary)
                        .accessibility(hidden: true)
                    
                    // Title and Subtitle
                    VStack(spacing: Brand.Spacing.md) {
                        Text(step.title)
                            .font(Brand.Typography.displayLarge)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(step.subtitle)
                            .font(Brand.Typography.headlineMedium)
                            .foregroundColor(Brand.Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)
                    
                    // Step-specific content
                    stepSpecificContent(for: step)
                    
                    Spacer(minLength: Brand.Spacing.xl)
                }
                .padding(.horizontal, Brand.Spacing.xl)
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
        VStack(spacing: Brand.Spacing.xl) {
            Text("Synagamy combines evidence-based medical research with user-friendly tools to help you understand and navigate your fertility journey.")
                .font(Brand.Typography.bodyMedium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
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
        LazyVStack(spacing: Brand.Spacing.lg) {
            ForEach(OnboardingFeature.features) { feature in
                FeatureCard(feature: feature)
            }
        }
    }
    
    
    private var permissionsContent: some View {
        VStack(spacing: Brand.Spacing.xl) {
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
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
        VStack(spacing: Brand.Spacing.xl) {
            Text("You're ready to start using Synagamy! Here are some quick tips to get started:")
                .font(Brand.Typography.bodyMedium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
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
        HStack(spacing: Brand.Spacing.lg) {
            if !onboardingManager.isFirstStep {
                Button("Back") {
                    onboardingManager.previousStep()
                }
                .font(Brand.Typography.labelLarge)
                .foregroundColor(Brand.Color.primary)
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
            .font(Brand.Typography.labelLarge)
            .foregroundColor(.white)
            .padding(.horizontal, Brand.Spacing.xxl)
            .padding(.vertical, Brand.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                    .fill(Brand.Color.primary)
            )
            .brandPressEffect()
            .accessibilityHint(onboardingManager.isLastStep ? "Complete onboarding and start using the app" : "Continue to next step")
        }
        .padding(.horizontal, Brand.Spacing.xl)
        .padding(.bottom, Brand.Spacing.xxl)
    }
}

// MARK: - Supporting Views

private struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Brand.Color.primary)
                .frame(width: Brand.Spacing.xl)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                Text(title)
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FeatureCard: View {
    let feature: OnboardingFeature
    
    var body: some View {
        HStack(alignment: .center, spacing: Brand.Spacing.lg) {
            Image(systemName: feature.systemImage)
                .font(.title2)
                .foregroundColor(feature.color)
                .frame(width: Brand.Spacing.xxl, height: Brand.Spacing.xxl)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                Text(feature.title)
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(Brand.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
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
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: icon)
                .font(Brand.Typography.headlineMedium)
                .foregroundColor(Brand.Color.success)
                .frame(width: Brand.Spacing.xl)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                HStack {
                    Text(title)
                        .font(Brand.Typography.labelMedium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(status)
                        .font(Brand.Typography.labelSmall)
                        .foregroundColor(Brand.Color.success)
                        .padding(.horizontal, Brand.Spacing.sm)
                        .padding(.vertical, Brand.Spacing.spacing1)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                .fill(Brand.Color.success.opacity(0.1))
                        )
                }
                
                Text(description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
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
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Brand.Color.primary)
                    .frame(width: Brand.Spacing.xl, height: Brand.Spacing.xl)
                
                Text(number)
                    .font(Brand.Typography.labelSmall.weight(.bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                Text(title)
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.secondary)
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
