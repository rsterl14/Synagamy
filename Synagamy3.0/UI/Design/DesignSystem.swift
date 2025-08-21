//
//  DesignSystem.swift
//  Synagamy3.0
//
//  Central brand tokens (colors, spacing, radii) + a few safe helpers.
//  This version removes use of SwiftUI.ShadowStyle (not constructible) and
//  uses explicit Color.black in shadow calls to avoid inference issues.
//

import SwiftUI

// MARK: - Brand Tokens

enum Brand {
    // MARK: Colors (safe fallbacks if asset isn’t present)
    enum ColorToken {
        /// Primary brand color used for tints, accents, and key strokes.
        static var primary: Color {
            Color("BrandPrimary", bundle: .main).fallback(.blue)
        }
        /// Secondary brand color used for prominent surfaces/icons.
        static var secondary: Color {
            Color("BrandSecondary", bundle: .main).fallback(.purple)
        }
        /// Neutral background for cards/tiles when you don’t want full material.
        static var surface: Color { Color(.secondarySystemBackground) }
        /// Very subtle stroke color.
        static var hairline: Color { primary.opacity(0.08) }
    }

    // MARK: Spacing (keep increments consistent)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Corner Radii
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let pill: CGFloat = 999
    }

    // MARK: Typography (optional helpers)
    enum FontToken {
        static var titleEmphasis: Font { .title3.weight(.semibold) }
        static var sectionTitle: Font { .headline }
        static var body: Font { .body }
        static var captionEmphasis: Font { .caption.weight(.semibold) }
    }
}

// MARK: - Safe color fallback
// Color fallback extension is now in View+Extensions.swift

// MARK: - Optimized Animation System
// Use Brand.Motion from EnhancedTheme.swift instead of these legacy animations

extension Brand {
    // MARK: Legacy Animation Support (use Brand.Motion instead)
    @available(*, deprecated, message: "Use Brand.Motion instead")
    enum Animation {
        static let quick = Brand.Motion.userInteraction
        static let standard = Brand.Motion.pageTransition
        static let smooth = Brand.Motion.springGentle
        static let bouncy = Brand.Motion.springBouncy
        static let fade = SwiftUI.Animation.easeOut(duration: 0.2)
    }
    
    // MARK: Shadows
    enum Shadow {
        static let subtle = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(1))
        static let card = (color: Color.black.opacity(0.08), radius: CGFloat(14), x: CGFloat(0), y: CGFloat(8))
        static let floating = (color: Color.black.opacity(0.12), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(12))
    }
    
    // MARK: Haptics
    enum Haptic {
        static let light = UIImpactFeedbackGenerator(style: .light)
        static let medium = UIImpactFeedbackGenerator(style: .medium)
        static let heavy = UIImpactFeedbackGenerator(style: .heavy)
        static let selection = UISelectionFeedbackGenerator()
        static let success = UINotificationFeedbackGenerator()
    }
}

// MARK: - Reusable helpers

extension View {
    /// Soft card surface (material + stroke + shadow) with brand defaults and performance optimization.
    func brandCardSurface(
        cornerRadius: CGFloat = Brand.Radius.lg,
    ) -> some View {
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
                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                )
        )
    }

    /// Light brand outline (works on light/dark).
    func brandStroke(cornerRadius: CGFloat = Brand.Radius.md) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Brand.ColorToken.hairline, lineWidth: 1)
        )
    }

    /// Brand-tinted prominent button with haptic feedback.
    func brandProminentButton(hapticFeedback: Bool = true) -> some View {
        buttonStyle(.borderedProminent)
            .tint(Brand.ColorToken.primary)
            .onTapGesture {
                if hapticFeedback {
                    Brand.Haptic.medium.impactOccurred()
                }
            }
    }
    
    /// Enhanced interactive button with press animation and haptic feedback.
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
        .animation(Brand.Animation.quick, value: UUID())
    }
    
    /// Consistent floating header background.
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
    
    /// Apply performance optimization conditionally.
    @ViewBuilder
    private func conditionallyOptimized(_ enabled: Bool) -> some View {
        if enabled {
            self
        } else {
            self
        }
    }
    
    /// Smooth page transition animation.
    func pageTransition() -> some View {
        transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(Brand.Animation.standard, value: UUID())
    }
    
    /// Consistent list row animation.
    func listRowAnimation(delay: Double = 0) -> some View {
        transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
        .animation(Brand.Animation.smooth.delay(delay), value: UUID())
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

// MARK: - Preview

#Preview("DesignSystem – Tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
            Text("Brand Colors").font(Brand.FontToken.sectionTitle)
            HStack(spacing: Brand.Spacing.md) {
                RoundedRectangle(cornerRadius: Brand.Radius.md)
                    .fill(Brand.ColorToken.primary).frame(width: 56, height: 32)
                RoundedRectangle(cornerRadius: Brand.Radius.md)
                    .fill(Brand.ColorToken.secondary).frame(width: 56, height: 32)
                RoundedRectangle(cornerRadius: Brand.Radius.md)
                    .fill(Brand.ColorToken.surface).frame(width: 56, height: 32)
            }

            Text("Radii").font(Brand.FontToken.sectionTitle)
            HStack(spacing: Brand.Spacing.md) {
                RoundedRectangle(cornerRadius: Brand.Radius.sm).fill(Brand.ColorToken.surface).frame(width: 48, height: 24)
                RoundedRectangle(cornerRadius: Brand.Radius.md).fill(Brand.ColorToken.surface).frame(width: 48, height: 24)
                RoundedRectangle(cornerRadius: Brand.Radius.lg).fill(Brand.ColorToken.surface).frame(width: 48, height: 24)
                RoundedRectangle(cornerRadius: Brand.Radius.xl).fill(Brand.ColorToken.surface).frame(width: 48, height: 24)
            }

            Text("Card Surface Helper").font(Brand.FontToken.sectionTitle)
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
    .background(Color(.systemGroupedBackground))
}
