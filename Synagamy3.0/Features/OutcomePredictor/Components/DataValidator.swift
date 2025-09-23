//
//  DataValidator.swift
//  Synagamy3.0
//
//  Comprehensive data validation with edge case handling
//

import Foundation

struct DataValidator {
    
    // MARK: - Validation Results
    
    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?
        let warningMessage: String?
        let normalizedValue: Double?
        let confidence: ValidationConfidence
        
        enum ValidationConfidence {
            case high, medium, low
            
            var description: String {
                switch self {
                case .high: return "High confidence in this value"
                case .medium: return "Moderate confidence - please verify"
                case .low: return "Low confidence - consider reviewing"
                }
            }
        }
        
        static func valid(value: Double, confidence: ValidationConfidence = .high) -> ValidationResult {
            ValidationResult(
                isValid: true,
                errorMessage: nil,
                warningMessage: nil,
                normalizedValue: value,
                confidence: confidence
            )
        }
        
        static func invalid(message: String) -> ValidationResult {
            ValidationResult(
                isValid: false,
                errorMessage: message,
                warningMessage: nil,
                normalizedValue: nil,
                confidence: .low
            )
        }
        
        static func warning(value: Double, message: String, confidence: ValidationConfidence = .medium) -> ValidationResult {
            ValidationResult(
                isValid: true,
                errorMessage: nil,
                warningMessage: message,
                normalizedValue: value,
                confidence: confidence
            )
        }
    }
    
    // MARK: - Age Validation
    
    static func validateAge(_ input: String) -> ValidationResult {
        // Handle empty input
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: "Age is required")
        }
        
        // Parse the input
        guard let age = Double(input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .invalid(message: "Please enter a valid number for age")
        }
        
        // Check basic range
        guard age >= 12 && age <= 55 else {
            if age < 12 {
                return .invalid(message: "This app is designed for individuals 12 years and older")
            } else {
                return .invalid(message: "Please enter an age between 12 and 55 years")
            }
        }
        
        // Age-specific warnings and confidence levels
        if age < 18 {
            return .warning(
                value: age,
                message: "Fertility predictions for individuals under 18 have limited data",
                confidence: .low
            )
        } else if age <= 25 {
            return .valid(value: age, confidence: .high)
        } else if age <= 35 {
            return .valid(value: age, confidence: .high)
        } else if age <= 40 {
            return .warning(
                value: age,
                message: "Consider discussing with your healthcare provider about fertility preservation",
                confidence: .medium
            )
        } else if age <= 45 {
            return .warning(
                value: age,
                message: "Fertility declines significantly after 40. Please consult with a fertility specialist",
                confidence: .medium
            )
        } else {
            return .warning(
                value: age,
                message: "Pregnancy success rates are very low after 45. Please seek specialized medical advice",
                confidence: .low
            )
        }
    }
    
    // MARK: - AMH Validation
    
    static func validateAMH(_ input: String, unit: AMHUnit) -> ValidationResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: "AMH level is required")
        }
        
        guard let amh = Double(input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .invalid(message: "Please enter a valid number for AMH")
        }
        
        guard amh >= 0 else {
            return .invalid(message: "AMH level cannot be negative")
        }
        
        // Convert to ng/mL for consistency
        let amhInNgML = amh * unit.toNgPerMLFactor
        
        // Extreme values check
        if amhInNgML > 50 {
            return .invalid(message: "AMH level seems unusually high. Please verify the value and units")
        }
        
        if amhInNgML < 0.01 {
            return .invalid(message: "AMH level is below detectable limits. Use 0.01 \(unit.displayName) if undetectable")
        }
        
        // Clinical interpretation with warnings
        if amhInNgML < 0.5 {
            return .warning(
                value: amh,
                message: "Very low AMH suggests severely diminished ovarian reserve. Consult with a fertility specialist",
                confidence: .medium
            )
        } else if amhInNgML < 1.0 {
            return .warning(
                value: amh,
                message: "Low AMH suggests diminished ovarian reserve",
                confidence: .medium
            )
        } else if amhInNgML <= 4.0 {
            return .valid(value: amh, confidence: .high)
        } else if amhInNgML <= 8.0 {
            return .valid(value: amh, confidence: .high)
        } else if amhInNgML <= 15.0 {
            return .warning(
                value: amh,
                message: "High AMH may indicate PCOS. Discuss with your healthcare provider",
                confidence: .medium
            )
        } else {
            return .warning(
                value: amh,
                message: "Very high AMH strongly suggests PCOS and increased OHSS risk",
                confidence: .medium
            )
        }
    }
    
    // MARK: - Estrogen Validation
    
    static func validateEstrogen(_ input: String, unit: EstrogenUnit) -> ValidationResult {
        // Estrogen is optional
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .valid(value: 0, confidence: .high) // Default to 0 if empty
        }
        
        guard let estrogen = Double(input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .invalid(message: "Please enter a valid number for estradiol")
        }
        
        guard estrogen >= 0 else {
            return .invalid(message: "Estradiol level cannot be negative")
        }
        
        // Convert to pg/mL for consistency
        let estrogenInPgML = estrogen * unit.toPgPerMLFactor
        
        // Extreme values check
        if estrogenInPgML > 20000 {
            return .invalid(message: "Estradiol level seems unusually high. Please verify the value and units")
        }
        
        // Clinical interpretation
        if estrogenInPgML < 50 {
            return .warning(
                value: estrogen,
                message: "Very low estradiol may indicate poor follicular development",
                confidence: .medium
            )
        } else if estrogenInPgML < 100 {
            return .warning(
                value: estrogen,
                message: "Low estradiol for stimulation cycle",
                confidence: .medium
            )
        } else if estrogenInPgML <= 4000 {
            return .valid(value: estrogen, confidence: .high)
        } else if estrogenInPgML <= 6000 {
            return .warning(
                value: estrogen,
                message: "High estradiol - monitor for OHSS risk",
                confidence: .medium
            )
        } else {
            return .warning(
                value: estrogen,
                message: "Very high estradiol - significant OHSS risk. Cycle may need modification",
                confidence: .low
            )
        }
    }
    
    // MARK: - Oocyte Count Validation
    
    static func validateOocyteCount(_ input: String) -> ValidationResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: "Oocyte count is required")
        }
        
        guard let count = Double(input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .invalid(message: "Please enter a valid number for oocyte count")
        }
        
        // Must be whole number
        guard count == floor(count) else {
            return .invalid(message: "Oocyte count must be a whole number")
        }
        
        guard count >= 0 else {
            return .invalid(message: "Oocyte count cannot be negative")
        }
        
        // Practical limits
        if count > 50 {
            return .invalid(message: "Oocyte count seems unusually high. Please verify")
        }
        
        // Clinical interpretation
        if count == 0 {
            return .warning(
                value: count,
                message: "No oocytes retrieved. Consider cycle cancellation factors",
                confidence: .medium
            )
        } else if count < 4 {
            return .warning(
                value: count,
                message: "Low oocyte yield may indicate poor ovarian response",
                confidence: .medium
            )
        } else if count <= 15 {
            return .valid(value: count, confidence: .high)
        } else if count <= 25 {
            return .warning(
                value: count,
                message: "Good response - monitor for OHSS symptoms",
                confidence: .medium
            )
        } else {
            return .warning(
                value: count,
                message: "Very high yield - significant OHSS risk",
                confidence: .medium
            )
        }
    }
    
    // MARK: - BMI Validation
    
    static func validateBMI(_ input: String) -> ValidationResult {
        // BMI is optional
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .valid(value: 22.0, confidence: .high) // Default to normal BMI
        }
        
        guard let bmi = Double(input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .invalid(message: "Please enter a valid number for BMI")
        }
        
        guard bmi > 0 else {
            return .invalid(message: "BMI must be greater than 0")
        }
        
        // Extreme values
        if bmi < 12 || bmi > 60 {
            return .invalid(message: "BMI value seems incorrect. Please verify")
        }
        
        // Clinical interpretation
        if bmi < 18.5 {
            return .warning(
                value: bmi,
                message: "Underweight BMI may affect fertility. Consider nutritional counseling",
                confidence: .medium
            )
        } else if bmi <= 24.9 {
            return .valid(value: bmi, confidence: .high)
        } else if bmi <= 29.9 {
            return .warning(
                value: bmi,
                message: "Overweight BMI may affect fertility outcomes",
                confidence: .medium
            )
        } else if bmi <= 34.9 {
            return .warning(
                value: bmi,
                message: "Obesity may significantly impact fertility treatment success",
                confidence: .medium
            )
        } else {
            return .warning(
                value: bmi,
                message: "Severe obesity substantially reduces fertility treatment success rates",
                confidence: .low
            )
        }
    }
    
    // MARK: - Cross-Field Validation
    
    static func validateInputCombination(
        age: Double,
        amh: Double,
        estrogen: Double?,
        diagnosis: String
    ) -> ValidationResult {
        
        // Age-AMH consistency check
        if age < 30 && amh < 1.0 {
            return .warning(
                value: age,
                message: "Low AMH at young age is unusual. Please verify AMH test results",
                confidence: .low
            )
        }
        
        if age > 42 && amh > 5.0 {
            return .warning(
                value: age,
                message: "High AMH at advanced age is uncommon. Please verify",
                confidence: .low
            )
        }
        
        // Estrogen-related checks
        if let estrogen = estrogen, estrogen > 0 {
            let expectedEstrogen = estimateExpectedEstrogen(amh: amh, age: age)
            let ratio = estrogen / expectedEstrogen
            
            if ratio < 0.3 {
                return .warning(
                    value: estrogen,
                    message: "Estradiol lower than expected for your AMH level",
                    confidence: .medium
                )
            } else if ratio > 3.0 {
                return .warning(
                    value: estrogen,
                    message: "Estradiol higher than expected - monitor for OHSS",
                    confidence: .medium
                )
            }
        }
        
        return .valid(value: age, confidence: .high)
    }
    
    // MARK: - Helper Functions
    
    private static func estimateExpectedEstrogen(amh: Double, age: Double) -> Double {
        // Simplified estimation based on typical ranges
        let baseEstrogen = max(200, amh * 300)
        let ageFactor = max(0.5, (45 - age) / 20)
        return baseEstrogen * ageFactor
    }
}

// MARK: - Unit Definitions

enum AMHUnit: String, CaseIterable {
    case ngPerML = "ng/mL"
    case pmolPerL = "pmol/L"
    
    var displayName: String { rawValue }
    
    var toNgPerMLFactor: Double {
        switch self {
        case .ngPerML: return 1.0
        case .pmolPerL: return 0.14 // Conversion factor
        }
    }
}

enum EstrogenUnit: String, CaseIterable {
    case pgPerML = "pg/mL"
    case pmolPerL = "pmol/L"
    
    var displayName: String { rawValue }
    
    var toPgPerMLFactor: Double {
        switch self {
        case .pgPerML: return 1.0
        case .pmolPerL: return 0.272 // Conversion factor
        }
    }
}

#if DEBUG
// MARK: - Test Cases

extension DataValidator {
    static func runTestCases() -> [String] {
        var results: [String] = []
        
        // Age tests
        let ageTests = [
            ("25", "Valid age"),
            ("17", "Young age warning"),
            ("45", "Advanced age warning"),
            ("abc", "Invalid format"),
            ("60", "Out of range")
        ]
        
        for (input, expected) in ageTests {
            let result = validateAge(input)
            results.append("Age '\(input)': \(result.isValid ? "Valid" : "Invalid") - \(expected)")
        }
        
        return results
    }
}
#endif