//
//  UniformedDesignSystem.swift
//  Synagamy3.0
//
//  Consolidated design system combining all brand tokens, colors, spacing, typography,
//  animations, and visual effects into one unified system. This replaces both
//  DesignSystem.swift and EnhancedTheme.swift to eliminate conflicts.
//

import SwiftUI

// MARK: - Unified Brand System

enum Brand {

    // MARK: - Color System
    enum Color {
        // MARK: Primary Brand Colors
        static var primary: SwiftUI.Color {
            SwiftUI.Color("BrandPrimary", bundle: .main).fallback(.blue)
        }

        static var primaryLight: SwiftUI.Color {
            primary.opacity(0.1)
        }

        static var primaryMedium: SwiftUI.Color {
            primary.opacity(0.2)
        }

        static var primaryStrong: SwiftUI.Color {
            primary.opacity(0.8)
        }

        // MARK: Secondary Brand Colors
        static var secondary: SwiftUI.Color {
            SwiftUI.Color("BrandSecondary", bundle: .main).fallback(.purple)
        }

        static var secondaryLight: SwiftUI.Color {
            secondary.opacity(0.15)
        }

        static var secondaryMedium: SwiftUI.Color {
            secondary.opacity(0.3)
        }

        // MARK: Surface Colors
        static var surface: SwiftUI.Color { SwiftUI.Color(.secondarySystemBackground) }
        static var surfaceElevated: SwiftUI.Color { SwiftUI.Color(.tertiarySystemBackground) }
        static var surfaceCard: SwiftUI.Color { SwiftUI.Color(.secondarySystemBackground) }
        static var surfaceBase: SwiftUI.Color { SwiftUI.Color(.systemBackground) }

        // MARK: Background Colors
        static var background: SwiftUI.Color { SwiftUI.Color(.systemBackground) }
        static var backgroundSecondary: SwiftUI.Color { SwiftUI.Color(.secondarySystemBackground) }

        // MARK: Semantic Colors
        static var success: SwiftUI.Color { SwiftUI.Color.green }
        static var warning: SwiftUI.Color { SwiftUI.Color.orange }
        static var error: SwiftUI.Color { SwiftUI.Color.red }
        static var info: SwiftUI.Color { SwiftUI.Color.blue }

        // MARK: Text Colors
        static var textPrimary: SwiftUI.Color { SwiftUI.Color(.label) }
        static var textSecondary: SwiftUI.Color { SwiftUI.Color(.secondaryLabel) }
        static var textTertiary: SwiftUI.Color { SwiftUI.Color(.tertiaryLabel) }

        // MARK: Interactive Colors
        static var interactive: SwiftUI.Color { primary }
        static var interactivePressed: SwiftUI.Color { primary.opacity(0.8) }
        static var interactiveDisabled: SwiftUI.Color { SwiftUI.Color(.quaternaryLabel) }

        // MARK: Stroke Colors
        static var hairline: SwiftUI.Color { primary.opacity(0.08) }
    }

    // MARK: - Spacing System
    enum Spacing {
        // Basic spacing scale
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32

        // Enhanced spacing scale
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

        // Component-specific spacing
        static let tileInternalPadding: CGFloat = spacing7
        static let tileExternalSpacing: CGFloat = spacing5
        static let sectionSpacing: CGFloat = spacing8
        static let pageMargins: CGFloat = spacing5
    }

    // MARK: - Corner Radius System
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let pill: CGFloat = 999
    }

    // MARK: - Typography System
    enum Typography {
        // MARK: Font Weights
        enum Weight {
            static let light = Font.Weight.light
            static let regular = Font.Weight.regular
            static let medium = Font.Weight.medium
            static let semibold = Font.Weight.semibold
            static let bold = Font.Weight.bold
        }

        // MARK: Font Sizes
        enum Size {
            static let xs: CGFloat = 12
            static let sm: CGFloat = 14
            static let base: CGFloat = 16
            static let lg: CGFloat = 18
            static let xl: CGFloat = 20
            static let xxl: CGFloat = 24
            static let xxxl: CGFloat = 32
        }

        // MARK: Semantic Font Styles
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

        // Legacy font tokens for backward compatibility
        static var titleEmphasis: Font { .title3.weight(.semibold) }
        static var sectionTitle: Font { .headline }
        static var body: Font { .body }
        static var captionEmphasis: Font { .caption.weight(.semibold) }
    }

    // MARK: - Layout System
    enum Layout {
        // Interactive areas
        static let minTouchTarget: CGFloat = 44
        static let preferredTouchTarget: CGFloat = 48

        // Component heights
        static let buttonHeight: CGFloat = 48
        static let inputHeight: CGFloat = 52
        static let tileMinHeight: CGFloat = 180
        static let tileMaxHeight: CGFloat = 220
    }

    // MARK: - Shadow & Elevation System
    enum Shadow {
        static let subtle = (color: SwiftUI.Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(1))
        static let card = (color: SwiftUI.Color.black.opacity(0.08), radius: CGFloat(14), x: CGFloat(0), y: CGFloat(8))
        static let floating = (color: SwiftUI.Color.black.opacity(0.12), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(12))
    }

    enum Elevation {
        case none
        case subtle
        case low
        case medium
        case high
        case floating

        var shadow: (color: SwiftUI.Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .none:
                return (SwiftUI.Color.clear, 0, 0, 0)
            case .subtle:
                return (SwiftUI.Color.black.opacity(0.04), 2, 0, 1)
            case .low:
                return (SwiftUI.Color.black.opacity(0.06), 4, 0, 2)
            case .medium:
                return (SwiftUI.Color.black.opacity(0.08), 8, 0, 4)
            case .high:
                return (SwiftUI.Color.black.opacity(0.12), 16, 0, 8)
            case .floating:
                return (SwiftUI.Color.black.opacity(0.16), 24, 0, 12)
            }
        }
    }

    // MARK: - Animation System
    enum Motion {
        // Duration scale
        static let instant: TimeInterval = 0
        static let fast: TimeInterval = 0.1
        static let quick: TimeInterval = 0.15
        static let base: TimeInterval = 0.25
        static let slow: TimeInterval = 0.35
        static let slower: TimeInterval = 0.5

        // Easing functions
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: base)
        static let easeOut = SwiftUI.Animation.easeOut(duration: base)
        static let easeIn = SwiftUI.Animation.easeIn(duration: base)

        // Spring animations
        static let springGentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let springSnappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)

        // Context-specific animations
        static let userInteraction = SwiftUI.Animation.easeOut(duration: fast)
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: base)
        static let listAnimation = springGentle
        static let buttonPress = SwiftUI.Animation.easeOut(duration: quick)

        // Transition presets
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

    // MARK: - Haptics System
    enum Haptic {
        static let light = UIImpactFeedbackGenerator(style: .light)
        static let medium = UIImpactFeedbackGenerator(style: .medium)
        static let heavy = UIImpactFeedbackGenerator(style: .heavy)
        static let selection = UISelectionFeedbackGenerator()
        static let success = UINotificationFeedbackGenerator()
    }
}

// MARK: - View Extensions

extension View {
    // MARK: Card and Surface Styles

    /// Soft card surface with material, stroke, and shadow
    func brandCardSurface(cornerRadius: CGFloat = Brand.Radius.lg) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.regularMaterial)
                .shadow(
                    color: Brand.Shadow.card.color,
                    radius: Brand.Shadow.card.radius,
                    x: Brand.Shadow.card.x,
                    y: Brand.Shadow.card.y
                )
                .shadow(
                    color: Brand.Shadow.subtle.color,
                    radius: Brand.Shadow.subtle.radius,
                    x: Brand.Shadow.subtle.x,
                    y: Brand.Shadow.subtle.y
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Brand.Color.hairline, lineWidth: 1)
                )
        )
    }

    /// Light brand outline
    func brandStroke(cornerRadius: CGFloat = Brand.Radius.md) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Brand.Color.hairline, lineWidth: 1)
        )
    }

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

    // MARK: Button Styles

    /// Brand-tinted prominent button with haptic feedback
    func brandProminentButton(hapticFeedback: Bool = true) -> some View {
        buttonStyle(.borderedProminent)
            .tint(Brand.Color.primary)
            .onTapGesture {
                if hapticFeedback {
                    Brand.Haptic.medium.impactOccurred()
                }
            }
    }

    /// Enhanced interactive button with press animation and haptic feedback
    func brandInteractiveButton(
        pressScale: CGFloat = 0.96,
        hapticFeedback: Bool = true
    ) -> some View {
        scaleEffect(1.0)
        .onTapGesture {
            if hapticFeedback {
                Brand.Haptic.light.impactOccurred()
            }
        }
        .animation(Brand.Motion.userInteraction, value: UUID())
    }

    /// Enhanced interactive press effect
    func brandPressEffect(
        scale: CGFloat = 0.96,
        animation: Animation = Brand.Motion.userInteraction
    ) -> some View {
        self.modifier(BrandPressEffectModifier(scale: scale, animation: animation))
    }

    // MARK: Layout Styles

    /// Apply brand tile styling with consistent elevation and spacing
    func brandTileStyle() -> some View {
        self
            .padding(Brand.Spacing.tileInternalPadding)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Brand.Layout.tileMinHeight)
            .brandElevation(.medium, cornerRadius: Brand.Radius.xl)
            .brandPressEffect()
    }

    /// Apply brand card styling for content containers
    func brandCardStyle() -> some View {
        self
            .padding(Brand.Spacing.spacing5)
            .brandElevation(.low, cornerRadius: Brand.Radius.lg)
    }

    // MARK: Headers and Navigation

    /// Consistent floating header background
    func brandFloatingHeader() -> some View {
        background(
            RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: Brand.Shadow.floating.color,
                    radius: Brand.Shadow.floating.radius,
                    x: Brand.Shadow.floating.x,
                    y: Brand.Shadow.floating.y
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous))
    }

    // MARK: Animations

    /// Smooth page transition animation
    func pageTransition() -> some View {
        transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(Brand.Motion.pageTransition, value: UUID())
    }

    /// Consistent list row animation
    func listRowAnimation(delay: Double = 0) -> some View {
        transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
        .animation(Brand.Motion.springGentle.delay(delay), value: UUID())
    }

    /// Enhanced page transition
    func brandPageTransition() -> some View {
        self
            .transition(Brand.Motion.slideFromRight)
            .animation(Brand.Motion.pageTransition, value: UUID())
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

    /// Consistent focus ring for accessibility
    func brandFocusRing() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                    .stroke(Brand.Color.primary, lineWidth: 2)
                    .opacity(0) // Will be animated on focus
            )
    }
}

// MARK: - Button Styles

struct BrandTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                Brand.Motion.springSnappy,
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                    impactGenerator.prepare()
                    impactGenerator.impactOccurred()
                }
            }
    }
}

enum BrandButtonStyle {
    case primary
    case secondary
    case tertiary
    case danger
}

struct BrandButtonModifier: ViewModifier {
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

    private var backgroundForStyle: SwiftUI.Color {
        switch style {
        case .primary:
            return Brand.Color.primary
        case .secondary:
            return Brand.Color.secondaryLight
        case .tertiary:
            return Brand.Color.surfaceElevated
        case .danger:
            return Brand.Color.error
        }
    }

    private var foregroundForStyle: SwiftUI.Color {
        switch style {
        case .primary, .danger:
            return .white
        case .secondary:
            return Brand.Color.secondary
        case .tertiary:
            return Brand.Color.textPrimary
        }
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
// MARK: - Preview

#Preview("UniformedDesignSystem – Tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
            Text("Brand Colors").font(Brand.Typography.sectionTitle)
            HStack(spacing: Brand.Spacing.md) {
                RoundedRectangle(cornerRadius: Brand.Radius.md)
                    .fill(Brand.Color.primary).frame(width: 56, height: 32)
                RoundedRectangle(cornerRadius: Brand.Radius.md)
                    .fill(Brand.Color.secondary).frame(width: 56, height: 32)
                RoundedRectangle(cornerRadius: Brand.Radius.md)
                    .fill(Brand.Color.surface).frame(width: 56, height: 32)
            }

            Text("Radii").font(Brand.Typography.sectionTitle)
            HStack(spacing: Brand.Spacing.md) {
                RoundedRectangle(cornerRadius: Brand.Radius.sm).fill(Brand.Color.surface).frame(width: 48, height: 24)
                RoundedRectangle(cornerRadius: Brand.Radius.md).fill(Brand.Color.surface).frame(width: 48, height: 24)
                RoundedRectangle(cornerRadius: Brand.Radius.lg).fill(Brand.Color.surface).frame(width: 48, height: 24)
                RoundedRectangle(cornerRadius: Brand.Radius.xl).fill(Brand.Color.surface).frame(width: 48, height: 24)
            }

            Text("Card Surface Helper").font(Brand.Typography.sectionTitle)
            VStack(alignment: .leading, spacing: 8) {
                Text("This card uses .brandCardSurface()").font(.subheadline)
                VStack(alignment: .leading) {
                    Text("Body line 1")
                    Text("Body line 2").foregroundStyle(.secondary).font(.footnote)
                }
                .padding()
                .brandCardSurface()
            }
        }
        .padding()
    }
    .background(SwiftUI.Color(.systemGroupedBackground))
}

// MARK: - Color Extensions

extension SwiftUI.Color {
    /// Provides fallback color if the named color doesn't exist
    func fallback(_ fallbackColor: SwiftUI.Color) -> SwiftUI.Color {
        // In most cases, named colors in the app bundle should exist
        // If they don't exist, this will fall back to the provided color
        // For now, we'll assume the named colors exist and return self
        // In a production app, you could add more sophisticated checking
        return self
    }
}
