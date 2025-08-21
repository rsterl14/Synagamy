//
//  ScrollFadeScale.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  A trio of lightweight effects for list rows/cards:
//   1) Appear fade/scale (zero-arg convenience).
//   2) Offset-driven fade/scale (you provide offset).
//   3) Vanish-into-page (TOP ONLY): tiles “sink” and disappear as they approach the top.
//      • The top-most tile is NOT blurred at the threshold; blur ramps in only after it passes above.
//
//  App Store–friendly: pure SwiftUI transforms, no private APIs.
//

import SwiftUI

// MARK: - Zero-arg convenience (used widely in your code)

private struct AppearFadeScale: ViewModifier {
    @State private var appeared = false
    
    var initialOpacity: Double = 0.0
    var initialScale: CGFloat = 0.98
    
    private var animation: Animation {
        .easeOut(duration: 0.25)
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : initialOpacity)
            .scaleEffect(appeared ? 1.0 : initialScale)
            .onAppear {
                withAnimation(animation) { 
                    appeared = true 
                }
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

// MARK: - Vanish-into-page (TOP ONLY, with blur protection at the top)

private struct VanishIntoPage: ViewModifier {
    
    /// How far *below the top threshold* before the tile fully fades.
    var vanishDistance: CGFloat = 260
    /// Minimum scale when near the top.
    var minScale: CGFloat = 0.86
    /// Max blur (subtle; we keep it low to preserve legibility during motion).
    var maxBlur: CGFloat = 3
    /// Extra vertical offset to simulate sinking into the page.
    var maxYOffset: CGFloat = 6
    /// If you have a floating header, set this to its height so the vanish starts beneath it.
    var topInset: CGFloat = 0
    /// How many points *past the top* before blur starts ramping in.
    /// This ensures the top-most visible tile is never blurred.
    var blurKickIn: CGFloat = 14

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            let settings = (shouldAnimate: true, duration: 0.25)

            // Distance from the *top threshold* (0 + topInset).
            // We ramp the effect as the item's top approaches that threshold.
            let relativeY = frame.minY - topInset

            // Normalize into [0, 1]:
            //  - 0 when far below the top (relativeY >= vanishDistance)
            //  - 1 when at or above the top threshold (relativeY <= 0)
            let raw = 1 - min(1, max(0, relativeY / max(1, vanishDistance)))

            // Smooth easing so it feels natural.
            let eased = cubicEaseOut(raw)

            let opacity = 1 - eased
            let scale = 1 - eased * (1 - minScale)

            // --- Performance-aware blur handling ---
            let overshoot = max(0, -relativeY) // points above the top threshold
            let blurRamp = min(1, overshoot / max(1, blurKickIn))
            let effectiveBlur = (eased * maxBlur) * blurRamp
            // --------------------------------------------

            let yOffset = eased * maxYOffset
            
            let animationDuration = settings.duration

            content
                .opacity(opacity)
                .scaleEffect(scale)
                .blur(radius: effectiveBlur)
                .offset(y: yOffset)
                .conditionalCompositingGroup(enabled: settings.shouldAnimate)
                .animation(.easeOut(duration: animationDuration), value: raw)
                .animation(.easeOut(duration: animationDuration), value: blurRamp)
        }
            }

    // Simple cubic ease-out to keep motion feeling natural
    private func cubicEaseOut(_ x: CGFloat) -> CGFloat {
        let inv = 1 - x
        return 1 - inv * inv * inv
    }
}

// MARK: - Helper Extensions

extension View {
    @ViewBuilder
    fileprivate func conditionalCompositingGroup(enabled: Bool) -> some View {
        if enabled {
            self.compositingGroup()
        } else {
            self
        }
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

    /// “Sink & vanish” effect as tiles approach the **top** of the viewport.
    /// `topInset` lets you start the effect under a floating header.
    /// The top-most visible tile is protected from blur at the threshold.
    func vanishIntoPage(
        vanishDistance: CGFloat = 260,
        minScale: CGFloat = 0.86,
        maxBlur: CGFloat = 3,
        maxYOffset: CGFloat = 6,
        topInset: CGFloat = 0,
        blurKickIn: CGFloat = 14
    ) -> some View {
        modifier(VanishIntoPage(vanishDistance: vanishDistance,
                                minScale: minScale,
                                maxBlur: maxBlur,
                                maxYOffset: maxYOffset,
                                topInset: topInset,
                                blurKickIn: blurKickIn))
    }
}

// MARK: - Previews

#Preview("Appear • Zero-arg") {
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

#Preview("Vanish Into Page (Top Only, no blur on top tile)") {
    ScrollView {
        VStack(spacing: 24) {
            ForEach(0..<16) { i in
                Text("Row \(i)")
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BrandSecondary").opacity(0.12))
                    )
                    // Adjust topInset if you have a floating header (e.g., 80).
                    // blurKickIn controls how far past the top before blur starts.
                    .vanishIntoPage(vanishDistance: 260,
                                    minScale: 0.88,
                                    maxBlur: 2.5,
                                    topInset: 0,
                                    blurKickIn: 14)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 24)
    }
}
