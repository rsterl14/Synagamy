//
//  ResourceDetailSheet.swift
//  Synagamy3.0
//
//  Bottom sheet that shows a single Resource with actions to open or share.
//  – Opens in-app (SFSafariView) or externally (Safari).
//  – Uses completion-form of openURL() which returns Bool ("accepted").
//  – Shows friendly, non-technical error alerts.
//  – Avoids force-unwraps.
//

import SwiftUI

struct ResourceDetailSheet: View {
    // MARK: - Input
    let resource: Resource

    // MARK: - Environment & State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL            // for external Safari
    @State private var showSafari = false                  // toggles in-app Safari sheet
    @State private var errorMessage: String? = nil         // user-facing error text
    @State private var showingErrorAlert = false           // controls error alert presentation

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Spacing.lg) {

                    // MARK: - Enhanced header matching TopicDetailContent style
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        // Category badge
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .font(.caption2)
                            
                            Text("RESOURCE")
                                .font(Brand.Typography.labelSmall)
                                .tracking(0.5)
                        }
                        .foregroundColor(Brand.Color.primary)
                        .padding(.horizontal, Brand.Spacing.sm)
                        .padding(.vertical, Brand.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Brand.Color.primary.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Brand.Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Main title
                        Text(resource.title)
                            .font(Brand.Typography.headlineMedium)
                            .foregroundColor(Brand.Color.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        
                        // Subtitle
                        HStack(spacing: Brand.Spacing.sm) {
                            Image(systemName: resource.systemImage)
                                .font(.body)
                                .foregroundColor(Brand.Color.secondary)
                            
                            Text(resource.subtitle)
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.Color.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, Brand.Spacing.xs)
                    
                    // Divider
                    Rectangle()
                        .fill(Brand.Color.primary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.bottom, Brand.Spacing.xs)

                    // MARK: - Description with enhanced design
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        HStack(spacing: Brand.Spacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .font(.body)
                                .foregroundColor(Brand.Color.primary)
                            
                            Text("About This Resource")
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.Color.primary)
                        }
                        
                        Text(resource.description)
                            .font(Brand.Typography.bodySmall)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .padding(Brand.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                                            .strokeBorder(Brand.Color.hairline, lineWidth: 1)
                                    )
                            )
                    }

                    // MARK: - Enhanced Actions
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        HStack(spacing: Brand.Spacing.sm) {
                            Image(systemName: "hand.tap.fill")
                                .font(.body)
                                .foregroundColor(Brand.Color.primary)
                            
                            Text("Actions")
                                .font(Brand.Typography.labelLarge)
                                .foregroundColor(Brand.Color.primary)
                        }
                        
                        VStack(spacing: Brand.Spacing.md) {
                            // Open inside the app (SFSafariViewController)
                            Button {
                                showSafari = true
                            } label: {
                                HStack(spacing: Brand.Spacing.sm) {
                                    Text("Open in App")
                                        .font(Brand.Typography.labelMedium)
                                    Image(systemName: "safari")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Brand.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                        .fill(Brand.Color.primary)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the website in an in-app browser.")

                            // Open in external Safari
                            Button {
                                openURL(resource.url) { accepted in
                                    if !accepted {
                                        errorMessage = "Couldn't open the link. Please try again."
                                        showingErrorAlert = true
                                    }
                                }
                            } label: {
                                HStack(spacing: Brand.Spacing.sm) {
                                    Text("Open in Safari")
                                        .font(Brand.Typography.labelMedium)
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.subheadline)
                                }
                                .foregroundColor(Brand.Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Brand.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                        .fill(Brand.Color.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                                .strokeBorder(Brand.Color.primary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)

                            // Native share sheet
                            ShareLink(item: resource.url) {
                                HStack(spacing: Brand.Spacing.sm) {
                                    Text("Share")
                                        .font(Brand.Typography.labelMedium)
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline)
                                }
                                .foregroundColor(Brand.Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Brand.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                        .fill(Brand.Color.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                                .strokeBorder(Brand.Color.primary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the system share sheet for this link.")
                        }
                    }
                }
                .padding(Brand.Spacing.lg)
            }
        }
        .tint(Brand.Color.primary)

        // MARK: - In-app Safari
        .sheet(isPresented: $showSafari) {
            WebSafariView(url: resource.url)   // SFSafariViewController under the hood
                .ignoresSafeArea()
        }

        // MARK: - Friendly, non-technical error alert
        .alert("Something went wrong",
               isPresented: $showingErrorAlert,
               actions: {
                    Button("OK", role: .cancel) { showingErrorAlert = false; errorMessage = nil }
               },
               message: {
                    Text(errorMessage ?? "Please try again.")
               })
    }
}
