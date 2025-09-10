//
//  PredictionPersistenceService.swift
//  Synagamy3.0
//
//  Service for persisting and managing saved IVF predictions
//

import Foundation
import Combine

@MainActor
class PredictionPersistenceService: ObservableObject {
    static let shared = PredictionPersistenceService()
    
    @Published var savedPredictions: [SavedPrediction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let predictionsKey = "SavedIVFPredictions"
    private let maxSavedPredictions = 20 // Limit to prevent excessive storage
    
    private init() {
        loadPredictions()
    }
    
    // MARK: - Public Methods
    
    func savePrediction(
        _ prediction: SavedPrediction,
        withNickname nickname: String? = nil
    ) async {
        print("📱 [DEBUG] Starting to save prediction: \(prediction.displayName)")
        isLoading = true
        errorMessage = nil
        
        do {
            // Add to beginning of array (most recent first)
            savedPredictions.insert(prediction, at: 0)
            
            // Limit the number of saved predictions
            if savedPredictions.count > maxSavedPredictions {
                savedPredictions = Array(savedPredictions.prefix(maxSavedPredictions))
            }
            
            try persistPredictions()
            print("📱 [DEBUG] Successfully saved prediction. Total saved: \(savedPredictions.count)")
            
        } catch {
            print("📱 [DEBUG] Error saving prediction: \(error.localizedDescription)")
            errorMessage = "Failed to save prediction: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deletePrediction(_ prediction: SavedPrediction) {
        savedPredictions.removeAll { $0.id == prediction.id }
        
        do {
            try persistPredictions()
        } catch {
            errorMessage = "Failed to delete prediction: \(error.localizedDescription)"
        }
    }
    
    func updatePredictionNickname(_ predictionId: UUID, nickname: String) {
        guard savedPredictions.contains(where: { $0.id == predictionId }) else {
            return
        }
        
        // Since SavedPrediction is a struct, we need to replace the entire object
        // For now, we'll keep the update functionality disabled to prevent data corruption
        // TODO: Implement proper nickname-only update mechanism
        errorMessage = "Nickname updates temporarily disabled to preserve data integrity"
    }
    
    func clearAllPredictions() {
        savedPredictions.removeAll()
        
        do {
            try persistPredictions()
        } catch {
            errorMessage = "Failed to clear predictions: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    private func loadPredictions() {
        print("📱 [DEBUG] Loading predictions from UserDefaults")
        guard let data = userDefaults.data(forKey: predictionsKey) else {
            print("📱 [DEBUG] No saved predictions data found")
            return
        }
        
        do {
            let loadedPredictions = try JSONDecoder().decode([SavedPrediction].self, from: data)
            
            // Check if predictions have the new cascade data fields
            // If any prediction is missing the new fields, clear all predictions to force regeneration
            if !loadedPredictions.isEmpty {
                // Try to access new cascade fields to see if they exist
                let firstPrediction = loadedPredictions[0]
                _ = firstPrediction.matureOocytes // This will cause decoding to fail if field doesn't exist
                _ = firstPrediction.day3Embryos
            }
            
            savedPredictions = loadedPredictions
            print("📱 [DEBUG] Loaded \(savedPredictions.count) predictions with complete cascade data")
        } catch {
            print("📱 [DEBUG] Failed to load saved predictions (likely due to model changes): \(error)")
            print("📱 [DEBUG] Clearing old prediction data to support new cascade structure")
            // Clear old/corrupted data due to model changes
            userDefaults.removeObject(forKey: predictionsKey)
            savedPredictions = []
        }
    }
    
    private func persistPredictions() throws {
        let data = try JSONEncoder().encode(savedPredictions)
        userDefaults.set(data, forKey: predictionsKey)
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
        print("📱 [DEBUG] createResultsFromSavedPrediction called for: \(prediction.displayName)")
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