//
//  ClinicFinderView.swift
//  Synagamy3.0
//
//  An interactive map of Canadian fertility clinics with a segmented region picker.
//  This refactor:
//   • Uses the shared OnChangeHeightModifier (no per-file duplicates).
//   • Adds region *filtering* (pins change as you switch regions).
//   • Removes force-unwraps for URLs and handles bad links gracefully.
//   • Adds friendly empty states and a non-technical alert for recoverable errors.
//   • Improves accessibility labels.
//
//  Prereqs:
//   • UI/Modifiers/OnChangeHeightModifier.swift (shared)
//   • UI/Components/FloatingLogoHeader.swift
//   • UI/Web/WebSafariView.swift
//   • UI/Components/EmptyStateView.swift
//

import SwiftUI
import MapKit

struct ClinicFinderView: View {
    // MARK: - Map camera state
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56.13, longitude: -106.35), // Canada center
            span: MKCoordinateSpan(latitudeDelta: 40.0, longitudeDelta: 60.0)
        )
    )

    // MARK: - UI state
    @State private var selectedRegion: String = "Canada"     // segmented control
    @State private var selectedClinic: Clinic? = nil         // drives the detail sheet
    @State private var headerHeight: CGFloat = 64            // reserved for floating header
    @State private var errorMessage: String? = nil           // user-friendly alert text

    // MARK: - Data model for a clinic pin (includes simple region tag for filtering)
    struct Clinic: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
        let website: String
        let region: String // "Canada", "AB", "BC", "ON", "QC", "ATL", etc.
    }

    // MARK: - Master list (can be split out to a data file later)
    private let allClinics: [Clinic] = ClinicData.canada

    // Regions to present in the segmented picker (order matters)
    private let regions: [String] = ["Canada", "AB", "BC", "ON", "QC", "ATL"]

    // Filtered list for the currently selected region
    private var clinicsForRegion: [Clinic] {
        if selectedRegion == "Canada" { return allClinics }
        // Simple matching: clinic.region must equal selectedRegion
        return allClinics.filter { $0.region == selectedRegion }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Region picker row
            HStack {
                Picker("Region", selection: $selectedRegion) {
                    ForEach(regions, id: \.self) { region in
                        Text(region)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Map or an empty state if no clinics for region
            if clinicsForRegion.isEmpty {
                ScrollView {
                    EmptyStateView(
                        icon: "mappin.slash",
                        title: "No clinics in this region",
                        message: "Try a different region or select Canada to see all."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }
                .scrollIndicators(.hidden)
                .background(Color(.systemBackground))
            } else {
                Map(position: $cameraPosition) {
                    ForEach(clinicsForRegion) { clinic in
                        Annotation(clinic.name, coordinate: clinic.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(.red)
                                .onTapGesture { selectedClinic = clinic }
                                .accessibilityLabel(Text("\(clinic.name). Tap to open website."))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .mapControls { MapCompass() }
                .frame(minHeight: 360)
                .background(Color(.systemBackground))
            }
        }
        // Standard hidden nav style used throughout the app
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

        // Floating header overlay + dynamic height sync
        .overlay(alignment: .top) {
            FloatingLogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "ClinicLogo")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { headerHeight = geo.size.height }
                            .modifier(OnChangeHeightModifier(currentHeight: $headerHeight,
                                                             height: geo.size.height))
                    }
                )
        }

        // Move/zoom camera when the user changes region
        .onChange(of: selectedRegion) { _, newRegion in
            withAnimation(.easeInOut) {
                cameraPosition = .region(regionFor(newRegion))
            }
        }

        // Friendly, non-technical alert for recoverable errors
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Detail sheet: open the clinic website (safely)
        .sheet(item: $selectedClinic) { clinic in
            if let url = URL(string: clinic.website) {
                WebSafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // If the URL is malformed, show a helpful fallback instead of crashing.
                NavigationStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(clinic.name)
                            .font(.title2.bold())
                        Text("We couldn’t open this clinic’s website. Please try again later or visit it manually:")
                            .foregroundStyle(.secondary)
                        Text(clinic.website)
                            .textSelection(.enabled)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Clinic")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Region camera presets (kept intentionally broad for context)
    private func regionFor(_ key: String) -> MKCoordinateRegion {
        switch key {
        case "AB":
            return .init(center: .init(latitude: 53.93, longitude: -116.58),
                         span: .init(latitudeDelta: 8, longitudeDelta: 10))
        case "BC":
            return .init(center: .init(latitude: 54.7, longitude: -125.3),
                         span: .init(latitudeDelta: 12, longitudeDelta: 16))
        case "ON":
            return .init(center: .init(latitude: 50.0, longitude: -85.0),
                         span: .init(latitudeDelta: 16, longitudeDelta: 20))
        case "QC":
            return .init(center: .init(latitude: 52.9, longitude: -71.5),
                         span: .init(latitudeDelta: 18, longitudeDelta: 22))
        case "ATL":
            return .init(center: .init(latitude: 46.5, longitude: -63.0),
                         span: .init(latitudeDelta: 12, longitudeDelta: 16))
        default: // Canada
            return .init(center: .init(latitude: 56.13, longitude: -106.35),
                         span: .init(latitudeDelta: 40, longitudeDelta: 60))
        }
    }

    // MARK: - Static data
    private enum ClinicData {
        static let canada: [ClinicFinderView.Clinic] = [
            // BRITISH COLUMBIA
            .init(name: "Olive Fertility Centre (Vancouver)",
                  coordinate: .init(latitude: 49.2643, longitude: -123.1689),
                  website: "https://www.olivefertility.com",
                  region: "BC"),
            .init(name: "Olive Fertility Centre (Victoria)",
                  coordinate: .init(latitude: 48.4284, longitude: -123.3656),
                  website: "https://www.olivefertility.com/locations/victoria",
                  region: "BC"),
            .init(name: "Pacific Centre for Reproductive Medicine (Greater Vancouver)",
                  coordinate: .init(latitude: 49.2488, longitude: -122.9805),
                  website: "https://www.pacificfertility.ca",
                  region: "BC"),
            .init(name: "Pacific Centre for Reproductive Medicine (Victoria)",
                  coordinate: .init(latitude: 48.4649, longitude: -123.3759),
                  website: "https://www.pacificfertility.ca/fertility-clinics/victoria",
                  region: "BC"),

            // ALBERTA
            .init(name: "Regional Fertility Program (Calgary)",
                  coordinate: .init(latitude: 51.0450, longitude: -114.0570),
                  website: "https://www.regionalfertilityprogram.ca",
                  region: "AB"),
            .init(name: "Alberta Reproductive Centre (Edmonton)",
                  coordinate: .init(latitude: 53.5461, longitude: -113.4938),
                  website: "https://albertafertility.ca",
                  region: "AB"),
            .init(name: "Pacific Centre for Reproductive Medicine (Edmonton)",
                  coordinate: .init(latitude: 53.5444, longitude: -113.4909),
                  website: "https://www.pacificfertility.ca/fertility-clinics/edmonton",
                  region: "AB"),

            // SASKATCHEWAN
            .init(name: "Aurora Reproductive Care (Saskatoon)",
                  coordinate: .init(latitude: 52.1332, longitude: -106.6700),
                  website: "https://www.aurorareproductivecare.com",
                  region: "Canada"),

            // MANITOBA
            .init(name: "Heartland Fertility (Winnipeg)",
                  coordinate: .init(latitude: 49.8951, longitude: -97.1384),
                  website: "https://www.heartlandfertility.mb.ca",
                  region: "Canada"),

            // ONTARIO (GTA & SWO)
            .init(name: "CReATe Fertility Centre (Toronto)",
                  coordinate: .init(latitude: 43.6532, longitude: -79.3832),
                  website: "https://www.createivf.com",
                  region: "ON"),
            .init(name: "TRIO Fertility (Toronto)",
                  coordinate: .init(latitude: 43.6532, longitude: -79.3832),
                  website: "https://triofertility.com",
                  region: "ON"),
            .init(name: "Mount Sinai Fertility (Toronto)",
                  coordinate: .init(latitude: 43.6540, longitude: -79.3860),
                  website: "https://mountsinaifertility.com",
                  region: "ON"),
            .init(name: "Hannam Fertility Centre (Toronto)",
                  coordinate: .init(latitude: 43.6710, longitude: -79.3830),
                  website: "https://www.hannamfertility.com",
                  region: "ON"),
            .init(name: "Pollin Fertility (Toronto)",
                  coordinate: .init(latitude: 43.7087, longitude: -79.3985),
                  website: "https://www.pollinfertility.com",
                  region: "ON"),
            .init(name: "IVF Canada (GTA)",
                  coordinate: .init(latitude: 43.6532, longitude: -79.3832),
                  website: "https://ivfcanada.com",
                  region: "ON"),
            .init(name: "RCC Fertility (Mississauga)",
                  coordinate: .init(latitude: 43.5950, longitude: -79.7160),
                  website: "https://rccfertility.com",
                  region: "ON"),
            .init(name: "ONE Fertility (Burlington)",
                  coordinate: .init(latitude: 43.3250, longitude: -79.7990),
                  website: "https://onefertility.com",
                  region: "ON"),
            .init(name: "ONE Fertility Kitchener-Waterloo (Kitchener)",
                  coordinate: .init(latitude: 43.4250, longitude: -80.4200),
                  website: "https://www.onefertilitykitchenerwaterloo.com",
                  region: "ON"),
            .init(name: "Generation Fertility (Toronto West)",
                  coordinate: .init(latitude: 43.6450, longitude: -79.5150),
                  website: "https://www.generationfertility.ca",
                  region: "ON"),
            .init(name: "Generation Fertility (Vaughan)",
                  coordinate: .init(latitude: 43.8417, longitude: -79.5149),
                  website: "https://www.generationfertility.ca",
                  region: "ON"),
            .init(name: "Generation Fertility (Newmarket)",
                  coordinate: .init(latitude: 44.0592, longitude: -79.4613),
                  website: "https://www.generationfertility.ca",
                  region: "ON"),
            .init(name: "Generation Fertility (Waterloo)",
                  coordinate: .init(latitude: 43.4668, longitude: -80.5164),
                  website: "https://www.generationfertility.ca",
                  region: "ON"),
            .init(name: "Markham Fertility Centre (Markham)",
                  coordinate: .init(latitude: 43.8760, longitude: -79.2630),
                  website: "https://markhamfertility.com",
                  region: "ON"),
            .init(name: "Niagara Fertility (Stoney Creek)",
                  coordinate: .init(latitude: 43.2170, longitude: -79.7650),
                  website: "https://ontariofertilitynetwork.com/locations/niagara-fertility-clinic/",
                  region: "ON"),
            .init(name: "Ottawa Fertility Centre (Ottawa)",
                  coordinate: .init(latitude: 45.4215, longitude: -75.6972),
                  website: "https://www.ottawafertilitycentre.com",
                  region: "ON"),

            // QUÉBEC
            .init(name: "OVO Fertility (Montréal)",
                  coordinate: .init(latitude: 45.5017, longitude: -73.5673),
                  website: "https://www.cliniqueovo.com",
                  region: "QC"),
            .init(name: "Fertilys (Laval)",
                  coordinate: .init(latitude: 45.5579, longitude: -73.7231),
                  website: "https://www.fertilys.org",
                  region: "QC"),
            .init(name: "Montréal Fertility Centre (Montréal)",
                  coordinate: .init(latitude: 45.5017, longitude: -73.5673),
                  website: "https://montrealfertility.com",
                  region: "QC"),
            .init(name: "MUHC Reproductive Centre (Montréal)",
                  coordinate: .init(latitude: 45.4960, longitude: -73.5870),
                  website: "https://cusm.ca/centre-reproduction",
                  region: "QC"),
            .init(name: "Procrea Fertilité (Québec City)",
                  coordinate: .init(latitude: 46.8139, longitude: -71.2080),
                  website: "https://en.procrea.ca",
                  region: "QC"),
            .init(name: "Miacleo (Rive-Sud / Longueuil)",
                  coordinate: .init(latitude: 45.5230, longitude: -73.5210),
                  website: "https://miacleo.com",
                  region: "QC"),
            .init(name: "Clinique de fertilité – CHU de Québec-Université Laval (Québec)",
                  coordinate: .init(latitude: 46.8139, longitude: -71.2080),
                  website: "https://www.chudequebec.ca",
                  region: "QC"),
            .init(name: "Fertility & Assisted Reproduction Clinic – CIUSSS de l’Estrie-CHUS (Sherbrooke)",
                  coordinate: .init(latitude: 45.4030, longitude: -71.8920),
                  website: "https://www.santeestrie.qc.ca/en/care-services/themes/grossesse-accouchement/our-fertility-and-assisted-reproduction-clinic",
                  region: "QC"),

            // ATLANTIC
            .init(name: "Atlantic Fertility (Halifax)",
                  coordinate: .init(latitude: 44.6488, longitude: -63.5752),
                  website: "https://atlanticfertility.ca",
                  region: "ATL"),
            .init(name: "Conceptia (Moncton)",
                  coordinate: .init(latitude: 46.0878, longitude: -64.7782),
                  website: "https://conceptia.ca",
                  region: "ATL"),
            .init(name: "NL Fertility Services (Eastern Health, St. John’s)",
                  coordinate: .init(latitude: 47.5615, longitude: -52.7126),
                  website: "https://www.easternhealth.ca/providers/fertility-services/",
                  region: "ATL")
        ]
    }
}
