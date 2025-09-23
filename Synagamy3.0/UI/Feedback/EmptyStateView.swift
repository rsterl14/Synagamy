//
//  EmptyStateView.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  Reusable “friendly blank state” used when lists are empty, searches have no matches,
//  or content fails to load. Keeps copy non-technical (App Store–friendly).
//
//  Highlights
//  ----------
//  • Accepts either an SF Symbol or an asset image (with graceful fallback).
//  • Uses Brand tokens for a cohesive look, supports Dynamic Type, and is accessible.
//  • Optional action button for a suggested next step (retry, clear search, etc.).
//

import SwiftUI

struct EmptyStateView: View {
    // MARK: - Inputs

    /// Main icon. If `assetImage` is provided and found, it takes precedence over the SF Symbol.
    let icon: String
    let title: String
    let message: String

    /// Optional asset image name (PNG/PDF in catalog). If not found, we fall back to `icon`.
    var assetImage: String? = nil

    /// Optional action (e.g., “Retry” or “Clear Search”).
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    /// Layout/style knobs (sane defaults)
    var topPadding: CGFloat = 24
    var horizontalPadding: CGFloat = 16
    var cornerRadius: CGFloat = Brand.Radius.lg

    var body: some View {
        VStack(spacing: 14) {
            // MARK: - Icon
            iconView
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Brand.Color.primary.opacity(0.10))
                )
                .overlay(
                    Circle().stroke(Brand.Color.primary.opacity(0.12), lineWidth: 1)
                )
                .accessibilityHidden(true)

            // MARK: - Title
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // MARK: - Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // MARK: - Optional action
            if let actionTitle, let action {
                Button(actionTitle, action: {
                    // Gentle haptic to signal the tap; safe for App Store.
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    action()
                })
                .buttonStyle(.bordered)
                .tint(Brand.Color.primary)
                .padding(.top, 6)
                .accessibilityHint(Text("Performs a helpful action for this screen."))
            }
        }
        .padding(.top, topPadding)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Brand.Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title). \(message)"))
    }

    // MARK: - Icon builder

    @ViewBuilder
    private var iconView: some View {
        if let asset = assetImage, !asset.isEmpty, UIImage(named: asset) != nil {
            Image(asset)
                .resizable()
                .scaledToFit()
                .padding(10)
        } else {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(Brand.Color.primary)
        }
    }
}

// MARK: - Previews

#Preview("Basic") {
    EmptyStateView(
        icon: "doc.text.magnifyingglass",
        title: "No resources available",
        message: "Please check back later. You can still explore Education and Pathways."
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("With Action") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No matches",
        message: "Try different keywords or clear the search.",
        actionTitle: "Clear Search",
        action: { /* no-op */ }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
