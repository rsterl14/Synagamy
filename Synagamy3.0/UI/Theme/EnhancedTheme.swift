//
//  EnhancedTheme.swift
//  Synagamy3.0
//
//  Enhanced theming system for a more cohesive and fluid design experience.
//  Builds upon the existing Brand tokens with additional refinements.
//

import SwiftUI

// MARK: - Enhanced Color System

extension Brand {
    enum ColorSystem {
        // MARK: - Primary Palette
        static var primary: Color {
            Color("BrandPrimary", bundle: .main).fallback(.blue)
        }
        
        static var primaryLight: Color {
            primary.opacity(0.1)
        }
        
        static var primaryMedium: Color {
            primary.opacity(0.2)
        }
        
        static var primaryStrong: Color {
            primary.opacity(0.8)
        }
        
        // MARK: - Secondary Palette
        static var secondary: Color {
            Color("BrandSecondary", bundle: .main).fallback(.purple)
        }
        
        static var secondaryLight: Color {
            secondary.opacity(0.15)
        }
        
        static var secondaryMedium: Color {
            secondary.opacity(0.3)
        }
        
        // MARK: - Semantic Colors
        static var success: Color { Color.green }
        static var warning: Color { Color.orange }
        static var error: Color { Color.red }
        static var info: Color { Color.blue }
        
        // MARK: - Surface Colors
        static var surfaceElevated: Color { Color(.tertiarySystemBackground) }
        static var surfaceCard: Color { Color(.secondarySystemBackground) }
        static var surfaceBase: Color { Color(.systemBackground) }
        
        // MARK: - Text Colors
        static var textPrimary: Color { Color(.label) }
        static var textSecondary: Color { Color(.secondaryLabel) }
        static var textTertiary: Color { Color(.tertiaryLabel) }
        
        // MARK: - Interactive Colors
        static var interactive: Color { primary }
        static var interactivePressed: Color { primary.opacity(0.8) }
        static var interactiveDisabled: Color { Color(.quaternaryLabel) }
    }
}

// MARK: - Enhanced Typography

extension Brand {
    enum Typography {
        // MARK: - Font Weights
        enum Weight {
            static let light = Font.Weight.light
            static let regular = Font.Weight.regular
            static let medium = Font.Weight.medium
            static let semibold = Font.Weight.semibold
            static let bold = Font.Weight.bold
        }
        
        // MARK: - Font Sizes
        enum Size {
            static let xs: CGFloat = 12
            static let sm: CGFloat = 14
            static let base: CGFloat = 16
            static let lg: CGFloat = 18
            static let xl: CGFloat = 20
            static let xxl: CGFloat = 24
            static let xxxl: CGFloat = 32
        }
        
        // MARK: - Semantic Font Styles
        static var displayLarge: Font {
            .system(size: Size.xxxl, weight: Weight.bold, design: .default)
        }
        
        static var displayMedium: Font {
            .system(size: Size.xxl, weight: Weight.bold, design: .default)
        }
        
        static var headlineLarge: Font {
            .system(size: Size.xl, weight: Weight.semibold, design: .default)
        }
        
        static var headlineMedium: Font {
            .system(size: Size.lg, weight: Weight.semibold, design: .default)
        }
        
        static var bodyLarge: Font {
            .system(size: Size.lg, weight: Weight.regular, design: .default)
        }
        
        static var bodyMedium: Font {
            .system(size: Size.base, weight: Weight.regular, design: .default)
        }
        
        static var bodySmall: Font {
            .system(size: Size.sm, weight: Weight.regular, design: .default)
        }
        
        static var labelLarge: Font {
            .system(size: Size.base, weight: Weight.medium, design: .default)
        }
        
        static var labelMedium: Font {
            .system(size: Size.sm, weight: Weight.medium, design: .default)
        }
        
        static var labelSmall: Font {
            .system(size: Size.xs, weight: Weight.medium, design: .default)
        }
    }
}

// MARK: - Enhanced Spacing System

extension Brand {
    enum Layout {
        // MARK: - Spacing Scale
        static let spacing1: CGFloat = 2
        static let spacing2: CGFloat = 4
        static let spacing3: CGFloat = 8
        static let spacing4: CGFloat = 12
        static let spacing5: CGFloat = 16
        static let spacing6: CGFloat = 20
        static let spacing7: CGFloat = 24
        static let spacing8: CGFloat = 32
        static let spacing9: CGFloat = 40
        static let spacing10: CGFloat = 48
        
        // MARK: - Component Spacing
        static let tileInternalPadding: CGFloat = spacing7
        static let tileExternalSpacing: CGFloat = spacing5
        static let sectionSpacing: CGFloat = spacing8
        static let pageMargins: CGFloat = spacing5
        
        // MARK: - Interactive Areas
        static let minTouchTarget: CGFloat = 44
        static let preferredTouchTarget: CGFloat = 48
        
        // MARK: - Component Heights
        static let buttonHeight: CGFloat = 48
        static let inputHeight: CGFloat = 52
        static let tileMinHeight: CGFloat = 180
        static let tileMaxHeight: CGFloat = 220
    }
}

// MARK: - Enhanced Animation System

extension Brand {
    enum Motion {
        // MARK: - Duration Scale
        static let instant: TimeInterval = 0
        static let fast: TimeInterval = 0.1
        static let quick: TimeInterval = 0.15
        static let base: TimeInterval = 0.25
        static let slow: TimeInterval = 0.35
        static let slower: TimeInterval = 0.5
        
        // MARK: - Easing Functions
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: base)
        static let easeOut = SwiftUI.Animation.easeOut(duration: base)
        static let easeIn = SwiftUI.Animation.easeIn(duration: base)
        
        // MARK: - Spring Animations
        static let springGentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let springSnappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        // MARK: - Context-Specific Animations
        static let userInteraction = SwiftUI.Animation.easeOut(duration: fast)
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: base)
        static let listAnimation = springGentle
        static let buttonPress = SwiftUI.Animation.easeOut(duration: quick)
        
        // MARK: - Transition Presets
        static let slideFromRight = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
        
        static let scaleAndFade = AnyTransition.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        )
        
        static let slideUp = AnyTransition.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
}

// MARK: - Enhanced Shadow System

extension Brand {
    enum Elevation {
        case none
        case subtle
        case low
        case medium
        case high
        case floating
        
        var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .none:
                return (Color.clear, 0, 0, 0)
            case .subtle:
                return (Color.black.opacity(0.04), 2, 0, 1)
            case .low:
                return (Color.black.opacity(0.06), 4, 0, 2)
            case .medium:
                return (Color.black.opacity(0.08), 8, 0, 4)
            case .high:
                return (Color.black.opacity(0.12), 16, 0, 8)
            case .floating:
                return (Color.black.opacity(0.16), 24, 0, 12)
            }
        }
    }
}

// MARK: - Enhanced Visual Effects

extension View {
    /// Apply brand elevation with consistent shadow and background
    func brandElevation(_ level: Brand.Elevation, cornerRadius: CGFloat = Brand.Radius.lg) -> some View {
        let shadow = level.shadow
        return self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(
                        color: shadow.color,
                        radius: shadow.radius,
                        x: shadow.x,
                        y: shadow.y
                    )
            )
    }
    
    /// Enhanced interactive press effect
    func brandPressEffect(
        scale: CGFloat = 0.96,
        animation: Animation = Brand.Motion.userInteraction
    ) -> some View {
        self.modifier(BrandPressEffectModifier(scale: scale, animation: animation))
    }
    
    /// Smooth appear animation for list items
    func brandListItemAppear(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .scaleEffect(0.95)
            .offset(y: 20)
            .onAppear {
                withAnimation(Brand.Motion.springGentle.delay(delay)) {
                    // Animation will be handled by state changes
                }
            }
    }
    
    /// Enhanced page transition
    func brandPageTransition() -> some View {
        self
            .transition(Brand.Motion.slideFromRight)
            .animation(Brand.Motion.pageTransition, value: UUID())
    }
    
    /// Consistent focus ring for accessibility
    func brandFocusRing() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                    .stroke(Brand.ColorSystem.primary, lineWidth: 2)
                    .opacity(0) // Will be animated on focus
            )
    }
}

// MARK: - Press Effect Modifier

private struct BrandPressEffectModifier: ViewModifier {
    let scale: CGFloat
    let animation: Animation
    
    @GestureState private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(animation, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

// MARK: - Semantic View Modifiers

extension View {
    /// Apply brand tile styling with consistent elevation and spacing
    func brandTileStyle() -> some View {
        self
            .padding(Brand.Layout.tileInternalPadding)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Brand.Layout.tileMinHeight)
            .brandElevation(.medium, cornerRadius: Brand.Radius.xl)
            .brandPressEffect()
    }
    
    /// Apply brand card styling for content containers
    func brandCardStyle() -> some View {
        self
            .padding(Brand.Layout.spacing5)
            .brandElevation(.low, cornerRadius: Brand.Radius.lg)
    }
    
    /// Apply brand button styling
    func brandButtonStyle(style: BrandButtonStyle = .primary) -> some View {
        self.modifier(BrandButtonModifier(style: style))
    }
}

// MARK: - Button Styles

enum BrandButtonStyle {
    case primary
    case secondary
    case tertiary
    case danger
}

private struct BrandButtonModifier: ViewModifier {
    let style: BrandButtonStyle
    
    func body(content: Content) -> some View {
        content
            .font(Brand.Typography.labelLarge)
            .frame(height: Brand.Layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(backgroundForStyle)
            .foregroundColor(foregroundForStyle)
            .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous))
            .brandPressEffect()
    }
    
    private var backgroundForStyle: Color {
        switch style {
        case .primary:
            return Brand.ColorSystem.primary
        case .secondary:
            return Brand.ColorSystem.secondaryLight
        case .tertiary:
            return Brand.ColorSystem.surfaceElevated
        case .danger:
            return Brand.ColorSystem.error
        }
    }
    
    private var foregroundForStyle: Color {
        switch style {
        case .primary, .danger:
            return .white
        case .secondary:
            return Brand.ColorSystem.secondary
        case .tertiary:
            return Brand.ColorSystem.textPrimary
        }
    }
}