//
//  ResourcesView.swift
//  Synagamy3.0
//
//  Curated Canada-focused resources with a floating header and detail sheet.
//  This refactor:
//   • Uses the shared OnChangeHeightModifier (no file-local duplicates).
//   • Adds friendly empty-state handling if the list is ever empty.
//   • Improves a11y labels and avoids force-unwrap pitfalls.
//   • Keeps sheet presentation safe (no crashes on odd state).
//
//  Prereqs:
//   • UI/Modifiers/OnChangeHeightModifier.swift
//   • UI/Components/{BrandTile,BrandCard,EmptyStateView,HomeButton,FloatingLogoHeader}.swift
//   • Features/Resources/ResourceDetailSheet.swift
//

import SwiftUI

struct ResourcesView: View {
    // MARK: - UI state
    @State private var selectedResource: Resource? = nil   // drives the detail sheet
    @State private var headerHeight: CGFloat = 64          // reserved for floating header
    @State private var errorMessage: String? = nil         // user-facing alert text

    // MARK: - Static (curated) resources
    // If you later move these to JSON, keep the same shape and render logic.
    private let resources: [Resource] = [
        Resource(
            title: "CFAS",
            subtitle: "Canadian Fertility & Andrology Society",
            description: "Canada’s professional society for reproductive medicine. Publishes guidance statements, hosts the annual conference, and supports practice standards, education, and research across clinics and labs.",
            url: URL(string: "https://cfas.ca")!,
            systemImage: "person.2.wave.2"
        ),
        Resource(
            title: "Fertility Matters Canada",
            subtitle: "Patient education & support",
            description: "National patient organization offering evidence-based information, peer support, advocacy, webinars, and community resources for those facing infertility.",
            url: URL(string: "https://fertilitymatters.ca")!,
            systemImage: "heart.text.square"
        ),
        Resource(
            title: "CARTR-BORN Stats",
            subtitle: "National IVF outcomes (BORN Ontario)",
            description: "Public reporting portal summarizing assisted reproduction activity and outcomes contributed by Canadian clinics to CARTR-BORN. Useful for understanding trends at a national level.",
            url: URL(string: "https://www.bornontario.ca/en/about-born/data-and-reports/cartr-born.aspx")!,
            systemImage: "chart.bar.doc.horizontal"
        ),
        Resource(
            title: "Health Canada – AHR",
            subtitle: "Regulations & safety notices",
            description: "Assisted Human Reproduction (AHR) regulatory information, including safety of sperm/egg/embryo handling, inspections, guidance documents, and compliance updates.",
            url: URL(string: "https://www.canada.ca/en/health-canada/services/drugs-health-products/assisted-human-reproduction.html")!,
            systemImage: "checkmark.shield"
        ),
        Resource(
            title: "SOGC",
            subtitle: "Clinical guidelines & statements",
            description: "Society of Obstetricians and Gynaecologists of Canada. Access clinical practice guidelines, committee opinions, and patient resources related to reproductive health.",
            url: URL(string: "https://sogc.org")!,
            systemImage: "doc.text.magnifyingglass"
        ),
        Resource(
            title: "Fertility Funding by Province",
            subtitle: "Government & insurance support",
            description: "Overview of provincial programs, employer benefits, drug coverage and tax credits that can help pay for fertility treatment in Canada.",
            url: URL(string: "https://fertilitymatters.ca/learn/funding/")!,
            systemImage: "creditcard"
        ),
        Resource(
            title: "Find Support & Professionals",
            subtitle: "Counsellors, clinics, legal & groups",
            description: "Directory from Fertility Matters Canada to find mental health providers, support groups, clinics, legal help, and more.",
            url: URL(string: "https://fertilitymatters.ca/support/find/")!,
            systemImage: "person.3.sequence"
        ),
        Resource(
            title: "Canadian Cancer Society",
            subtitle: "Fertility & cancer side effects",
            description: "Evidence-based info on how cancer treatments affect fertility and options for preservation before therapy.",
            url: URL(string: "https://cancer.ca/en/treatments/side-effects/fertility-problems")!,
            systemImage: "bandage"
        ),
        Resource(
            title: "Young Adult Cancer Canada",
            subtitle: "Oncofertility resources & stories",
            description: "Articles and lived experiences focused on fertility issues for adolescents and young adults with cancer.",
            url: URL(string: "https://youngadultcancer.ca/tag/fertility/")!,
            systemImage: "figure.2.and.child.holdinghands"
        ),
        Resource(
            title: "MyFertilityChoices",
            subtitle: "Options & preservation primer",
            description: "Canadian site with plain-language guides on fertility testing, preservation (egg/sperm/embryo), and treatment pathways.",
            url: URL(string: "https://myfertilitychoices.com/")!,
            systemImage: "books.vertical"
        ),
        Resource(
            title: "Fertility in Focus Podcast",
            subtitle: "Fertility Matters Canada",
            description: "Interviews with specialists and patient stories on infertility and fertility preservation—listen on your preferred platform.",
            url: URL(string: "https://fertilitymatters.ca/involve/programs/podcast/")!,
            systemImage: "mic"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // If the list is empty for any reason, explain rather than showing a blank screen.
                if resources.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No resources available",
                        message: "Please check back later. You can still explore Education and Pathways."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                } else {
                    VStack(spacing: 75) {
                        ForEach(resources) { resource in
                            BrandTile(
                                title: resource.title,
                                subtitle: resource.subtitle,
                                systemIcon: resource.systemImage,
                                assetIcon: nil
                            )
                            .padding(.horizontal, 16)
                            .onTapGesture { selectedResource = resource } // safe state update
                            .vanishIntoPage(vanishDistance: 350,
                                            minScale: 0.88,
                                            maxBlur: 2.5,
                                            topInset: 0,
                                            blurKickIn: 14)
                            .accessibilityLabel(Text("\(resource.title). \(resource.subtitle). Tap to view details."))
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }
        // MARK: - Standard nav style
        .navigationTitle("") // hide nav title to match other screens
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { HomeButton() }
        }

        // Reserve space equal to the ACTUAL floating header height
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: headerHeight)
        }

        // Floating header + auto-measure
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "ResourcesLogo")
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

        // Friendly non-technical alert for recoverable issues
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Detail sheet (uses ResourceDetailSheet which already handles URL opening safely)
        .sheet(item: $selectedResource) { res in
            ResourceDetailSheet(resource: res)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
