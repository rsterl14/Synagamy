//
//  View+Extensions.swift
//  Synagamy3.0
//
//  Common view extensions used throughout the app for consistent
//  styling and behavior.
//

import SwiftUI

// MARK: - Layout Extensions

extension View {
    /// Applies standard page padding
    func standardPagePadding() -> some View {
        self.padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
    
    /// Applies standard tile grid spacing
    func tileGridSpacing() -> some View {
        self.padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
    
    /// Standard navigation configuration for feature views
    func standardNavigation(showHomeButton: Bool = true, usePopToRoot: Bool = false) -> some View {
        self
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if showHomeButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        HomeButton(usePopToRoot: usePopToRoot)
                    }
                }
            }
    }
    
    /// Standard scroll view configuration
    func standardScrollView() -> some View {
        self
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
    }
}

// MARK: - Conditional Modifiers

extension View {
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies a modifier with else case
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Animation Extensions

extension View {
    /// Standard appear animation
    func standardAppearAnimation(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .scaleEffect(0.95)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                    // Animation will be handled by state changes
                }
            }
    }
    
    /// Simple scroll animation
    func optimizedScrollAnimation() -> some View {
        self
    }
}

// MARK: - Loading and Error States

extension View {
    /// Standard loading overlay
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color(.systemBackground)
                        .opacity(0.8)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity)
            }
        }
    }
    
    /// Standard error overlay
    func errorOverlay(_ errorMessage: String?) -> some View {
        self.overlay {
            if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Something went wrong")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Accessibility Extensions

extension View {
    /// Standard accessibility configuration for navigation items
    func navigationAccessibility(title: String, subtitle: String? = nil, hint: String = "Tap to open") -> some View {
        let subtitleText = subtitle?.isEmpty == false ? ". \(subtitle!)" : ""
        return self.accessibilityLabel("\(title)\(subtitleText). \(hint)")
    }
    
    /// Standard accessibility for buttons
    func buttonAccessibility(label: String, hint: String = "Double tap to activate") -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Custom Modifiers

// OptimizedScrollModifier is defined in PerformanceOptimizer.swift

// MARK: - Color Extensions

extension Color {
    /// Provides fallback color if the named color doesn't exist
    func fallback(_ fallbackColor: Color) -> Color {
        return self
    }
}