//
//  SavedPrediction.swift
//  Synagamy3.0
//
//  Data model for saved IVF outcome predictions
//

import Foundation

struct SavedPrediction: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let nickname: String? // Optional user-friendly name
    
    // Input parameters
    let age: Double
    let amhLevel: Double? // Optional for post-retrieval calculations
    let amhUnit: String?
    let estrogenLevel: Double? // Original input value - Optional for post-retrieval
    let estrogenLevelInPgML: Double? // Converted value for calculations - Optional for post-retrieval
    let estrogenUnit: String?
    let bmi: Double?
    let diagnosisType: String
    let calculationMode: String
    let retrievedOocytes: Double? // For post-retrieval calculations
    
    // Key results (simplified for storage)
    let expectedOocytes: Double
    let expectedFertilization: Double
    let expectedBlastocysts: Double
    let expectedEuploidBlastocysts: Double
    let confidenceLevel: String
    
    // Cascade flow results - comprehensive data for accurate reconstruction
    let matureOocytes: Double
    let day3Embryos: Double
    let ivfFertilizedEmbryos: Double
    let icsiFertilizedEmbryos: Double
    let ivfDay3Embryos: Double
    let icsiDay3Embryos: Double
    let ivfBlastocysts: Double
    let icsiBlastocysts: Double
    let ivfEuploidBlastocysts: Double
    let icsiEuploidBlastocysts: Double
    let ivfFinalOutcome: Double
    let icsiFinalOutcome: Double
    
    init(
        nickname: String? = nil,
        inputs: IVFOutcomePredictor.PredictionInputs,
        results: IVFOutcomePredictor.PredictionResults,
        calculationMode: String,
        amhUnit: String?,
        estrogenUnit: String?,
        originalEstrogenValue: Double?,
        retrievedOocytes: Double? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.nickname = nickname
        
        // Store inputs
        self.age = inputs.age
        self.amhLevel = originalEstrogenValue != nil ? inputs.amhLevel : nil // Only store if we have real values
        self.amhUnit = amhUnit
        self.estrogenLevel = originalEstrogenValue // Store the original input (nil for post-retrieval)
        self.estrogenLevelInPgML = originalEstrogenValue != nil ? inputs.estrogenLevel : nil // Only store if we have real values
        self.estrogenUnit = estrogenUnit
        self.bmi = inputs.bmI
        self.diagnosisType = inputs.diagnosisType.rawValue
        self.calculationMode = calculationMode
        self.retrievedOocytes = retrievedOocytes
        
        // Store key results
        self.expectedOocytes = results.expectedOocytes.predicted
        self.expectedFertilization = results.expectedFertilization.icsi.predicted
        self.expectedBlastocysts = results.expectedBlastocysts.predicted
        self.expectedEuploidBlastocysts = results.euploidyRates.expectedEuploidBlastocysts
        self.confidenceLevel = results.confidenceLevel.rawValue
        
        // Store comprehensive cascade flow results
        self.matureOocytes = results.cascadeFlow.matureOocytes
        self.day3Embryos = results.cascadeFlow.day3Embryos
        self.ivfFertilizedEmbryos = results.cascadeFlow.ivfPathway.fertilizedEmbryos
        self.icsiFertilizedEmbryos = results.cascadeFlow.icsiPathway.fertilizedEmbryos
        self.ivfDay3Embryos = results.cascadeFlow.ivfPathway.day3Embryos
        self.icsiDay3Embryos = results.cascadeFlow.icsiPathway.day3Embryos
        self.ivfBlastocysts = results.cascadeFlow.ivfPathway.blastocysts
        self.icsiBlastocysts = results.cascadeFlow.icsiPathway.blastocysts
        self.ivfEuploidBlastocysts = results.cascadeFlow.ivfPathway.euploidBlastocysts
        self.icsiEuploidBlastocysts = results.cascadeFlow.icsiPathway.euploidBlastocysts
        self.ivfFinalOutcome = results.cascadeFlow.ivfPathway.finalOutcome
        self.icsiFinalOutcome = results.cascadeFlow.icsiPathway.finalOutcome
        
        // Debug logging for cascade values
        print("📱 [DEBUG] SavedPrediction storing cascade data:")
        print("📱 [DEBUG] - Mature Oocytes: \(self.matureOocytes)")
        print("📱 [DEBUG] - Day 3 Embryos: \(self.day3Embryos)")
        print("📱 [DEBUG] - IVF Blastocysts: \(self.ivfBlastocysts)")
        print("📱 [DEBUG] - ICSI Blastocysts: \(self.icsiBlastocysts)")
    }
    
    // Computed properties for display
    var displayName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Prediction \(formatter.string(from: timestamp))"
    }
    
    var ageDisplay: String {
        return "\(Int(age)) years"
    }
    
    var summaryText: String {
        let diagnosisText = diagnosisType.replacingOccurrences(of: "Factor", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        
        if let amhLevel = amhLevel, let amhUnit = amhUnit {
            let amhText = String(format: "%.1f %@", amhLevel, amhUnit)
            return "\(ageDisplay) • AMH \(amhText) • \(diagnosisText)"
        } else if let retrievedOocytes = retrievedOocytes {
            return "\(ageDisplay) • \(Int(retrievedOocytes)) oocytes retrieved • \(diagnosisText)"
        } else {
            return "\(ageDisplay) • \(diagnosisText)"
        }
    }
}