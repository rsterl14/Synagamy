//
//  AppWalkthroughView.swift
//  Synagamy3.0
//
//  Interactive walkthrough overlay to help users understand the app
//

import SwiftUI

struct AppWalkthroughView: View {
    @Binding var isShowing: Bool
    @State private var currentStep = 0
    @State private var animateIn = false
    @State private var offset = CGSize.zero
    
    private let steps: [WalkthroughStep] = [
        WalkthroughStep(
            title: "",
            description: "",
            icon: "heart.fill",
            position: .center,
            highlightArea: nil
        ),
        WalkthroughStep(
            title: "A Starting Point",
            description: "Begin with 'A Starting Point' to understand infertility basics and determine if you need further evaluation. This section helps you assess whether you might benefit from fertility care.",
            icon: "person.3.fill",
            position: .center,
            highlightArea: nil
        ),
        WalkthroughStep(
            title: "Education",
            description: "Access comprehensive educational content about reproduction, fertility, and treatment options. Learn about the science behind fertility in easy-to-understand language.",
            icon: "book.fill",
            position: .center,
            highlightArea: nil
        ),
        WalkthroughStep(
            title: "Pathway Explorer",
            description: "Use the Pathway Explorer to discover personalized treatment options based on your specific situation. Answer questions to get tailored guidance for your journey.",
            icon: "map.fill",
            position: .center,
            highlightArea: nil
        ),
        WalkthroughStep(
            title: "Timed Intercourse",
            description: "Calculate your fertility window and optimal timing for conception. This tool helps you maximize your chances of natural conception by identifying your most fertile days.",
            icon: "heart.circle.fill",
            position: .center,
            highlightArea: nil
        ),
        WalkthroughStep(
            title: "Outcome Predictor",
            description: "Get realistic expectations about IVF success rates based on your age and circumstances. This evidence-based tool helps set appropriate expectations for treatment outcomes.",
            icon: "chart.line.uptrend.xyaxis",
            position: .center,
            highlightArea: nil
        ),
        WalkthroughStep(
            title: "Additional Resources",
            description: "Explore the Clinics finder to locate fertility centers near you, browse FAQs for common questions, access Resources for helpful links, and connect with the Community for support.",
            icon: "person.2.wave.2.fill",
            position: .center,
            highlightArea: nil
        ),
        WalkthroughStep(
            title: "You're All Set!",
            description: "Explore at your own pace. Remember, you can always tap the info button to see this walkthrough again.",
            icon: "checkmark.circle.fill",
            position: .center,
            highlightArea: nil
        )
    ]
    
    var body: some View {
        ZStack {
            // Background overlay with cutouts
            if let highlightArea = steps[currentStep].highlightArea {
                // Create overlay with cutout
                OverlayWithCutout(cutoutRect: highlightArea)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if currentStep == steps.count - 1 {
                            dismissWalkthrough()
                        } else {
                            nextStep()
                        }
                    }
                
                // Highlight border around cutout
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: highlightArea.width, height: highlightArea.height)
                    .position(x: highlightArea.midX, y: highlightArea.midY)
                    .shadow(color: .white.opacity(0.5), radius: 15)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIn)
            } else {
                // Full overlay for center steps
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if currentStep == steps.count - 1 {
                            dismissWalkthrough()
                        } else {
                            nextStep()
                        }
                    }
            }
            
            // Main walkthrough card
            walkthroughCard
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if abs(value.translation.width) > 100 {
                                    if value.translation.width > 0 {
                                        // Swiped right - previous
                                        previousStep()
                                    } else {
                                        // Swiped left - next
                                        nextStep()
                                    }
                                }
                                offset = .zero
                            }
                        }
                )
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                animateIn = true
            }
        }
    }
    
    private var walkthroughCard: some View {
        let step = steps[currentStep]
        
        return VStack(spacing: 0) {
            // Card content
            VStack(spacing: 20) {
                // Special content for welcome step
                if currentStep == 0 {
                    ZStack {
                        // Primary logo (larger) - positioned slightly up
                        Image("SynagamyLogoTwo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140 * 1.2)
                            .offset(y: -30)
                        
                        // Quote image (smaller) - positioned below and overlapping
                        Image("SynagamyQuote")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140 * 1.2)
                            .offset(y: 50)
                    }
                } else {
                    // Icon for other steps
                    ZStack {
                        Circle()
                            .fill(Brand.ColorSystem.primary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: step.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(Brand.ColorSystem.primary)
                    }
                }
                
                // Text content (skip for welcome slide)
                if currentStep != 0 {
                    VStack(spacing: 12) {
                        Text(step.title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Brand.ColorSystem.primary : Brand.ColorSystem.primary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentStep)
                    }
                }
                .padding(.top, 8)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button {
                            previousStep()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.caption.weight(.semibold))
                                Text("Previous")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(Brand.ColorSystem.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Brand.ColorSystem.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Button {
                        if currentStep == steps.count - 1 {
                            dismissWalkthrough()
                        } else {
                            nextStep()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentStep == steps.count - 1 ? "Get Started" : "Next")
                                .font(.subheadline.weight(.medium))
                            
                            if currentStep == steps.count - 1 {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.semibold))
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Brand.ColorSystem.primary)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .frame(maxWidth: 340)
        .position(positionForStep(step))
    }
    
    private func positionForStep(_ step: WalkthroughStep) -> CGPoint {
        let screenSize = UIScreen.main.bounds.size
        
        switch step.position {
        case .center:
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
            
        case .topCenter:
            if let highlightArea = step.highlightArea {
                // Position card above the highlighted area with more space
                let cardY = highlightArea.minY - 220
                // Ensure it doesn't go too high
                return CGPoint(
                    x: screenSize.width / 2,
                    y: max(cardY, 120)
                )
            }
            return CGPoint(x: screenSize.width / 2, y: 150)
            
        case .bottomCenter:
            if let highlightArea = step.highlightArea {
                // Position card below the highlighted area with more space
                let cardY = highlightArea.maxY + 220
                // Ensure it doesn't go off screen
                return CGPoint(
                    x: screenSize.width / 2,
                    y: min(cardY, screenSize.height - 180)
                )
            }
            return CGPoint(x: screenSize.width / 2, y: screenSize.height - 200)
            
        case .topLeading:
            if let highlightArea = step.highlightArea {
                return CGPoint(
                    x: screenSize.width / 2,
                    y: highlightArea.minY - 180
                )
            }
            return CGPoint(x: screenSize.width / 2, y: 200)
            
        case .topTrailing:
            return CGPoint(x: screenSize.width - 170, y: 200)
        case .bottomLeading:
            return CGPoint(x: 170, y: screenSize.height - 200)
        case .bottomTrailing:
            return CGPoint(x: screenSize.width - 170, y: screenSize.height - 200)
        }
    }
    
    // MARK: - Navigation Actions
    
    private func nextStep() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentStep < steps.count - 1 {
                currentStep += 1
            }
        }
    }
    
    private func previousStep() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }
    
    private func dismissWalkthrough() {
        withAnimation(.easeOut(duration: 0.3)) {
            animateIn = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
    
    // MARK: - Skip Button
    private var skipButton: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    dismissWalkthrough()
                } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding()
            }
            
            Spacer()
        }
    }
}

// MARK: - Data Models

struct WalkthroughStep {
    let title: String
    let description: String
    let icon: String
    let position: WalkthroughPosition
    let highlightArea: CGRect?
}

enum WalkthroughPosition {
    case center
    case topCenter
    case bottomCenter
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}

// MARK: - Overlay with Cutout View

struct OverlayWithCutout: View {
    let cutoutRect: CGRect
    
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.7))
            .mask {
                Rectangle()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: cutoutRect.width, height: cutoutRect.height)
                            .position(x: cutoutRect.midX, y: cutoutRect.midY)
                            .blendMode(.destinationOut)
                    )
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        AppWalkthroughView(isShowing: .constant(true))
    }
}
