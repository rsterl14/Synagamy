//
//  ResourceHeroCard.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  Displays a large, attention-grabbing card for featured resources (e.g., funding programs,
//  special guides). Used in ResourcesView or as a promo tile.
//
//  Improvements
//  ------------
//  • Graceful image fallback (uses SF Symbol if asset missing).
//  • Clear tap target + haptic feedback.
//  • Accessible (VoiceOver reads title + subtitle + action).
//  • Brand-consistent shadows, radii, and color tokens.
//
//  Prereqs
//  -------
//  • Brand.swift (DesignSystem), BrandCard.swift
//

import SwiftUI

struct ResourceHeroCard: View {
    let title: String
    let subtitle: String
    let systemIcon: String?
    let assetIcon: String?
    let actionTitle: String
    let action: () -> Void

    // Style tokens
    var cornerRadius: CGFloat = Brand.Radius.lg
    var iconSize: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // MARK: - Icon
                iconView
                    .frame(width: iconSize, height: iconSize)
                    .background(
                        Circle().fill(Brand.ColorToken.primary.opacity(0.12))
                    )
                    .overlay(
                        Circle().stroke(Brand.ColorToken.primary.opacity(0.10), lineWidth: 1)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            // MARK: - Action button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            }) {
                Text(actionTitle)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Brand.ColorToken.primary)
            .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous))
            .accessibilityLabel(Text("\(actionTitle). Opens resource \(title)"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Icon Builder
    @ViewBuilder
    private var iconView: some View {
        if let asset = assetIcon, !asset.isEmpty, UIImage(named: asset) != nil {
            Image(asset)
                .resizable()
                .scaledToFit()
                .padding(8)
        } else if let symbol = systemIcon {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Brand.ColorToken.primary)
        } else {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Brand.ColorToken.primary)
        }
    }
}

// MARK: - Previews

#Preview("ResourceHeroCard Demo") {
    VStack(spacing: 20) {
        ResourceHeroCard(
            title: "Fertility Funding Program",
            subtitle: "Learn about grants and subsidies available in your province.",
            systemIcon: "heart.text.square",
            assetIcon: nil,
            actionTitle: "Learn More",
            action: {}
        )

        ResourceHeroCard(
            title: "Patient Support Guide",
            subtitle: "Step-by-step guide for navigating fertility treatment.",
            systemIcon: nil,
            assetIcon: "EducationLogo", // falls back gracefully if missing
            actionTitle: "Open Guide",
            action: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
