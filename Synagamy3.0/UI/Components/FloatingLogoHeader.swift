//
//  FloatingLogoHeader.swift
//  Synagamy3.0
//

import SwiftUI

struct FloatingLogoHeader: View {
    /// Primary brand asset name (must exist in Assets.xcassets).
    let primaryImage: String
    /// Optional secondary asset name (renders only if found).
    let secondaryImage: String?

    // Layout
    var height: CGFloat = 200
    var spacing: CGFloat = 12

    var body: some View {
        HStack(spacing: spacing) {
            assetImage(named: primaryImage)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .accessibilityLabel(Text("Synagamy"))

            if let secondary = secondaryImage,
               UIImage(named: secondary) != nil {
                assetImage(named: secondary)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.clear)
    }

    // MARK: - Helpers

    /// Returns an `Image` from assets if present; otherwise a safe SF Symbol fallback.
    private func assetImage(named name: String) -> Image {
        if UIImage(named: name) != nil {
            return Image(name)                // asset-backed image (supports .resizable())
        } else {
            return Image(systemName: "photo") // fallback (also supports .resizable())
        }
    }
}

#Preview("FloatingLogoHeader • Demo") {
    VStack {
        FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "EducationLogo")
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
