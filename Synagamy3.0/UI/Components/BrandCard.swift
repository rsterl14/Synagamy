//
//  BrandCard.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  A lightweight container that renders content inside a branded “card” surface.
//  Used across detail screens and sheets (e.g., Topic details, Resource descriptions).
//
//  What’s improved
//  ---------------
//  • Consistent padding, corner radius, and subtle strokes/shadows per Brand tokens.
//  • Dynamic Type–friendly; no hard-coded font sizes here (content decides).
//  • Accessibility-friendly (treats the card as a single group by default).
//  • No force-unwraps or fragile assumptions.
//  • Optional header row (icon + title) to keep common patterns DRY.
//
//  Usage
//  -----
//  BrandCard {
//     Text("Body content here")
//  }
//
//  BrandCard(title: "Section", systemIcon: "book.fill") {
//     Text("Body content here")
//  }
//
//  BrandCard(title: "Education", assetIcon: "EducationLogo") {
//     TopicDetailContent(topic: t)
//  }
//

import SwiftUI

struct BrandCard<Content: View>: View {
    // MARK: - Optional header
    var title: String?
    var systemIcon: String?      // SF Symbol (used if assetIcon is nil)
    var assetIcon: String?       // Asset catalog image name

    // MARK: - Layout tokens (aligned with the DesignSystem)
    var cornerRadius: CGFloat
    var verticalPadding: CGFloat
    var horizontalPadding: CGFloat

    // MARK: - Content
    @ViewBuilder var content: () -> Content

    // MARK: - Designated initializer (inside the struct to suppress synthesized memberwise init)
    init(
        title: String? = nil,
        systemIcon: String? = nil,
        assetIcon: String? = nil,
        cornerRadius: CGFloat = Brand.Radius.lg,
        verticalPadding: CGFloat = 14,
        horizontalPadding: CGFloat = 14,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemIcon = systemIcon
        self.assetIcon = assetIcon
        self.cornerRadius = cornerRadius
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Optional header
            if hasHeader {
                HStack(spacing: 10) {
                    headerIcon
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Brand.ColorToken.primary.opacity(0.12)))
                        .overlay(Circle().stroke(Brand.ColorToken.primary.opacity(0.10), lineWidth: 1))
                        .accessibilityHidden(true)

                    if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Brand.ColorToken.primary)
                            .accessibilityAddTraits(.isHeader)
                    }

                    Spacer(minLength: 0)
                }
            }

            // Caller-provided content
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    // MARK: - Computed

    private var hasHeader: Bool {
        (title?.isEmpty == false) || (systemIcon?.isEmpty == false) || (assetIcon?.isEmpty == false)
    }

    @ViewBuilder
    private var headerIcon: some View {
        // Prefer asset if available; otherwise SF Symbol; otherwise minimal placeholder.
        if let asset = assetIcon, !asset.isEmpty, UIImage(named: asset) != nil {
            Image(asset).resizable().scaledToFit().padding(6)
        } else if let symbol = systemIcon, !symbol.isEmpty {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Brand.ColorToken.primary)
        } else {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Brand.ColorToken.primary)
        }
    }

    private var accessibilitySummary: String {
        if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        return "Card"
    }
}

// MARK: - Previews (unique labels)

#Preview("BrandCard • Basic") {
    BrandCard {
        Text("This is a basic card body. It grows with content and respects Dynamic Type.")
        Text("Secondary line with more details.")
            .foregroundStyle(.secondary)
            .font(.footnote)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("BrandCard • With Header (SF Symbol)") {
    BrandCard(title: "Section Title", systemIcon: "book.fill") {
        VStack(alignment: .leading, spacing: 8) {
            Text("Body copy goes here.")
            Text("Additional details…").foregroundStyle(.secondary).font(.footnote)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("BrandCard • With Header (Asset)") {
    BrandCard(title: "Education", assetIcon: "EducationLogo") {
        Text("Asset-based header icon example.")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
