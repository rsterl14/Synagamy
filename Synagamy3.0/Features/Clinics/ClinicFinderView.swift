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
    @StateObject private var errorHandler = ErrorHandler.shared
    @State private var mapLoadError: Bool = false

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
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "ClinicLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(spacing: Brand.Spacing.md) {
                // Enhanced region selector header
                VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                    HStack(spacing: Brand.Spacing.sm) {
                        Image(systemName: "location.fill")
                            .font(.body)
                            .foregroundColor(Brand.Color.primary)

                        Text("Select Region")
                            .font(Brand.Typography.labelLarge)
                            .foregroundColor(Brand.Color.primary)
                    }
                    
                    // Custom region selector with brand styling
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Brand.Spacing.sm) {
                            ForEach(regions, id: \.self) { region in
                                Button(action: {
                                    selectedRegion = region
                                }) {
                                    Text(region)
                                        .font(Brand.Typography.bodyMedium)
                                        .foregroundColor(selectedRegion == region ? .white : Brand.Color.primary)
                                        .padding(.horizontal, Brand.Spacing.lg)
                                        .padding(.vertical, Brand.Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: Brand.Radius.xl, style: .continuous)
                                                .fill(selectedRegion == region ? Brand.Color.primary : Brand.Color.primary.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Brand.Radius.xl, style: .continuous)
                                                        .strokeBorder(Brand.Color.primary.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedRegion)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, Brand.Spacing.lg)
                .padding(.vertical, Brand.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

                // Map with reasonable height
                if clinicsForRegion.isEmpty {
                    EmptyStateView(
                        icon: "mappin.slash",
                        title: "No clinics in this region",
                        message: "Try a different region or select Canada to see all."
                    )
                    .frame(height: 420)
                } else {
                    if mapLoadError {
                        // Map failed to load - show error state
                        VStack(spacing: 16) {
                            Image(systemName: "map.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            
                            Text("Map Unavailable")
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(.primary)
                            
                            Text("The map couldn't load. You can still browse clinic information below.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Try Again") {
                                mapLoadError = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(height: 600)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg))
                    } else {
                        Map(position: $cameraPosition) {
                            ForEach(clinicsForRegion) { clinic in
                                Annotation(clinic.name, coordinate: clinic.coordinate) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(Brand.Color.secondary)
                                        .onTapGesture { 
                                            handleClinicSelection(clinic)
                                        }
                                        .accessibilityLabel(Text("\(clinic.name). Tap to open website."))
                                }
                            }
                        }
                        .mapControls { MapCompass() }
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg))
                        .onAppear {
                            // Validate map can load
                            validateMapAccess()
                        }
                    }
                }
            }
        }

        // Move/zoom camera when the user changes region
        .onChange(of: selectedRegion) { _, newRegion in
            withAnimation(.easeInOut) {
                cameraPosition = .region(regionFor(newRegion))
            }
        }

        // Centralized error handling
        .errorAlert(
            onRetry: {
                mapLoadError = false
                validateMapAccess()
            },
            onNavigateHome: {
                // Navigation handled by parent
            }
        )

        // Detail sheet: open the clinic website (safely)
        .sheet(item: $selectedClinic) { clinic in
            if let url = URL(string: clinic.website) {
                WebSafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // If the URL is malformed, show a helpful fallback instead of crashing.
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Brand.Spacing.xl) {

                            // MARK: - Enhanced header matching app style
                            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                                // Category badge
                                HStack {
                                    Image(systemName: "building.2.fill")
                                        .font(.caption2)
                                    
                                    Text("CLINIC")
                                        .font(Brand.Typography.labelSmall)
                                        .tracking(0.5)
                                }
                                .foregroundColor(Brand.Color.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Brand.Color.primary.opacity(0.12))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Brand.Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                
                                // Main title
                                Text(clinic.name)
                                    .font(Brand.Typography.headlineMedium)
                                    .foregroundColor(Brand.Color.primary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityAddTraits(.isHeader)
                            }
                            .padding(.bottom, 4)
                            
                            // Divider
                            Rectangle()
                                .fill(Brand.Color.primary.opacity(0.2))
                                .frame(height: 1)
                                .padding(.bottom, 4)

                            // MARK: - Error content with enhanced design
                            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                                HStack(spacing: Brand.Spacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.body)
                                        .foregroundColor(.orange)
                                    
                                    Text("Website Unavailable")
                                        .font(Brand.Typography.labelLarge)
                                        .foregroundColor(Brand.Color.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                                    Text("We couldn't open this clinic's website. Please try again later or visit it manually:")
                                        .font(Brand.Typography.bodyMedium)
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text(clinic.website)
                                        .font(Brand.Typography.bodyMedium)
                                        .foregroundColor(Brand.Color.primary)
                                        .textSelection(.enabled)
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.8)
                                        .padding(Brand.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                                .fill(Brand.Color.primary.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                                        .strokeBorder(Brand.Color.primary.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
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
                        }
                        .padding()
                    }
                }
                .tint(Brand.Color.primary)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Error Handling Methods
    
    private func handleClinicSelection(_ clinic: Clinic) {
        // Validate clinic URL before selection
        guard URL(string: clinic.website) != nil else {
            let error = SynagamyError.urlInvalid(url: clinic.website)
            errorHandler.handle(error)
            return
        }
        
        selectedClinic = clinic
    }
    
    private func validateMapAccess() {
        // Basic check for map functionality
        // This is a placeholder - in a real app you might check location permissions,
        // network connectivity for map tiles, etc.
        
        // Simulate map loading check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // In a real implementation, you would check if MapKit is available
            // For now, we'll assume it works unless there's a specific issue
            
            // You could add actual validation here such as:
            // - Check if device supports MapKit
            // - Check network connectivity for map tiles
            // - Validate coordinate data
            
            let invalidClinics = clinicsForRegion.filter { clinic in
                clinic.coordinate.latitude < -90 || clinic.coordinate.latitude > 90 ||
                clinic.coordinate.longitude < -180 || clinic.coordinate.longitude > 180
            }
            
            if !invalidClinics.isEmpty {
                let error = SynagamyError.dataValidationFailed(
                    resource: "Clinic Locations",
                    issues: invalidClinics.map { "Invalid coordinates for \($0.name)" }
                )
                errorHandler.handle(error)
                mapLoadError = true
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
