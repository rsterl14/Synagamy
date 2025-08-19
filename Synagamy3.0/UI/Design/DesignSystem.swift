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

extension Color {
    /// Returns `self` now; parameter kept for clarity/future override hooks.
    fileprivate func fallback(_ alt: Color) -> Color { self }
}

// MARK: - Reusable helpers

extension View {
    /// Soft card surface (material + stroke + shadow) with brand defaults.
    func brandCardSurface(cornerRadius: CGFloat = Brand.Radius.lg) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
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

    /// Brand-tinted prominent button.
    func brandProminentButton() -> some View {
        buttonStyle(.borderedProminent).tint(Brand.ColorToken.primary)
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
