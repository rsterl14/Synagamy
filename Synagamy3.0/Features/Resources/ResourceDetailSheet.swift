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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Enhanced header matching TopicDetailContent style
                    VStack(alignment: .leading, spacing: 12) {
                        // Category badge
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .font(.caption2)
                            
                            Text("RESOURCE")
                                .font(.caption2.weight(.bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(Brand.ColorSystem.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Brand.ColorSystem.primary.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Main title
                        Text(resource.title)
                            .font(.largeTitle.bold())
                            .foregroundColor(Brand.ColorSystem.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        
                        // Subtitle
                        HStack(spacing: 8) {
                            Image(systemName: resource.systemImage)
                                .font(.body)
                                .foregroundColor(Brand.ColorSystem.secondary)
                            
                            Text(resource.subtitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Brand.ColorSystem.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Divider
                    Rectangle()
                        .fill(Brand.ColorSystem.primary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.bottom, 4)

                    // MARK: - Description with enhanced design
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.body)
                                .foregroundColor(Brand.ColorSystem.primary)
                            
                            Text("About This Resource")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Brand.ColorSystem.primary)
                        }
                        
                        Text(resource.description)
                            .font(.callout)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Brand.ColorToken.hairline, lineWidth: 1)
                                    )
                            )
                    }

                    // MARK: - Enhanced Actions
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.body)
                                .foregroundColor(Brand.ColorSystem.primary)
                            
                            Text("Actions")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Brand.ColorSystem.primary)
                        }
                        
                        VStack(spacing: 12) {
                            // Open inside the app (SFSafariViewController)
                            Button {
                                showSafari = true
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Open in App")
                                        .font(.subheadline.weight(.medium))
                                    Image(systemName: "safari")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Brand.ColorSystem.primary)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the website in an in-app browser.")

                            // Open in external Safari
                            Button {
                                openURL(resource.url) { accepted in
                                    if !accepted {
                                        errorMessage = "Couldn't open the link. Please try again."
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Open in Safari")
                                        .font(.subheadline.weight(.medium))
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.subheadline)
                                }
                                .foregroundColor(Brand.ColorSystem.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Brand.ColorSystem.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(Brand.ColorSystem.primary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)

                            // Native share sheet
                            ShareLink(item: resource.url) {
                                HStack(spacing: 8) {
                                    Text("Share")
                                        .font(.subheadline.weight(.medium))
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline)
                                }
                                .foregroundColor(Brand.ColorSystem.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Brand.ColorSystem.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(Brand.ColorSystem.primary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the system share sheet for this link.")
                        }
                    }
                }
                .padding()
            }
        }
        .tint(Color("BrandPrimary"))

        // MARK: - In-app Safari
        .sheet(isPresented: $showSafari) {
            WebSafariView(url: resource.url)   // SFSafariViewController under the hood
                .ignoresSafeArea()
        }

        // MARK: - Friendly, non-technical error alert
        .alert("Something went wrong",
               isPresented: .constant(errorMessage != nil),
               actions: {
                    Button("OK", role: .cancel) { errorMessage = nil }
               },
               message: {
                    Text(errorMessage ?? "Please try again.")
               })
    }
}
