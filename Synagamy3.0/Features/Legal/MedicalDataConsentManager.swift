//
//  MedicalDataConsentManager.swift
//  Synagamy3.0
//
//  Manages user consent for storing sensitive medical data
//  Required for HIPAA/privacy law compliance
//

import Foundation
import SwiftUI

@MainActor
class MedicalDataConsentManager: ObservableObject {
    static let shared = MedicalDataConsentManager()

    @Published var hasUserConsentedToDataStorage = false
    @Published var isShowingConsentSheet = false
    @Published var consentTimestamp: Date?

    private let userDefaults = UserDefaults.standard
    private let consentKey = "MedicalDataStorageConsent"
    private let consentTimestampKey = "MedicalDataConsentTimestamp"

    private init() {
        loadConsentStatus()
    }

    // MARK: - Public Methods

    /// Check if user has provided explicit consent for medical data storage
    func checkConsentStatus() -> Bool {
        return hasUserConsentedToDataStorage
    }

    /// Request consent from user before storing medical data
    func requestConsentIfNeeded() {
        if !hasUserConsentedToDataStorage {
            isShowingConsentSheet = true
        }
    }

    /// User grants consent to store medical data
    func grantConsent() {
        hasUserConsentedToDataStorage = true
        consentTimestamp = Date()
        saveConsentStatus()
        isShowingConsentSheet = false
    }

    /// User declines consent - no medical data will be stored
    func declineConsent() {
        hasUserConsentedToDataStorage = false
        consentTimestamp = nil
        saveConsentStatus()
        isShowingConsentSheet = false
    }

    /// Revoke previously granted consent and delete all stored medical data
    func revokeConsent() async {
        hasUserConsentedToDataStorage = false
        consentTimestamp = nil
        saveConsentStatus()

        // Delete all stored medical data
        await deleteAllMedicalData()
    }

    /// Check if consent was granted within the last year (recommended re-consent period)
    func isConsentCurrent() -> Bool {
        guard hasUserConsentedToDataStorage,
              let timestamp = consentTimestamp else { return false }

        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date.distantPast
        return timestamp > oneYearAgo
    }

    // MARK: - Private Methods

    private func loadConsentStatus() {
        hasUserConsentedToDataStorage = userDefaults.bool(forKey: consentKey)
        if let timestampData = userDefaults.object(forKey: consentTimestampKey) as? Date {
            consentTimestamp = timestampData
        }
    }

    private func saveConsentStatus() {
        userDefaults.set(hasUserConsentedToDataStorage, forKey: consentKey)
        if let timestamp = consentTimestamp {
            userDefaults.set(timestamp, forKey: consentTimestampKey)
        } else {
            userDefaults.removeObject(forKey: consentTimestampKey)
        }
    }

    private func deleteAllMedicalData() async {
        // Delete encrypted medical data
        await SecureMedicalDataStore.shared.deleteAllData()

        // Clear any legacy UserDefaults data
        userDefaults.removeObject(forKey: "SavedIVFPredictions")

        #if DEBUG
        print("🗑️ All medical data deleted due to consent revocation")
        #endif
    }
}

// MARK: - Consent Sheet View

struct MedicalDataConsentSheet: View {
    @StateObject private var consentManager = MedicalDataConsentManager.shared
    @State private var hasReadFullDisclosure = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Medical Data Storage Consent")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)

                    // Data Collection Disclosure
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What Medical Data We Store")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            DisclosureRow(icon: "person.circle", text: "Age and demographic information")
                            DisclosureRow(icon: "heart.circle", text: "Hormone levels (AMH, Estrogen)")
                            DisclosureRow(icon: "figure.walk.circle", text: "Body mass index (BMI)")
                            DisclosureRow(icon: "medical.thermometer", text: "Fertility diagnosis information")
                            DisclosureRow(icon: "chart.line.uptrend.xyaxis.circle", text: "IVF prediction results and calculations")
                        }
                        .padding(.leading, 8)
                    }

                    // Data Protection Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How We Protect Your Data")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            DisclosureRow(icon: "lock.shield", text: "All medical data is encrypted using industry-standard encryption")
                            DisclosureRow(icon: "iphone", text: "Data is stored locally on your device only")
                            DisclosureRow(icon: "network.slash", text: "No medical data is transmitted to external servers")
                            DisclosureRow(icon: "person.badge.shield.checkmark", text: "You can delete all data at any time in Settings")
                        }
                        .padding(.leading, 8)
                    }

                    // Your Rights
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Rights")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            DisclosureRow(icon: "hand.raised.circle", text: "You can decline data storage and still use the app")
                            DisclosureRow(icon: "trash.circle", text: "Delete all stored medical data at any time")
                            DisclosureRow(icon: "arrow.clockwise.circle", text: "Revoke consent and automatically delete data")
                            DisclosureRow(icon: "eye.circle", text: "View exactly what data is stored about you")
                        }
                        .padding(.leading, 8)
                    }

                    // Consent Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("I have read and understand the data handling practices", isOn: $hasReadFullDisclosure)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            consentManager.grantConsent()
                        }) {
                            Text("Grant Consent to Store Medical Data")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(hasReadFullDisclosure ? Color.blue : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(!hasReadFullDisclosure)

                        Button(action: {
                            consentManager.declineConsent()
                        }) {
                            Text("Decline - Don't Store My Medical Data")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("Medical Data Consent")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Supporting Views

struct DisclosureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    MedicalDataConsentSheet()
}