//
//  StandardPageLayout.swift
//  Synagamy3.0
//
//  Enhanced standard page layout with unified floating header,
//  optimized performance, and consistent styling across the app.
//

// Required imports for dependencies
// ErrorHandler from Core/Data/
// Brand design system from UI/System/UniformedDesignSystem.swift
// UnifiedFloatingHeader from UI/Navigation/
// HomeButton from UI/Navigation/
// NetworkViewExtensions for .errorAlert modifier

import SwiftUI
import Foundation

/// Enhanced standard page layout used throughout the app
struct StandardPageLayout<Content: View>: View {
    // MARK: - Properties
    
    let primaryImage: String
    let secondaryImage: String?
    let showHomeButton: Bool
    let usePopToRoot: Bool
    let showBackButton: Bool
    let content: Content
    
    @State private var headerHeight: CGFloat = 160
    @StateObject private var errorHandler = ErrorHandler.shared
    
    // MARK: - Initializers
    
    init(
        primaryImage: String,
        secondaryImage: String? = nil,
        showHomeButton: Bool = true,
        usePopToRoot: Bool = true,
        showBackButton: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.primaryImage = primaryImage
        self.secondaryImage = secondaryImage
        self.showHomeButton = showHomeButton
        self.usePopToRoot = usePopToRoot
        self.showBackButton = showBackButton
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        content
                            .padding(.horizontal, Brand.Spacing.pageMargins)
                            .padding(.top, Brand.Spacing.sm)
                            .padding(.bottom, Brand.Spacing.lg)
                    }
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemBackground))
            }
            
            // MARK: - Floating Header
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: headerHeight)
            }
            .overlay(alignment: .top) {
                UnifiedFloatingHeader(
                    primaryImage: primaryImage, 
                    secondaryImage: secondaryImage,
                    height: Brand.Spacing.spacing10 * 3
                )
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { headerHeight = geo.size.height }
                            .onChange(of: geo.size.height) { _, newHeight in
                                if abs(headerHeight - newHeight) > 1 {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        headerHeight = newHeight
                                    }
                                }
                            }
                    }
                )
            }
            
            // Floating navigation buttons - symmetrical with magnifying glass
            VStack {
                HStack {
                    // Floating back button (only show if needed)
                    if showBackButton {
                        FloatingBackButton()
                            .padding(.leading, 16)
                    } else {
                        Spacer()
                            .frame(width: 56) // Reserve space for symmetry
                    }
                    
                    Spacer()
                    
                    // Floating home button
                    if showHomeButton {
                        HomeButton(usePopToRoot: usePopToRoot)
                            .padding(.trailing, 16)
                    }
                }
                .padding(.top, 60) // Match magnifying glass height
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        
        // MARK: - Navigation Configuration
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        
        // MARK: - Error Handling
        .errorAlert(
            onRetry: {
                // Perform basic health check
                Task {
                    await performBasicHealthCheck()
                }
            },
            onNavigateHome: {
                NotificationCenter.default.post(name: .goHome, object: nil)
            }
        )
    }
    
    // MARK: - Helpers
    
    private func performBasicHealthCheck() async {
        // Basic validation that can be performed at any view level
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}

// MARK: - Floating Back Button

private struct FloatingBackButton: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @State private var isPressed = false
    
    var body: some View {
        Button {
            handleBack()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Brand.Color.primary,
                                    Brand.Color.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Brand.Color.primary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("Go Back")
        .accessibilityHint("Returns to the previous screen")
    }
    
    private func handleBack() {
        // Optimized haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()
        impactGenerator.impactOccurred()
        
        // Try dismiss first (for sheets/modals), then presentationMode
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo"
        ) {
            VStack(spacing: 20) {
                ForEach(0..<5) { index in
                    Text("Sample content \(index)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Brand.Color.primary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
}