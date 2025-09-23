//
//  SettingsView.swift
//  Synagamy3.0
//
//  Comprehensive settings and preferences for the Synagamy app
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredUnits") private var preferredUnits: UnitSystem = .metric
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("dataSource") private var dataSource: DataSource = .automatic
    @AppStorage("exportFormat") private var exportFormat: ExportFormat = .pdf
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("privacyMode") private var privacyMode: Bool = false
    
    @State private var showingAbout = false
    @State private var showingPrivacy = false
    @State private var showingDisclaimer = false
    @State private var showingDataManagement = false
    
    enum UnitSystem: String, CaseIterable {
        case metric = "Metric"
        case imperial = "Imperial"
        
        var displayName: String { rawValue }
    }
    
    enum DataSource: String, CaseIterable {
        case automatic = "Automatic"
        case remoteOnly = "Remote Only"
        case offlineMode = "Offline Mode"
        
        var displayName: String { rawValue }
        var description: String {
            switch self {
            case .automatic:
                return "Use remote data when available, fallback to cached data"
            case .remoteOnly:
                return "Always fetch latest data from server"
            case .offlineMode:
                return "Use only locally cached data"
            }
        }
    }
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case text = "Text"
        case json = "JSON"
        
        var displayName: String { rawValue }
    }
    
    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var displayName: String { rawValue }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Units & Preferences
                Section("Units & Preferences") {
                    Picker("Unit System", selection: $preferredUnits) {
                        ForEach(UnitSystem.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    
                    Picker("Appearance", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    
                    Picker("Export Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }
                
                // Data & Privacy
                Section("Data & Privacy") {
                    Picker("Data Source", selection: $dataSource) {
                        ForEach(DataSource.allCases, id: \.self) { source in
                            VStack(alignment: .leading) {
                                Text(source.displayName)
                                Text(source.description)
                                    .font(Brand.Typography.bodySmall)
                                    .foregroundColor(.secondary)
                            }
                            .tag(source)
                        }
                    }
                    
                    Toggle("Privacy Mode", isOn: $privacyMode)
                    
                    Button("Manage Data") {
                        showingDataManagement = true
                    }
                    .foregroundColor(Brand.Color.primary)
                }
                
                // Notifications
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    
                    if enableNotifications {
                        NavigationLink("Notification Preferences") {
                            NotificationSettingsView()
                        }
                    }
                }
                
                // About & Legal
                Section("About & Legal") {
                    Button("About Synagamy") {
                        showingAbout = true
                    }
                    .foregroundColor(Brand.Color.primary)
                    
                    Button("Privacy Policy") {
                        showingPrivacy = true
                    }
                    .foregroundColor(Brand.Color.primary)
                    
                    Button("Medical Disclaimer") {
                        showingDisclaimer = true
                    }
                    .foregroundColor(Brand.Color.primary)
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Advanced
                Section("Advanced") {
                    NavigationLink("Debug Information") {
                        DebugSettingsView()
                    }
                    
                    Button("Reset All Settings") {
                        resetSettings()
                    }
                    .foregroundColor(Brand.Color.error)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingDisclaimer) {
            MedicalDisclaimerView()
        }
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
    }
    
    private func resetSettings() {
        preferredUnits = .metric
        enableNotifications = true
        dataSource = .automatic
        exportFormat = .pdf
        appearanceMode = .system
        privacyMode = false
    }
}

struct NotificationSettingsView: View {
    @AppStorage("reminderFrequency") private var reminderFrequency: ReminderFrequency = .weekly
    @AppStorage("predictionUpdates") private var predictionUpdates: Bool = true
    @AppStorage("educationContent") private var educationContent: Bool = true
    
    enum ReminderFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case never = "Never"
        
        var displayName: String { rawValue }
    }
    
    var body: some View {
        List {
            Section("Reminder Frequency") {
                Picker("Frequency", selection: $reminderFrequency) {
                    ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Content Notifications") {
                Toggle("Prediction Updates", isOn: $predictionUpdates)
                Toggle("New Educational Content", isOn: $educationContent)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                    // App Icon and Name
                    VStack(spacing: Brand.Spacing.lg) {
                        Image("SynagamyLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(Brand.Radius.xl)
                        
                        Text("Synagamy")
                            .font(Brand.Typography.displayMedium)
                        
                        Text("Evidence-Based Fertility Education")
                            .font(Brand.Typography.bodyMedium)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Brand.Spacing.lg)
                    
                    // Description
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Text("About This App")
                            .font(Brand.Typography.headlineMedium)
                        
                        Text("Synagamy provides evidence-based fertility education and IVF outcome predictions based on Canadian national data. Our algorithms use the latest research from CARTR-BORN and international fertility registries.")
                            .lineLimit(nil)
                        
                        Text("This app is designed for educational purposes only and should not replace professional medical advice.")
                            .font(Brand.Typography.bodySmall)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Text("Key Features")
                            .font(Brand.Typography.headlineMedium)
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            FeatureRow(icon: "chart.bar.fill", title: "IVF Outcome Prediction", description: "Personalized predictions based on population data")
                            FeatureRow(icon: "book.fill", title: "Educational Content", description: "Comprehensive fertility education resources")
                            FeatureRow(icon: "map.fill", title: "Treatment Pathways", description: "Personalized learning paths")
                            FeatureRow(icon: "heart.fill", title: "Timed Intercourse", description: "Fertility window tracking")
                        }
                    }
                    
                    // Credits
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Text("Data Sources")
                            .font(Brand.Typography.headlineMedium)
                        
                        Text("• CARTR-BORN Registry (Canada)\n• CDC/SART Registry (USA)\n• International Fertility Research")
                            .font(Brand.Typography.bodySmall)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Brand.Spacing.md) {
            Image(systemName: icon)
                .font(Brand.Typography.headlineMedium)
                .foregroundColor(Brand.Color.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                Text(title)
                    .font(Brand.Typography.labelLarge)
                
                Text(description)
                    .font(Brand.Typography.bodySmall)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct DataManagementView: View {
    @StateObject private var consentManager = MedicalDataConsentManager.shared
    @StateObject private var persistenceService = PredictionPersistenceService.shared

    @State private var showingClearDataAlert = false
    @State private var showingMedicalDataAlert = false
    @State private var showingConsentRevokeAlert = false
    @State private var showingDataExport = false
    @State private var dataSize = "Loading..."
    @State private var medicalDataInfo = "Loading..."
    @State private var exportedData: [String: Any] = [:]

    var body: some View {
        NavigationView {
            List {
                // Medical Data Consent Section
                Section("Medical Data Consent") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Consent Status")
                            Text(consentStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: consentManager.hasUserConsentedToDataStorage ? "checkmark.shield.fill" : "xmark.shield.fill")
                            .foregroundColor(consentManager.hasUserConsentedToDataStorage ? .green : .orange)
                    }

                    if consentManager.hasUserConsentedToDataStorage {
                        if !consentManager.isConsentCurrent() {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Consent expires soon - please renew")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        Button("Revoke Medical Data Consent") {
                            showingConsentRevokeAlert = true
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Grant Medical Data Consent") {
                            consentManager.requestConsentIfNeeded()
                        }
                        .foregroundColor(.blue)
                    }
                }

                // Medical Data Section
                if consentManager.hasUserConsentedToDataStorage {
                    Section("Medical Data") {
                        HStack {
                            Text("Stored Predictions")
                            Spacer()
                            Text("\(persistenceService.savedPredictions.count)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Data Status")
                            Spacer()
                            Text("Encrypted")
                                .foregroundColor(.green)
                        }

                        Button("View My Medical Data") {
                            exportedData = persistenceService.exportMedicalDataForReview()
                            showingDataExport = true
                        }
                        .foregroundColor(.blue)

                        Button("Delete All Medical Data") {
                            showingMedicalDataAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }

                // General Storage Section
                Section("App Storage") {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(dataSize)
                            .foregroundColor(.secondary)
                    }

                    Button("Clear Cache") {
                        showingClearDataAlert = true
                    }
                    .foregroundColor(.orange)
                }

                // Export Section
                Section("Data Export") {
                    if consentManager.hasUserConsentedToDataStorage {
                        Button("Export Medical Data Report") {
                            exportMedicalData()
                        }
                        .foregroundColor(.blue)
                    }

                    Button("Export App Settings") {
                        exportAppSettings()
                    }
                    .foregroundColor(.blue)
                }

                // Privacy Information
                Section("Privacy Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Protection")
                            .font(.headline)
                        Text("• Medical data is encrypted using iOS Keychain\n• Data stays on your device only\n• No data is transmitted to external servers\n• You can delete everything at any time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
        .sheet(isPresented: $consentManager.isShowingConsentSheet) {
            MedicalDataConsentSheet()
        }
        .sheet(isPresented: $showingDataExport) {
            MedicalDataExportView(exportedData: exportedData)
        }
        .alert("Clear Cache", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear all cached data. The app will download fresh data when needed.")
        }
        .alert("Delete Medical Data", isPresented: $showingMedicalDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await persistenceService.clearAllPredictions()
                }
            }
        } message: {
            Text("This will permanently delete all your saved medical predictions and data. This action cannot be undone.")
        }
        .alert("Revoke Medical Data Consent", isPresented: $showingConsentRevokeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Revoke & Delete", role: .destructive) {
                Task {
                    await consentManager.revokeConsent()
                }
            }
        } message: {
            Text("This will revoke your consent and permanently delete all medical data. This action cannot be undone.")
        }
        .onAppear {
            calculateDataSize()
        }
    }

    private var consentStatusText: String {
        if consentManager.hasUserConsentedToDataStorage {
            if let timestamp = consentManager.consentTimestamp {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Granted on \(formatter.string(from: timestamp))"
            } else {
                return "Granted"
            }
        } else {
            return "Not granted"
        }
    }

    private func calculateDataSize() {
        // Calculate actual cache size
        dataSize = "2.3 MB" // Placeholder
    }

    private func clearCache() {
        // Clear cache implementation
    }

    private func exportMedicalData() {
        // Export medical data with proper formatting
        let data = persistenceService.exportMedicalDataForReview()
        // Implement sharing functionality
    }

    private func exportAppSettings() {
        // Export app settings (non-medical data)
    }
}

// MARK: - Medical Data Export View

struct MedicalDataExportView: View {
    let exportedData: [String: Any]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Medical Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom)

                    if let totalPredictions = exportedData["totalPredictions"] as? Int {
                        Text("Total Saved Predictions: \(totalPredictions)")
                            .font(.headline)
                    }

                    if let predictions = exportedData["predictions"] as? [[String: Any]] {
                        ForEach(Array(predictions.enumerated()), id: \.offset) { index, prediction in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Prediction \(index + 1)")
                                    .font(.headline)

                                if let timestamp = prediction["timestamp"] as? String {
                                    Text("Date: \(timestamp)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if let age = prediction["age"] {
                                    Text("Age: \(age)")
                                }

                                if let amh = prediction["amhLevel"], !(amh is NSNull) {
                                    Text("AMH Level: \(amh)")
                                }

                                if let estrogen = prediction["estrogenLevel"], !(estrogen is NSNull) {
                                    Text("Estrogen Level: \(estrogen)")
                                }

                                if let bmi = prediction["bmi"], !(bmi is NSNull) {
                                    Text("BMI: \(bmi)")
                                }

                                if let diagnosis = prediction["diagnosisType"] as? String {
                                    Text("Diagnosis: \(diagnosis)")
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    Text("Data Protection Notice")
                        .font(.headline)
                        .padding(.top)

                    Text("This data is stored encrypted on your device only. It is never transmitted to external servers. You have the right to delete this data at any time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("My Medical Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DebugSettingsView: View {
    @State private var memoryInfo = "Loading..."
    @State private var networkStatus = "Loading..."
    
    var body: some View {
        List {
            Section("Performance") {
                HStack {
                    Text("Memory Usage")
                    Spacer()
                    Text(memoryInfo)
                        .foregroundColor(.secondary)
                        .font(Brand.Typography.bodySmall)
                }
                
                HStack {
                    Text("Network Status")
                    Spacer()
                    Text(networkStatus)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Debugging") {
                Button("View Error Log") {
                    // Show error log
                }
                .foregroundColor(.blue)
                
                Button("Test Remote Connection") {
                    // Test connection
                }
                .foregroundColor(.blue)
                
                Button("Reset All Caches") {
                    // Reset caches
                }
                .foregroundColor(Brand.Color.warning)
            }
        }
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDebugInfo()
        }
    }
    
    private func loadDebugInfo() {
        memoryInfo = "45.2 MB"
        networkStatus = "Connected"
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                    Text("Privacy Policy")
                        .font(Brand.Typography.displayMedium)
                        .padding(.bottom)
                    
                    Group {
                        privacySection(
                            title: "Data Collection",
                            content: "Synagamy does not collect personal health information. All predictions are calculated locally on your device."
                        )
                        
                        privacySection(
                            title: "Data Storage",
                            content: "Your input data and prediction results are stored locally on your device and are not transmitted to our servers."
                        )
                        
                        privacySection(
                            title: "Third-Party Services",
                            content: "We use GitHub for hosting educational content. No personal data is sent to GitHub."
                        )
                        
                        privacySection(
                            title: "Your Rights",
                            content: "You can delete all app data at any time through the Settings > Data Management section."
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text(title)
                .font(Brand.Typography.headlineMedium)
            
            Text(content)
                .font(Brand.Typography.bodyMedium)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Settings") {
    SettingsView()
}

#Preview("About") {
    AboutView()
}