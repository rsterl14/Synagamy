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
        Group {
            if isCompact {
                // Compact layout: HStack with icon on left, content on right
                HStack(alignment: .center, spacing: 12) {
                    // Icon on the left
                    iconView
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Brand.ColorToken.primary.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(Brand.ColorToken.primary.opacity(0.25), lineWidth: 1)
                        )
                    
                    // Content on the right
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        if let subtitle, !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(Brand.ColorToken.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Brand.ColorToken.surface)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Brand.ColorToken.primary.opacity(0.15), lineWidth: 1)
                )
            } else {
                // Regular layout: VStack with icon at top, text below
                VStack(spacing: 20) {
                    
                    // MARK: - Icon at the top
                    iconView
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(Brand.ColorToken.primary.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(Brand.ColorToken.primary.opacity(0.25), lineWidth: 2)
                        )

                    // MARK: - Text content
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)

                        if let subtitle, !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(subtitle)
                                .font(.headline)
                                .foregroundStyle(Brand.ColorToken.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(35)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 240)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Brand.ColorToken.surface)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Brand.ColorToken.primary.opacity(0.2), lineWidth: 2)
                )
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    // MARK: - Derived views

    @ViewBuilder
    private var iconView: some View {
        if let asset = assetIcon, !asset.isEmpty {
            Image(asset)
                .resizable()
                .scaledToFit()
                .padding(isCompact ? 4 : 16)
        } else if let symbol = systemIcon, !symbol.isEmpty {
            // SF Symbol fallback
            Image(systemName: symbol)
                .font(.system(size: isCompact ? 16 : 40, weight: .semibold))
                .foregroundColor(Brand.ColorToken.primary)
                .symbolRenderingMode(.hierarchical)
        } else {
            // Minimal placeholder to keep layout consistent if no icon provided
            Image(systemName: "square.grid.2x2")
                .font(.system(size: isCompact ? 16 : 40, weight: .semibold))
                .foregroundColor(Brand.ColorToken.primary)
                .symbolRenderingMode(.hierarchical)
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
