//
//  EnhancedMedicalValidator.swift
//  Synagamy3.0
//
//  Enhanced medical validation system for IVF predictions with comprehensive
//  safety checks, edge case handling, and clinical confidence assessment.
//

import Foundation

// Forward declarations for types used in validation
// Note: CalculationMode and DiagnosisType are now defined in the calling view to avoid circular dependencies


/// Enhanced medical validation for IVF predictions with safety guardrails
struct EnhancedMedicalValidator {

    // MARK: - Validation Result Types

    struct MedicalValidationResult {
        let isValid: Bool
        let isSafe: Bool
        let validatedInputs: ValidatedInputs?
        let errors: [MedicalError]
        let warnings: [MedicalWarning]
        let confidence: ClinicalConfidence
        let safetyFlags: [SafetyFlag]
        enum ClinicalConfidence {
            case high, medium, low, insufficient

            var description: String {
                switch self {
                case .high: return "High clinical confidence"
                case .medium: return "Moderate confidence - verify with clinician"
                case .low: return "Low confidence - clinical consultation recommended"
                case .insufficient: return "Insufficient data for reliable prediction"
                }
            }
        }
    }

    struct ValidatedInputs {
        let age: Double
        let amhLevel: Double
        let estrogenLevel: Double
        let bmi: Double
        let priorCycles: Int
        let diagnosisType: String
        let oocyteCount: Double?
    }

    struct MedicalError {
        let field: String
        let message: String
        let severity: Severity

        enum Severity {
            case critical, high, medium

            var description: String {
                switch self {
                case .critical: return "Critical Error"
                case .high: return "High Priority Error"
                case .medium: return "Validation Error"
                }
            }
        }
    }

    struct MedicalWarning {
        let field: String
        let message: String
        let clinicalImpact: ClinicalImpact

        enum ClinicalImpact {
            case high, medium, low, informational

            var description: String {
                switch self {
                case .high: return "May significantly affect prediction accuracy"
                case .medium: return "May moderately affect prediction accuracy"
                case .low: return "Minor impact on prediction accuracy"
                case .informational: return "Additional clinical consideration"
                }
            }
        }
    }

    struct SafetyFlag {
        let type: SafetyType
        let message: String

        enum SafetyType {
            case extremeValues, inconsistentData, clinicalRisk, predictionLimits

            var description: String {
                switch self {
                case .extremeValues: return "Extreme Values Detected"
                case .inconsistentData: return "Data Inconsistency"
                case .clinicalRisk: return "Clinical Risk Factor"
                case .predictionLimits: return "Prediction Model Limits"
                }
            }
        }
    }

    // MARK: - Primary Validation Method

    static func validateMedicalInputs(
        age: String,
        amhLevel: String,
        amhUnit: String, // Pass as string to avoid dependency
        estrogenLevel: String,
        estrogenUnit: String, // Pass as string to avoid dependency
        retrievedOocytes: String?,
        bmi: String,
        selectedDiagnosis: String, // Pass as string to avoid dependency
        calculationMode: String // Pass as string to avoid dependency
    ) -> MedicalValidationResult {

        var errors: [MedicalError] = []
        var warnings: [MedicalWarning] = []
        var safetyFlags: [SafetyFlag] = []

        // Step 1: Individual field validation using built-in logic
        let ageValidation = validateAge(age)
        let amhValidation = validateAMH(amhLevel, unit: amhUnit)
        let estrogenValidation = validateEstrogen(estrogenLevel, unit: estrogenUnit)
        let bmiValidation = validateBMI(bmi)

        // Process age validation
        if !ageValidation.isValid {
            errors.append(MedicalError(
                field: "age",
                message: ageValidation.errorMessage ?? "Invalid age",
                severity: .high
            ))
        } else if let warningMessage = ageValidation.warningMessage {
            warnings.append(MedicalWarning(
                field: "age",
                message: warningMessage,
                clinicalImpact: ageValidation.confidence == .low ? .high : .medium
            ))
        }

        // Process AMH validation
        if !amhValidation.isValid {
            errors.append(MedicalError(
                field: "amh",
                message: amhValidation.errorMessage ?? "Invalid AMH level",
                severity: .high
            ))
        } else if let warningMessage = amhValidation.warningMessage {
            warnings.append(MedicalWarning(
                field: "amh",
                message: warningMessage,
                clinicalImpact: .medium
            ))
        }

        // Process estrogen validation
        if !estrogenValidation.isValid {
            errors.append(MedicalError(
                field: "estrogen",
                message: estrogenValidation.errorMessage ?? "Invalid estrogen level",
                severity: .medium
            ))
        } else if let warningMessage = estrogenValidation.warningMessage {
            warnings.append(MedicalWarning(
                field: "estrogen",
                message: warningMessage,
                clinicalImpact: .medium
            ))
        }

        // Process BMI validation
        if !bmiValidation.isValid {
            errors.append(MedicalError(
                field: "bmi",
                message: bmiValidation.errorMessage ?? "Invalid BMI",
                severity: .medium
            ))
        } else if let warningMessage = bmiValidation.warningMessage {
            warnings.append(MedicalWarning(
                field: "bmi",
                message: warningMessage,
                clinicalImpact: .medium
            ))
        }

        // Handle oocyte count for post-retrieval mode
        var oocyteValidation: ValidationResult?
        if calculationMode == "Post-Retrieval", let oocytes = retrievedOocytes {
            oocyteValidation = validateOocyteCount(oocytes)
            if !oocyteValidation!.isValid {
                errors.append(MedicalError(
                    field: "oocytes",
                    message: oocyteValidation!.errorMessage ?? "Invalid oocyte count",
                    severity: .high
                ))
            } else if let warningMessage = oocyteValidation!.warningMessage {
                warnings.append(MedicalWarning(
                    field: "oocytes",
                    message: warningMessage,
                    clinicalImpact: .medium
                ))
            }
        }

        // Step 2: Cross-field validation if individual validations pass
        if ageValidation.isValid && amhValidation.isValid,
           let ageValue = ageValidation.normalizedValue,
           let amhValue = amhValidation.normalizedValue {

            // Basic cross-field validation
            if ageValue > 40 && amhValue < 1.0 {
                warnings.append(MedicalWarning(
                    field: "combination",
                    message: "Advanced age with low AMH significantly reduces success probability",
                    clinicalImpact: .high
                ))
            }
        }

        // Step 3: Enhanced safety checks
        performEnhancedSafetyChecks(
            ageValidation: ageValidation,
            amhValidation: amhValidation,
            estrogenValidation: estrogenValidation,
            bmiValidation: bmiValidation,
            oocyteValidation: oocyteValidation,
            diagnosis: selectedDiagnosis,
            safetyFlags: &safetyFlags,
            warnings: &warnings
        )

        // Step 4: Calculate overall confidence
        let confidence = calculateOverallConfidence(
            ageValidation: ageValidation,
            amhValidation: amhValidation,
            estrogenValidation: estrogenValidation,
            bmiValidation: bmiValidation,
            oocyteValidation: oocyteValidation,
            errors: errors,
            warnings: warnings,
            safetyFlags: safetyFlags
        )

        // Step 5: Create inputs if validation passes
        var validatedInputs: ValidatedInputs?
        let isValid = errors.isEmpty
        let isSafe = !safetyFlags.contains { flag in
            flag.type == .clinicalRisk || flag.type == .extremeValues
        }

        if isValid,
           let ageValue = ageValidation.normalizedValue,
           let amhValue = amhValidation.normalizedValue,
           let bmiValue = bmiValidation.normalizedValue {

            // Convert AMH to ng/mL (simplified - assume already in ng/mL for now)
            let amhInNgML = amhValue

            // Convert estrogen to pg/mL (simplified - assume already in pg/mL for now)
            let estrogenInPgML = estrogenValidation.normalizedValue ?? 0

            // Extract oocyte count if provided
            let oocyteCount = oocyteValidation?.normalizedValue

            validatedInputs = ValidatedInputs(
                age: ageValue,
                amhLevel: amhInNgML,
                estrogenLevel: estrogenInPgML,
                bmi: bmiValue,
                priorCycles: 0, // Default to 0, could be added as input later
                diagnosisType: selectedDiagnosis,
                oocyteCount: oocyteCount
            )
        }

        return MedicalValidationResult(
            isValid: isValid,
            isSafe: isSafe,
            validatedInputs: validatedInputs,
            errors: errors,
            warnings: warnings,
            confidence: confidence,
            safetyFlags: safetyFlags
        )
    }

    // MARK: - Enhanced Safety Checks

    private static func performEnhancedSafetyChecks(
        ageValidation: ValidationResult,
        amhValidation: ValidationResult,
        estrogenValidation: ValidationResult,
        bmiValidation: ValidationResult,
        oocyteValidation: ValidationResult?,
        diagnosis: String,
        safetyFlags: inout [SafetyFlag],
        warnings: inout [MedicalWarning]
    ) {

        // Check for extreme age-AMH combinations
        if let age = ageValidation.normalizedValue,
           let amh = amhValidation.normalizedValue {

            // Very young with very low AMH
            if age < 25 && amh < 0.5 {
                safetyFlags.append(SafetyFlag(
                    type: .clinicalRisk,
                    message: "Unusually low AMH for young age - consider genetic counseling"
                ))
            }

            // Advanced age with high AMH
            if age > 42 && amh > 4.0 {
                safetyFlags.append(SafetyFlag(
                    type: .inconsistentData,
                    message: "High AMH at advanced age - verify test results"
                ))
            }

            // Very advanced age
            if age > 45 {
                safetyFlags.append(SafetyFlag(
                    type: .predictionLimits,
                    message: "Prediction accuracy limited for age >45 years"
                ))
            }
        }

        // Check estrogen safety thresholds
        if let estrogen = estrogenValidation.normalizedValue, estrogen > 0 {
            if estrogen > 5000 { // Assuming pg/mL
                safetyFlags.append(SafetyFlag(
                    type: .clinicalRisk,
                    message: "Very high estradiol levels increase OHSS risk"
                ))
            }
        }

        // Check BMI extreme values
        if let bmi = bmiValidation.normalizedValue {
            if bmi < 16 || bmi > 40 {
                safetyFlags.append(SafetyFlag(
                    type: .clinicalRisk,
                    message: "Extreme BMI may significantly affect treatment outcomes"
                ))
            }
        }

        // Check oocyte count extremes
        if let oocyteCount = oocyteValidation?.normalizedValue {
            if oocyteCount > 30 {
                safetyFlags.append(SafetyFlag(
                    type: .clinicalRisk,
                    message: "Very high oocyte count increases OHSS risk"
                ))
            } else if oocyteCount == 0 {
                safetyFlags.append(SafetyFlag(
                    type: .predictionLimits,
                    message: "No oocytes retrieved - prediction not applicable"
                ))
            }
        }

        // Diagnosis-specific safety checks
        switch diagnosis {
        case "Endometriosis Stage III-IV":
            warnings.append(MedicalWarning(
                field: "diagnosis",
                message: "Severe endometriosis may reduce prediction accuracy",
                clinicalImpact: .medium
            ))

        case "Tubal Factor with Hydrosalpinx":
            warnings.append(MedicalWarning(
                field: "diagnosis",
                message: "Hydrosalpinx presence may affect implantation rates",
                clinicalImpact: .medium
            ))

        case "Diminished Ovarian Reserve":
            safetyFlags.append(SafetyFlag(
                type: .predictionLimits,
                message: "DOR diagnosis requires careful clinical interpretation of predictions"
            ))

        default:
            break
        }
    }

    // MARK: - Confidence Calculation

    private static func calculateOverallConfidence(
        ageValidation: ValidationResult,
        amhValidation: ValidationResult,
        estrogenValidation: ValidationResult,
        bmiValidation: ValidationResult,
        oocyteValidation: ValidationResult?,
        errors: [MedicalError],
        warnings: [MedicalWarning],
        safetyFlags: [SafetyFlag]
    ) -> MedicalValidationResult.ClinicalConfidence {

        // Start with high confidence
        var confidenceScore = 100

        // Reduce for errors
        confidenceScore -= errors.count * 30

        // Reduce for validation confidence levels
        let validations = [ageValidation, amhValidation, estrogenValidation, bmiValidation]
            .compactMap { $0 }

        for validation in validations {
            switch validation.confidence {
            case .high:
                break // No reduction
            case .medium:
                confidenceScore -= 10
            case .low:
                confidenceScore -= 20
            case .insufficient:
                confidenceScore -= 30
            }
        }

        // Reduce for warnings
        let highImpactWarnings = warnings.filter { $0.clinicalImpact == .high }.count
        let mediumImpactWarnings = warnings.filter { $0.clinicalImpact == .medium }.count

        confidenceScore -= highImpactWarnings * 15
        confidenceScore -= mediumImpactWarnings * 8

        // Reduce for safety flags
        let clinicalRiskFlags = safetyFlags.filter { $0.type == .clinicalRisk }.count
        let predictionLimitFlags = safetyFlags.filter { $0.type == .predictionLimits }.count

        confidenceScore -= clinicalRiskFlags * 20
        confidenceScore -= predictionLimitFlags * 15

        // Determine final confidence level
        switch confidenceScore {
        case 80...100:
            return .high
        case 60...79:
            return .medium
        case 30...59:
            return .low
        default:
            return .insufficient
        }
    }

    // MARK: - Built-in Validation Methods

    private static func validateAge(_ age: String) -> ValidationResult {
        guard let ageValue = Double(age.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Please enter a valid age", warningMessage: nil)
        }

        guard ageValue >= 12 && ageValue <= 55 else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Age must be between 12 and 55 years", warningMessage: nil)
        }

        let confidence: ValidationConfidence
        let warningMessage: String?

        if ageValue > 42 {
            confidence = .low
            warningMessage = "Advanced maternal age may significantly impact success rates"
        } else if ageValue > 37 {
            confidence = .medium
            warningMessage = "Age over 37 may reduce success rates"
        } else {
            confidence = .high
            warningMessage = nil
        }

        return ValidationResult(isValid: true, normalizedValue: ageValue, confidence: confidence, errorMessage: nil, warningMessage: warningMessage)
    }

    private static func validateAMH(_ amh: String, unit: String) -> ValidationResult {
        guard let amhValue = Double(amh.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Please enter a valid AMH level", warningMessage: nil)
        }

        guard amhValue >= 0 && amhValue <= 50 else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "AMH level out of reasonable range", warningMessage: nil)
        }

        let confidence: ValidationConfidence
        let warningMessage: String?

        if amhValue < 1.0 {
            confidence = .low
            warningMessage = "Low AMH suggests diminished ovarian reserve"
        } else if amhValue > 15.0 {
            confidence = .medium
            warningMessage = "Very high AMH may indicate PCOS"
        } else {
            confidence = .high
            warningMessage = nil
        }

        return ValidationResult(isValid: true, normalizedValue: amhValue, confidence: confidence, errorMessage: nil, warningMessage: warningMessage)
    }

    private static func validateEstrogen(_ estrogen: String, unit: String) -> ValidationResult {
        guard let estrogenValue = Double(estrogen.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Please enter a valid estrogen level", warningMessage: nil)
        }

        guard estrogenValue >= 0 && estrogenValue <= 20000 else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Estrogen level out of reasonable range", warningMessage: nil)
        }

        let confidence: ValidationConfidence
        let warningMessage: String?

        if estrogenValue > 5000 {
            confidence = .low
            warningMessage = "Very high estradiol levels increase OHSS risk"
        } else {
            confidence = .high
            warningMessage = nil
        }

        return ValidationResult(isValid: true, normalizedValue: estrogenValue, confidence: confidence, errorMessage: nil, warningMessage: warningMessage)
    }

    private static func validateBMI(_ bmi: String) -> ValidationResult {
        guard let bmiValue = Double(bmi.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Please enter a valid BMI", warningMessage: nil)
        }

        guard bmiValue >= 12 && bmiValue <= 60 else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "BMI out of reasonable range", warningMessage: nil)
        }

        let confidence: ValidationConfidence
        let warningMessage: String?

        if bmiValue < 18.5 || bmiValue > 35 {
            confidence = .low
            warningMessage = "Extreme BMI may significantly affect fertility outcomes"
        } else if bmiValue > 30 {
            confidence = .medium
            warningMessage = "High BMI may reduce fertility success rates"
        } else {
            confidence = .high
            warningMessage = nil
        }

        return ValidationResult(isValid: true, normalizedValue: bmiValue, confidence: confidence, errorMessage: nil, warningMessage: warningMessage)
    }

    private static func validateOocyteCount(_ oocytes: String) -> ValidationResult {
        guard let oocyteValue = Double(oocytes.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Please enter a valid oocyte count", warningMessage: nil)
        }

        guard oocyteValue >= 0 && oocyteValue <= 50 else {
            return ValidationResult(isValid: false, normalizedValue: nil, confidence: .insufficient, errorMessage: "Oocyte count out of reasonable range", warningMessage: nil)
        }

        let confidence: ValidationConfidence
        let warningMessage: String?

        if oocyteValue > 30 {
            confidence = .low
            warningMessage = "Very high oocyte count increases OHSS risk"
        } else if oocyteValue == 0 {
            confidence = .insufficient
            warningMessage = "No oocytes retrieved - consider cycle cancellation"
        } else {
            confidence = .high
            warningMessage = nil
        }

        return ValidationResult(isValid: true, normalizedValue: oocyteValue, confidence: confidence, errorMessage: nil, warningMessage: warningMessage)
    }

    // MARK: - Validation Result Types

    struct ValidationResult {
        let isValid: Bool
        let normalizedValue: Double?
        let confidence: ValidationConfidence
        let errorMessage: String?
        let warningMessage: String?
    }

    enum ValidationConfidence {
        case high, medium, low, insufficient
    }
}

