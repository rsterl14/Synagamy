//
//  CommunityView.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  Community support section where users can access peer support resources,
//  support groups, and community-driven content. This view will eventually include:
//   • Moderated discussion forums for different fertility journey stages
//   • Local support group directories and meetup information
//   • Peer success story sharing (with privacy protections)
//   • Links to verified community resources and helplines
//
//  App Store Compliance
//  -------------------
//  • Content moderation for user safety and appropriate discussion
//  • Privacy protection for sensitive personal health information
//  • Clear community guidelines and reporting mechanisms
//  • Professional moderation to ensure supportive environment
//  • Compliance with health information privacy regulations
//
//  UI Features
//  -----------
//  • Consistent floating logo header with community branding
//  • Accessible navigation for all user types
//  • Safe browsing with content warnings where appropriate
//  • Offline-friendly for core community resource access
//  • Clear calls-to-action for immediate support needs
//

import SwiftUI

struct CommunityView: View {
    // MARK: - UI State
    @State private var errorMessage: String? = nil
    @State private var showComingSoon = true
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: nil,
            showHomeButton: true,
            usePopToRoot: true
        ) {
            if showComingSoon {
                // Placeholder content with helpful community resources
                VStack(spacing: 24) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color("BrandPrimary"))
                        .padding()
                        .background(
                            Circle()
                                .fill(Color("BrandPrimary").opacity(0.15))
                        )
                    
                    VStack(spacing: 12) {
                        Text("Community Support")
                            .font(.title2.bold())
                            .foregroundColor(Color("BrandSecondary"))
                        
                        Text("Coming Soon")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("This section will connect you with peer support, local groups, and a moderated community forum for sharing experiences and encouragement.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    // Immediate support resources
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "heart.circle")
                                .foregroundColor(Color("BrandPrimary"))
                            Text("Need Support Now?")
                                .font(.headline)
                                .foregroundColor(Color("BrandPrimary"))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            SupportLinkRow(
                                title: "Fertility Matters Canada",
                                subtitle: "National support organization",
                                url: "https://fertilitymatters.ca/support/"
                            )
                            
                            SupportLinkRow(
                                title: "Crisis Text Line",
                                subtitle: "Text HOME to 686868",
                                url: nil
                            )
                            
                            SupportLinkRow(
                                title: "Mental Health Support",
                                subtitle: "Find counsellors and groups",
                                url: "https://fertilitymatters.ca/support/find/"
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BrandPrimary").opacity(0.08))
                    )
                    
                    // Privacy notice
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(Color("BrandSecondary"))
                            Text("Privacy & Safety")
                                .font(.footnote.bold())
                                .foregroundColor(Color("BrandSecondary"))
                        }
                        
                        Text("When our community features launch, your privacy and safety will be our top priority. All discussions will be moderated, and personal health information will be protected.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BrandSecondary").opacity(0.08))
                    )
                }
                .padding(.vertical, 24)
            }
        }
        
        // MARK: - Error handling
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })
    }
}

// MARK: - Support Link Component
private struct SupportLinkRow: View {
    let title: String
    let subtitle: String
    let url: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if url != nil {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let urlString = url, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
        .accessibilityLabel(Text("\(title). \(subtitle)."))
        .accessibilityAddTraits(url != nil ? .isButton : [])
    }
}

