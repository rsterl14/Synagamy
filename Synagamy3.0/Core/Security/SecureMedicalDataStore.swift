//
//  SecureMedicalDataStore.swift
//  Synagamy3.0
//
//  Secure encrypted storage for sensitive medical data using iOS Keychain
//  Replaces unencrypted UserDefaults for HIPAA compliance
//

import Foundation
import Security

@MainActor
class SecureMedicalDataStore: ObservableObject {
    static let shared = SecureMedicalDataStore()

    @Published var savedPredictions: [SavedPrediction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = "com.synagamy.medical-data"
    private let predictionsAccount = "ivf-predictions"
    private let maxSavedPredictions = 20

    private init() {
        Task {
            await loadPredictions()
        }
    }

    // MARK: - Public Methods

    /// Save a medical prediction with encryption
    func savePrediction(
        _ prediction: SavedPrediction,
        withNickname nickname: String? = nil
    ) async throws {
        #if DEBUG
        print("🔐 SecureMedicalDataStore: Starting to save encrypted prediction: \(prediction.displayName)")
        #endif

        guard MedicalDataConsentManager.shared.checkConsentStatus() else {
            throw MedicalDataError.consentRequired
        }

        isLoading = true
        defer { isLoading = false }

        // Add to beginning of array (most recent first)
        savedPredictions.insert(prediction, at: 0)

        // Limit the number of saved predictions
        if savedPredictions.count > maxSavedPredictions {
            savedPredictions = Array(savedPredictions.prefix(maxSavedPredictions))
        }

        try await encryptAndStorePredictions()

        #if DEBUG
        print("🔐 SecureMedicalDataStore: Successfully saved encrypted prediction. Total saved: \(savedPredictions.count)")
        #endif
    }

    /// Delete a specific prediction
    func deletePrediction(_ prediction: SavedPrediction) async throws {
        savedPredictions.removeAll { $0.id == prediction.id }
        try await encryptAndStorePredictions()
    }

    /// Clear all stored medical data
    func deleteAllData() async {
        savedPredictions.removeAll()

        // Remove from keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: predictionsAccount
        ]

        let status = SecItemDelete(query as CFDictionary)

        #if DEBUG
        if status == errSecSuccess {
            print("🗑️ SecureMedicalDataStore: Successfully deleted all encrypted medical data")
        } else {
            print("⚠️ SecureMedicalDataStore: Failed to delete keychain data: \(status)")
        }
        #endif

        errorMessage = nil
    }

    /// Export medical data for user review (non-encrypted format for transparency)
    func exportMedicalDataForReview() -> [String: Any] {
        var exportData: [String: Any] = [:]

        exportData["totalPredictions"] = savedPredictions.count
        exportData["predictions"] = savedPredictions.map { prediction in
            return [
                "id": prediction.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: prediction.timestamp),
                "age": prediction.age,
                "amhLevel": prediction.amhLevel ?? "Not provided",
                "estrogenLevel": prediction.estrogenLevel ?? "Not provided",
                "bmi": prediction.bmi ?? "Not provided",
                "diagnosisType": prediction.diagnosisType,
                "nickname": prediction.nickname ?? "None"
            ]
        }

        return exportData
    }

    // MARK: - Private Methods

    /// Load predictions from encrypted keychain storage
    private func loadPredictions() async {
        #if DEBUG
        print("🔐 SecureMedicalDataStore: Loading predictions from encrypted storage")
        #endif

        guard MedicalDataConsentManager.shared.checkConsentStatus() else {
            #if DEBUG
            print("🚫 SecureMedicalDataStore: No consent - skipping data load")
            #endif
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: predictionsAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            #if DEBUG
            if status == errSecItemNotFound {
                print("🔐 SecureMedicalDataStore: No encrypted predictions found")
            } else {
                print("⚠️ SecureMedicalDataStore: Failed to load from keychain: \(status)")
            }
            #endif
            return
        }

        do {
            let loadedPredictions = try JSONDecoder().decode([SavedPrediction].self, from: data)
            savedPredictions = loadedPredictions

            #if DEBUG
            print("🔐 SecureMedicalDataStore: Loaded \(savedPredictions.count) encrypted predictions")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ SecureMedicalDataStore: Failed to decode predictions: \(error)")
            #endif

            // Clear corrupted data
            await deleteAllData()
            errorMessage = "Stored medical data was corrupted and has been cleared for security"
        }
    }

    /// Encrypt and store predictions in keychain
    private func encryptAndStorePredictions() async throws {
        do {
            let data = try JSONEncoder().encode(savedPredictions)

            // First, try to update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: predictionsAccount
            ]

            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]

            var status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

            // If update fails because item doesn't exist, add new item
            if status == errSecItemNotFound {
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: predictionsAccount,
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                ]

                status = SecItemAdd(addQuery as CFDictionary, nil)
            }

            guard status == errSecSuccess else {
                throw MedicalDataError.encryptionFailed(status)
            }

            #if DEBUG
            print("🔐 SecureMedicalDataStore: Successfully encrypted and stored \(savedPredictions.count) predictions")
            #endif

        } catch let error as MedicalDataError {
            throw error
        } catch {
            throw MedicalDataError.encodingFailed(error)
        }
    }
}

// MARK: - Error Types

enum MedicalDataError: LocalizedError {
    case consentRequired
    case encryptionFailed(OSStatus)
    case encodingFailed(Error)
    case dataDeletionFailed

    var errorDescription: String? {
        switch self {
        case .consentRequired:
            return "User consent is required before storing medical data"
        case .encryptionFailed(let status):
            return "Failed to encrypt medical data (Keychain error: \(status))"
        case .encodingFailed(let error):
            return "Failed to encode medical data: \(error.localizedDescription)"
        case .dataDeletionFailed:
            return "Failed to delete medical data from secure storage"
        }
    }
}

// MARK: - Migration Helper

extension SecureMedicalDataStore {
    /// Migrate existing unencrypted UserDefaults data to encrypted storage
    func migrateFromUserDefaults() async {
        #if DEBUG
        print("🔄 SecureMedicalDataStore: Checking for legacy UserDefaults data to migrate")
        #endif

        let userDefaults = UserDefaults.standard
        let legacyKey = "SavedIVFPredictions"

        guard let legacyData = userDefaults.data(forKey: legacyKey) else {
            #if DEBUG
            print("🔄 SecureMedicalDataStore: No legacy data found")
            #endif
            return
        }

        do {
            let legacyPredictions = try JSONDecoder().decode([SavedPrediction].self, from: legacyData)

            #if DEBUG
            print("🔄 SecureMedicalDataStore: Found \(legacyPredictions.count) legacy predictions to migrate")
            #endif

            // Only migrate if user has consented
            guard MedicalDataConsentManager.shared.checkConsentStatus() else {
                #if DEBUG
                print("🚫 SecureMedicalDataStore: Cannot migrate - no user consent")
                #endif
                // Delete unencrypted legacy data for security
                userDefaults.removeObject(forKey: legacyKey)
                return
            }

            // Migrate to encrypted storage
            savedPredictions = legacyPredictions
            try await encryptAndStorePredictions()

            // Remove legacy unencrypted data
            userDefaults.removeObject(forKey: legacyKey)

            #if DEBUG
            print("✅ SecureMedicalDataStore: Successfully migrated \(legacyPredictions.count) predictions to encrypted storage")
            #endif

        } catch {
            #if DEBUG
            print("⚠️ SecureMedicalDataStore: Failed to migrate legacy data: \(error)")
            #endif

            // Delete corrupted legacy data for security
            userDefaults.removeObject(forKey: legacyKey)
        }
    }
}