//
//  InfertilityView.swift
//  Synagamy3.0
//
//  Intro “Starting Point” screen: simple tiles that open short summaries in a sheet.
//  This refactor:
//   • Uses the shared OnChangeHeightModifier (no local duplicates).
//   • Adds friendly empty-state handling (if items ever become empty).
//   • Adds non-technical alert plumbing for recoverable issues.
//   • Improves accessibility labels and avoids force-unwraps.
//
//  Prereqs:
//   • UI/Modifiers/OnChangeHeightModifier.swift
//   • UI/Components/{BrandTile,BrandCard,HomeButton,FloatingLogoHeader,EmptyStateView}.swift
//

import SwiftUI

struct InfertilityView: View {
    // MARK: - Lightweight model for the intro tiles
    struct InfoItem: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemIcon: String
        let description: String
    }

    // MARK: - Content (static for now; could move to JSON later)
    private let topics: [InfoItem] = [
        .init(
            title: "What is Infertility?",
            subtitle: "Definition & overview",
            systemIcon: "person.2.slash",
            description: "Infertility means not being able to get pregnant after a year of trying (or six months if over 35). It can be due to egg, sperm, uterus, hormone, or unexplained factors."
        ),
        .init(
            title: "Infertility Treatment Options",
            subtitle: "Ways to help achieve pregnancy",
            systemIcon: "stethoscope",
            description: "Options include medications to stimulate ovulation, intrauterine insemination (IUI), in vitro fertilization (IVF), use of donor eggs or sperm, and gestational surrogacy."
        ),
        .init(
            title: "What is Fertility Preservation?",
            subtitle: "Keeping eggs, sperm, or embryos for future use",
            systemIcon: "snowflake",
            description: "Fertility preservation means saving reproductive cells or tissue so you can try for a pregnancy later. Often used before cancer treatment, surgery, or with age-related decline."
        ),
        .init(
            title: "Fertility Preservation Options",
            subtitle: "For men and women",
            systemIcon: "tray.and.arrow.down.fill",
            description: "Options include egg freezing, embryo freezing, sperm freezing, and ovarian/testicular tissue freezing. The right choice depends on age, health, and personal plans."
        )
    ]

    // MARK: - UI state
    @State private var selectedTopic: InfoItem? = nil   // drives the details sheet
    @State private var errorMessage: String? = nil      // user-friendly alert text

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "StartingPointLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if topics.isEmpty {
                    EmptyStateView(
                        icon: "info.circle",
                        title: "No info available",
                        message: "Please check back later or explore Education topics."
                    )
                    .padding(.top, 8)
                } else {
                    LazyVStack(spacing: Brand.Spacing.xl) {
                        ForEach(topics) { item in
                            Button {
                                selectedTopic = item
                            } label: {
                                BrandTile(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    systemIcon: item.systemIcon,
                                    assetIcon: nil,
                                    isCompact: true
                                )
                            }
                            .buttonStyle(BrandTileButtonStyle())
                            .accessibilityLabel(Text("\(item.title). \(item.subtitle). Tap to read more."))
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }

        // Friendly, non-technical alert for recoverable issues
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Detail sheet (styled like TopicDetailContent)
        .sheet(item: $selectedTopic) { topic in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and subtitle header matching TopicDetailContent
                    VStack(alignment: .leading, spacing: 12) {
                        // Category badge
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                            
                            Text(topic.subtitle.uppercased())
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
                        
                        // Main title with gradient
                        Text(topic.title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Brand.ColorSystem.primary, Brand.ColorSystem.primary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 4)
                    
                    // Divider
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Brand.ColorSystem.primary.opacity(0.3), Brand.ColorSystem.primary.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 1)
                        .padding(.bottom, 4)
                    
                    // Main content with enhanced design matching TopicDetailContent
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.body)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Overview")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Brand.ColorSystem.primary)
                        }
                        
                        Text(topic.description)
                            .font(.callout)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [Brand.ColorToken.hairline, Brand.ColorToken.hairline.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                }
                .padding()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
