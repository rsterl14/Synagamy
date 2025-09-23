//
//  PredictionPersistenceService.swift
//  Synagamy3.0
//
//  HIPAA-Compliant service for persisting and managing saved IVF predictions
//  Uses encrypted storage and requires user consent for medical data
//

import Foundation
import Combine

@MainActor
class PredictionPersistenceService: ObservableObject {
    static let shared = PredictionPersistenceService()

    @Published var savedPredictions: [SavedPrediction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingConsentSheet = false

    private let secureStore = SecureMedicalDataStore.shared
    private let consentManager = MedicalDataConsentManager.shared
    private let maxSavedPredictions = 20

    private init() {
        // Observe changes from secure store
        secureStore.$savedPredictions
            .assign(to: &$savedPredictions)

        secureStore.$isLoading
            .assign(to: &$isLoading)

        secureStore.$errorMessage
            .assign(to: &$errorMessage)

        consentManager.$isShowingConsentSheet
            .assign(to: &$showingConsentSheet)

        Task {
            await initializeService()
        }
    }

    private func initializeService() async {
        // Check for legacy unencrypted data and migrate if needed
        await secureStore.migrateFromUserDefaults()

        // Verify consent is current (within 1 year)
        if consentManager.checkConsentStatus() && !consentManager.isConsentCurrent() {
            #if DEBUG
            print("🔔 PredictionPersistenceService: Medical data consent has expired, requesting renewal")
            #endif
            consentManager.requestConsentIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    
    /// Save a medical prediction with encryption and consent verification
    func savePrediction(
        _ prediction: SavedPrediction,
        withNickname nickname: String? = nil
    ) async {
        #if DEBUG
        print("🔐 [DEBUG] Starting to save prediction with encryption: \(prediction.displayName)")
        #endif

        // Check consent before saving any medical data
        guard consentManager.checkConsentStatus() else {
            #if DEBUG
            print("🚫 [DEBUG] Cannot save prediction - user has not consented to medical data storage")
            #endif
            consentManager.requestConsentIfNeeded()
            return
        }

        do {
            try await secureStore.savePrediction(prediction, withNickname: nickname)
            #if DEBUG
            print("🔐 [DEBUG] Successfully saved encrypted prediction: \(prediction.displayName)")
            #endif
        } catch {
            #if DEBUG
            print("🔐 [DEBUG] Error saving encrypted prediction: \(error.localizedDescription)")
            #endif
            errorMessage = "Failed to save prediction securely: \(error.localizedDescription)"
        }
    }
    
    /// Delete a specific prediction from encrypted storage
    func deletePrediction(_ prediction: SavedPrediction) async {
        do {
            try await secureStore.deletePrediction(prediction)
            #if DEBUG
            print("🔐 [DEBUG] Successfully deleted encrypted prediction: \(prediction.displayName)")
            #endif
        } catch {
            #if DEBUG
            print("🔐 [DEBUG] Error deleting encrypted prediction: \(error.localizedDescription)")
            #endif
            errorMessage = "Failed to delete prediction securely: \(error.localizedDescription)"
        }
    }

    /// Update prediction nickname (requires re-encryption)
    func updatePredictionNickname(_ predictionId: UUID, nickname: String) async {
        guard let index = savedPredictions.firstIndex(where: { $0.id == predictionId }) else {
            errorMessage = "Prediction not found"
            return
        }

        // Create updated prediction with new nickname
        var updatedPrediction = savedPredictions[index]
        // Note: Since SavedPrediction is a struct, we would need to recreate it
        // For now, disable this functionality as it requires more complex implementation
        errorMessage = "Nickname updates require rebuilding the prediction data and are temporarily disabled"
    }

    /// Clear all medical predictions (with user confirmation)
    func clearAllPredictions() async {
        await secureStore.deleteAllData()
        #if DEBUG
        print("🔐 [DEBUG] Successfully cleared all encrypted medical data")
        #endif
    }

    /// Request user consent before storing medical data
    func requestConsentForDataStorage() {
        consentManager.requestConsentIfNeeded()
    }

    /// Export medical data for user review
    func exportMedicalDataForReview() -> [String: Any] {
        return secureStore.exportMedicalDataForReview()
    }
    
    // MARK: - Private Methods

    /// Check if user consent is still valid and request renewal if needed
    private func validateConsent() async {
        if consentManager.checkConsentStatus() && !consentManager.isConsentCurrent() {
            #if DEBUG
            print("🔔 PredictionPersistenceService: Medical data consent has expired")
            #endif
            consentManager.requestConsentIfNeeded()
        }
    }
    
    // Helper methods to recreate objects from saved data
    private func createInputsFromSavedPrediction(_ prediction: SavedPrediction) throws -> IVFOutcomePredictor.PredictionInputs {
        guard let diagnosisType = IVFOutcomePredictor.PredictionInputs.DiagnosisType(rawValue: prediction.diagnosisType) else {
            throw PersistenceError.invalidDiagnosisType
        }
        
        return IVFOutcomePredictor.PredictionInputs(
            age: prediction.age,
            amhLevel: prediction.amhLevel ?? 2.0, // Use dummy value if nil (post-retrieval)
            estrogenLevel: prediction.estrogenLevelInPgML ?? 2000, // Use dummy value if nil (post-retrieval)
            bmI: prediction.bmi,
            priorCycles: 0,
            diagnosisType: diagnosisType,
            maleFactor: nil
        )
    }
    
    func createResultsFromSavedPrediction(_ prediction: SavedPrediction) throws -> IVFOutcomePredictor.PredictionResults {
        #if DEBUG
        print("📱 [DEBUG] createResultsFromSavedPrediction called for: \(prediction.displayName)")
        #endif
        print("📱 [DEBUG] Expected Oocytes: \(prediction.expectedOocytes)")
        print("📱 [DEBUG] Mature Oocytes: \(prediction.matureOocytes)")
        print("📱 [DEBUG] Day 3 Embryos: \(prediction.day3Embryos)")
        print("📱 [DEBUG] IVF Blastocysts: \(prediction.ivfBlastocysts)")
        print("📱 [DEBUG] ICSI Blastocysts: \(prediction.icsiBlastocysts)")
        
        // Create simplified results structure for display purposes
        // Note: This is a simplified version - full results would require re-running the prediction
        
        let oocyteOutcome = IVFOutcomePredictor.PredictionResults.OocyteOutcome(
            predicted: prediction.expectedOocytes,
            range: (prediction.expectedOocytes * 0.8)...(prediction.expectedOocytes * 1.2),
            percentile: "75th percentile"
        )
        
        let fertilizationOutcome = IVFOutcomePredictor.PredictionResults.FertilizationOutcome(
            conventionalIVF: IVFOutcomePredictor.PredictionResults.FertilizationOutcome.IVFResult(
                predicted: prediction.ivfFertilizedEmbryos,
                range: (prediction.ivfFertilizedEmbryos * 0.8)...(prediction.ivfFertilizedEmbryos * 1.2),
                fertilizationRate: 0.65,
                explanation: "Conventional IVF fertilization"
            ),
            icsi: IVFOutcomePredictor.PredictionResults.FertilizationOutcome.ICSIResult(
                predicted: prediction.expectedFertilization,
                range: (prediction.expectedFertilization * 0.8)...(prediction.expectedFertilization * 1.2),
                fertilizationRate: 0.72,
                explanation: "ICSI fertilization"
            ),
            procedureComparison: "ICSI",
            explanation: "Restored from saved prediction"
        )
        
        let blastocystOutcome = IVFOutcomePredictor.PredictionResults.BlastocystOutcome(
            predicted: prediction.expectedBlastocysts,
            range: (prediction.expectedBlastocysts * 0.7)...(prediction.expectedBlastocysts * 1.3),
            developmentRate: 0.6
        )
        
        let euploidyOutcome = IVFOutcomePredictor.PredictionResults.EuploidyOutcome(
            euploidPercentage: 0.6,
            range: 0.5...0.7,
            expectedEuploidBlastocysts: prediction.expectedEuploidBlastocysts
        )
        
        let cascadeFlow = IVFOutcomePredictor.PredictionResults.CascadeFlow(
            totalOocytes: prediction.expectedOocytes,
            matureOocytes: prediction.matureOocytes,
            fertilizedEmbryos: prediction.expectedFertilization,
            day3Embryos: prediction.day3Embryos,
            blastocysts: prediction.expectedBlastocysts,
            euploidBlastocysts: prediction.expectedEuploidBlastocysts,
            aneuploidBlastocysts: prediction.expectedBlastocysts - prediction.expectedEuploidBlastocysts,
            stageLosses: IVFOutcomePredictor.PredictionResults.CascadeFlow.StageLosses(
                immatureOocytes: prediction.expectedOocytes - prediction.matureOocytes,
                fertilizationFailure: prediction.matureOocytes - prediction.expectedFertilization,
                day3Arrest: prediction.expectedFertilization - prediction.day3Embryos,
                blastocystArrest: prediction.day3Embryos - prediction.expectedBlastocysts,
                chromosomalAbnormalities: prediction.expectedBlastocysts - prediction.expectedEuploidBlastocysts
            ),
            ivfPathway: IVFOutcomePredictor.PredictionResults.CascadeFlow.FertilizationPathway(
                fertilizedEmbryos: prediction.ivfFertilizedEmbryos,
                fertilizationRate: 0.65, // Use standard fertilization rates instead of calculated ones
                day3Embryos: prediction.ivfDay3Embryos,
                blastocysts: prediction.ivfBlastocysts,
                euploidBlastocysts: prediction.ivfEuploidBlastocysts,
                finalOutcome: prediction.ivfFinalOutcome
            ),
            icsiPathway: IVFOutcomePredictor.PredictionResults.CascadeFlow.FertilizationPathway(
                fertilizedEmbryos: prediction.icsiFertilizedEmbryos,
                fertilizationRate: 0.72, // Use standard fertilization rates instead of calculated ones
                day3Embryos: prediction.icsiDay3Embryos,
                blastocysts: prediction.icsiBlastocysts,
                euploidBlastocysts: prediction.icsiEuploidBlastocysts,
                finalOutcome: prediction.icsiFinalOutcome
            )
        )
        
        guard let confidenceLevel = IVFOutcomePredictor.PredictionResults.ConfidenceLevel(rawValue: prediction.confidenceLevel) else {
            throw PersistenceError.invalidConfidenceLevel
        }
        
        return IVFOutcomePredictor.PredictionResults(
            expectedOocytes: oocyteOutcome,
            expectedFertilization: fertilizationOutcome,
            expectedBlastocysts: blastocystOutcome,
            euploidyRates: euploidyOutcome,
            cascadeFlow: cascadeFlow,
            confidenceLevel: confidenceLevel,
            clinicalNotes: ["Restored from saved prediction"],
            references: ["Previously generated prediction"]
        )
    }
}

// MARK: - Error Types

enum PersistenceError: LocalizedError {
    case invalidDiagnosisType
    case invalidConfidenceLevel
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .invalidDiagnosisType:
            return "Invalid diagnosis type in saved data"
        case .invalidConfidenceLevel:
            return "Invalid confidence level in saved data"
        case .dataCorruption:
            return "Saved prediction data is corrupted"
        }
    }
}