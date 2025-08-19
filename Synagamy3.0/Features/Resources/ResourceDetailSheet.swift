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
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - Hero header (title + subtitle + icon)
                    BrandCard {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: resource.systemImage)
                                .font(.system(size: 28, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color("BrandPrimary").opacity(0.15)))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(resource.title)
                                    .font(.title2.bold())
                                    .foregroundColor(Color("BrandPrimary"))
                                    .accessibilityAddTraits(.isHeader)
                                Text(resource.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }

                    // MARK: - Description
                    BrandCard {
                        Text(resource.description)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // MARK: - Actions
                    VStack(spacing: 12) {
                        // Open inside the app (SFSafariViewController)
                        Button {
                            showSafari = true
                        } label: {
                            Label("Open in App", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("BrandPrimary"))
                        .accessibilityHint("Opens the website in an in-app browser.")

                        // Open in external Safari (completion gives Bool)
                        Button {
                            openURL(resource.url) { accepted in
                                if !accepted {
                                    errorMessage = "Couldn’t open the link. Please try again."
                                }
                            }
                        } label: {
                            Label("Open in Safari", systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        // Native share sheet
                        ShareLink(item: resource.url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Opens the system share sheet for this link.")
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Resource")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(Color("BrandPrimary"))
                    .accessibilityLabel("Close")
                }
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
