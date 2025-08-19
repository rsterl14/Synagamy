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
    @State private var headerHeight: CGFloat = 64       // reserved space for floating header
    @State private var errorMessage: String? = nil      // user-friendly alert text

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if topics.isEmpty {
                    // Friendly empty-state instead of a blank screen
                    EmptyStateView(
                        icon: "info.circle",
                        title: "No info available",
                        message: "Please check back later or explore Education topics."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 75) {
                        ForEach(topics) { item in
                            Button {
                                selectedTopic = item // safe state update to present sheet
                            } label: {
                                BrandTile(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    systemIcon: item.systemIcon,
                                    assetIcon: nil
                                )
                                .vanishIntoPage(vanishDistance: 350,
                                                minScale: 0.88,
                                                maxBlur: 2.5,
                                                topInset: 0,
                                                blurKickIn: 14)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .accessibilityLabel(Text("\(item.title). \(item.subtitle). Tap to read more."))
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }
        // MARK: - Global nav style and Home button
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { HomeButton() }
        }

        // Reserve space equal to the floating header height
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: headerHeight)
        }

        // Floating header overlay + dynamic height sync via shared modifier
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "StartingPointLogo")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { headerHeight = geo.size.height } // initial value
                            .modifier(
                                OnChangeHeightModifier(                 // keep synced on rotation, etc.
                                    currentHeight: $headerHeight,
                                    height: geo.size.height
                                )
                            )
                    }
                )
        }

        // Friendly, non-technical alert for recoverable issues
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Detail sheet (short, readable summary)
        .sheet(item: $selectedTopic) { topic in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(topic.title)
                        .font(.title2.bold())
                        .foregroundColor(Color("BrandPrimary"))
                    Text(topic.description)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
