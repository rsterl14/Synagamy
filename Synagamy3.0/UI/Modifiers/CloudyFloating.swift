//
//  CloudyFloating.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  A reusable modifier that applies a soft “cloudy floating” background
//  effect to views (used for headers like FloatingLogoHeader).
//
//  Improvements
//  ------------
//  • Clear documentation + tunable parameters (blur radius, opacity).
//  • Safe fallbacks for colors (uses brand tokens with system fallback).
//  • Smooth shadows with no offscreen rendering hacks.
//  • App Store–friendly (uses only SwiftUI layers, no private APIs).
//

import SwiftUI

struct CloudyFloating: ViewModifier {
    /// Background color (defaults to brand surface).
    var backgroundColor: Color = Brand.ColorToken.surface
    /// Blur radius applied to the material.
    var blurRadius: CGFloat = 20
    /// Shadow strength for the floating effect.
    var shadowOpacity: Double = 0.12
    /// Corner radius for rounding.
    var cornerRadius: CGFloat = Brand.Radius.lg

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor.opacity(0.9))
                    .background(.ultraThinMaterial) // glassy effect
                    .blur(radius: blurRadius, opaque: false)
                    .shadow(color: .black.opacity(shadowOpacity), radius: 18, x: 0, y: 8)
                    .shadow(color: .black.opacity(shadowOpacity * 0.5), radius: 6, x: 0, y: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Convenience extension

extension View {
    /// Applies a soft cloudy floating effect behind a view.
    func cloudyFloating(
        backgroundColor: Color = Brand.ColorToken.surface,
        blurRadius: CGFloat = 20,
        shadowOpacity: Double = 0.12,
        cornerRadius: CGFloat = Brand.Radius.lg
    ) -> some View {
        self.modifier(
            CloudyFloating(
                backgroundColor: backgroundColor,
                blurRadius: blurRadius,
                shadowOpacity: shadowOpacity,
                cornerRadius: cornerRadius
            )
        )
    }
}

// MARK: - Previews

#Preview("CloudyFloating Demo") {
    VStack(spacing: 24) {
        Text("Floating Header")
            .font(.title2.weight(.semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .cloudyFloating()

        Text("Another floating element")
            .padding()
            .frame(maxWidth: .infinity)
            .cloudyFloating(backgroundColor: .white, blurRadius: 12, shadowOpacity: 0.2)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
