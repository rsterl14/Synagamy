//
//  BrandTile.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  A reusable “tile” that looks like a tappable card. It’s used across Home, Education,
//  Pathways, Resources, etc. This version:
//   • Keeps a consistent brand look using DesignSystem tokens.
//   • Adds safe press feedback without interfering with NavigationLink gestures.
//   • Avoids force-unwraps and fragile assumptions.
//   • Improves accessibility (labels, traits, dynamic type-friendly).
//
//  Usage
//  -----
//  BrandTile(title: "Education", subtitle: "Learn", systemIcon: "book.fill")
//  BrandTile(title: "Clinics", subtitle: "Find clinics", assetIcon: "ClinicLogo")
//
//  Notes
//  -----
//  • Provide either `systemIcon` (SF Symbol) or `assetIcon` (asset catalog name).
//    If both are provided, `assetIcon` wins by design.
//  • This view is only the visual tile; wrap it in a Button or NavigationLink externally.
//    That separation avoids “double-tap” gesture conflicts with NavigationStack.
//
//  Dependencies
//  ------------
//  • DesignSystem.swift (Brand colors, radii, spacing)
//

import SwiftUI

struct BrandTile: View {
    // MARK: - Inputs (non-optional for title to keep semantics clear)
    let title: String
    let subtitle: String?

    // Prefer one icon input. If both provided, assetIcon takes precedence.
    let systemIcon: String?
    let assetIcon: String?

    // Optional compact style if you want denser tiles in some lists.
    var isCompact: Bool = false

    // Internal press feedback (purely visual; safe with NavLink)
    @GestureState private var isPressed = false

    init(
        title: String,
        subtitle: String? = nil,
        systemIcon: String? = nil,
        assetIcon: String? = nil,
        isCompact: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.assetIcon = assetIcon
        self.isCompact = isCompact
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {

            // MARK: - Leading icon (asset first, otherwise SF Symbol, otherwise placeholder)
            iconView
                .frame(width: isCompact ? 40 : 48, height: isCompact ? 40 : 48)
                .background(
                    Circle()
                        .fill(Color("BrandPrimary").opacity(0.15))
                )
                .overlay(
                    Circle()
                        .stroke(Color("BrandPrimary").opacity(0.10), lineWidth: 1)
                )
                .accessibilityHidden(true)

            // MARK: - Text stack
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(isCompact ? .headline : .title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let subtitle, !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - Chevron affordance (non-interactive)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, isCompact ? 12 : 14)
        .padding(.vertical, isCompact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(isPressed ? 0.08 : 0.12), radius: isPressed ? 6 : 10, x: 0, y: isPressed ? 2 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .stroke(Color("BrandPrimary").opacity(isPressed ? 0.18 : 0.10), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    // MARK: - Derived views

    @ViewBuilder
    private var iconView: some View {
        if let asset = assetIcon, !asset.isEmpty, UIImage(named: asset) != nil {
            // Asset icon (renders the provided image if it exists in the asset catalog)
            Image(asset)
                .resizable()
                .scaledToFit()
                .padding(8)
        } else if let symbol = systemIcon, !symbol.isEmpty {
            // SF Symbol fallback
            Image(systemName: symbol)
                .font(.system(size: isCompact ? 18 : 22, weight: .semibold))
                .foregroundColor(Color("BrandPrimary"))
        } else {
            // Minimal placeholder to keep layout consistent if no icon provided
            Image(systemName: "square.grid.2x2")
                .font(.system(size: isCompact ? 18 : 22, weight: .semibold))
                .foregroundColor(Color("BrandPrimary"))
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        if let subtitle, !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(title). \(subtitle)."
        }
        return title
    }
}

// MARK: - Previews

#Preview("Standard") {
    VStack(spacing: 12) {
        BrandTile(title: "Education", subtitle: "Learn", systemIcon: "book.fill")
        BrandTile(title: "Pathways", subtitle: "Explore options", systemIcon: "map.fill")
        BrandTile(title: "Clinics", subtitle: "Find clinics", assetIcon: "ClinicLogo")
        BrandTile(title: "Resources", subtitle: "Guides & Tools", systemIcon: "doc.text.fill")
    }
    .padding()
}

#Preview("Compact") {
    VStack(spacing: 8) {
        BrandTile(title: "IUI (partner sperm)", subtitle: "Overview", systemIcon: "stethoscope", isCompact: true)
        BrandTile(title: "IVF", subtitle: "Step-by-step", systemIcon: "testtube.2", isCompact: true)
    }
    .padding()
}
