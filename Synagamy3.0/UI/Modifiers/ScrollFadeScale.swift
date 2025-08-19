//
//  ScrollFadeScale.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  A pair of lightweight effects for list rows/cards:
//   1) Zero-arg convenience: subtle fade/scale on appear (matches existing call sites).
//   2) Offset-driven version: fade/scale based on distance from a reference offset.
//
//  App Store–friendly: pure SwiftUI transforms, no private APIs.
//

import SwiftUI

// MARK: - Zero-arg convenience (used widely in your code)

private struct AppearFadeScale: ViewModifier {
    @State private var appeared = false
    var initialOpacity: Double = 0.0
    var initialScale: CGFloat = 0.98
    var animation: Animation = .easeOut(duration: 0.25)

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : initialOpacity)
            .scaleEffect(appeared ? 1.0 : initialScale)
            .onAppear {
                withAnimation(animation) { appeared = true }
            }
    }
}

// MARK: - Offset-driven version (optional, for fancy scroll effects)

private struct ScrollFadeScale: ViewModifier {
    /// Global/relative scroll offset for the item (caller computes this if desired).
    let scrollOffset: CGFloat
    /// How far (in points) before the item fully fades.
    var fadeDistance: CGFloat = 200
    /// Minimum scale when far away.
    var minScale: CGFloat = 0.88

    func body(content: Content) -> some View {
        let distance = abs(scrollOffset)
        let clamped = min(1, max(0, distance / max(1, fadeDistance))) // avoid divide-by-zero
        let opacity = 1 - clamped
        let scale = 1 - clamped * (1 - minScale)

        return content
            .opacity(opacity)
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.25), value: scrollOffset)
    }
}

// MARK: - Public extensions

extension View {
    /// Simple, subtle “fade/scale on appear” used by most list rows and tiles.
    func scrollFadeScale() -> some View {
        modifier(AppearFadeScale())
    }

    /// Advanced version: fade/scale based on an external `offset` you provide.
    /// Use when you have a GeometryReader measuring item position.
    func scrollFadeScale(
        offset: CGFloat,
        fadeDistance: CGFloat = 200,
        minScale: CGFloat = 0.88
    ) -> some View {
        modifier(ScrollFadeScale(scrollOffset: offset,
                                 fadeDistance: fadeDistance,
                                 minScale: minScale))
    }
}

// MARK: - Previews

#Preview("ScrollFadeScale • Zero-arg") {
    VStack(spacing: 16) {
        ForEach(0..<5) { i in
            Text("Tile \(i)")
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("BrandPrimary").opacity(0.12))
                )
                .scrollFadeScale() // zero-arg convenience
                .padding(.horizontal, 16)
        }
    }
    .padding(.vertical, 24)
}

#Preview("ScrollFadeScale • Offset-driven") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach(0..<12) { i in
                GeometryReader { geo in
                    let offset = geo.frame(in: .global).minY
                    Text("Row \(i)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 68)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("BrandSecondary").opacity(0.12))
                        )
                        .scrollFadeScale(offset: offset, fadeDistance: 240, minScale: 0.9)
                        .padding(.horizontal, 16)
                }
                .frame(height: 68)
            }
        }
        .padding(.vertical, 24)
    }
}
