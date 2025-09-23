//
//  OnChangeHeightModifier.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  A tiny helper that updates a bound CGFloat whenever a measured height changes.
//  Used with GeometryReader behind floating headers so parents can reserve the
//  *actual* space with `.safeAreaInset(edge: .top)`.
//
//  Why not use onChange(of:)? Because we often compute height inline from a
//  GeometryReader value (not a @State). This modifier compares and updates the
//  bound value without causing extra layout passes.
//
//  Usage
//  -----
//  .overlay(alignment: .top) {
//      FloatingLogoHeader(...)
//          .background(
//              GeometryReader { geo in
//                  Color.clear
//                      .onAppear { headerHeight = geo.size.height } // initial sync
//                      .modifier(
//                          OnChangeHeightModifier(
//                              currentHeight: $headerHeight,
//                              height: geo.size.height
//                          )
//                      )
//              }
//          )
//  }
//

import SwiftUI

struct OnChangeHeightModifier: ViewModifier {
    /// The parent-owned height that should stay in sync with the measured height.
    @Binding var currentHeight: CGFloat
    /// The newly measured height (typically `geo.size.height` from a GeometryReader).
    let height: CGFloat
    /// Optional tolerance to avoid micro-churn from sub-pixel changes.
    var epsilon: CGFloat = 0.5

    func body(content: Content) -> some View {
        content
            .task {
                updateIfNeeded()
            }
            .onChange(of: height) { _, _ in
                updateIfNeeded()
            }
    }

    // MARK: - Private

    private func updateIfNeeded() {
        // Only update when the new height differs by more than epsilon;
        // this avoids infinite layout loops and unnecessary animations.
        guard abs(currentHeight - height) > epsilon else { return }
        currentHeight = height
    }
}

// MARK: - Convenience extension

extension View {
    /// Synchronize a `@State`/`@Binding` height with a measured one,
    /// avoiding tiny “chatter” via a small epsilon comparison.
    func onChangeHeight(
        _ currentHeight: Binding<CGFloat>,
        to height: CGFloat,
        epsilon: CGFloat = 0.5
    ) -> some View {
        self.modifier(OnChangeHeightModifier(currentHeight: currentHeight, height: height, epsilon: epsilon))
    }
}

// MARK: - Preview

#Preview("OnChangeHeightModifier Demo") {
    StatefulHeightDemo()
}

// A small self-contained demo: the top rectangle’s height changes with Dynamic Type.
private struct StatefulHeightDemo: View {
    @State private var measured: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            // The bar whose height we measure
            Text("Resizable Header")
                .font(.title2.bold())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    GeometryReader { geo in
                        Brand.Color.primary.opacity(0.12)
                            .onAppear { measured = geo.size.height }
                            .modifier(OnChangeHeightModifier(currentHeight: $measured,
                                                             height: geo.size.height))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Measured height: \(Int(measured)) pt")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
