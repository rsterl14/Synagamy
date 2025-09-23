//
//  OutcomePredictorView.swift
//  Synagamy3.0
//
//  IVF Outcome Prediction Tool
//  ---------------------------
//  Interactive tool providing realistic expectations for IVF outcomes based on
//  age, AMH levels, estrogen, and diagnosis. Uses Canadian national averages
//  and CARTR-BORN data to generate personalized predictions.
//

import SwiftUI

// Import required services and models
// Note: The following imports reference files that should exist in the project

// Local enum definitions for UI components
enum CalculationMode: String, CaseIterable {
    case preRetrieval = "Pre-Retrieval"
    case postRetrieval = "Post-Retrieval"

    var displayName: String { self.rawValue }
    var description: String {
        switch self {
        case .preRetrieval:
            return "Predict Oocytes and All Subsequent Outcomes"
        case .postRetrieval:
            return "Enter Known Oocyte Count and Predict Remaining Stages"
        }
    }

}

enum DiagnosisType: String, CaseIterable {
    case unexplained = "Unexplained Infertility"
    case maleFactorMild = "Male Factor (Mild)"
    case maleFactorSevere = "Male Factor (Severe)"
    case ovulatory = "Ovulatory Disorders"
    case pcos = "PCOS"
    case tubalFactor = "Tubal Factor"
    case tubalFactorHydrosalpinx = "Tubal Factor with Hydrosalpinx"
    case endometriosisStage1_2 = "Endometriosis Stage I-II"
    case endometriosisStage3_4 = "Endometriosis Stage III-IV"
    case diminishedOvarianReserve = "Diminished Ovarian Reserve"
    case adenomyosis = "Adenomyosis"
    case multipleDiagnoses = "Multiple Diagnoses"
    case other = "Other"

    var displayName: String { self.rawValue }

    // Convert to IVFOutcomePredictor type when needed
    var ivfPredictorType: IVFOutcomePredictor.PredictionInputs.DiagnosisType {
        switch self {
        case .unexplained: return .unexplained
        case .maleFactorMild: return .maleFactorMild
        case .maleFactorSevere: return .maleFactorSevere
        case .ovulatory: return .ovulatory
        case .pcos: return .pcos
        case .tubalFactor: return .tubalFactor
        case .tubalFactorHydrosalpinx: return .tubalFactorHydrosalpinx
        case .endometriosisStage1_2: return .endometriosisStage1_2
        case .endometriosisStage3_4: return .endometriosisStage3_4
        case .diminishedOvarianReserve: return .diminishedOvarianReserve
        case .adenomyosis: return .adenomyosis
        case .multipleDiagnoses: return .multipleDiagnoses
        case .other: return .other
        }
    }

    // Convert from IVFOutcomePredictor type
    static func from(ivfType: IVFOutcomePredictor.PredictionInputs.DiagnosisType) -> DiagnosisType {
        switch ivfType {
        case .unexplained: return .unexplained
        case .maleFactorMild: return .maleFactorMild
        case .maleFactorSevere: return .maleFactorSevere
        case .ovulatory: return .ovulatory
        case .pcos: return .pcos
        case .tubalFactor: return .tubalFactor
        case .tubalFactorHydrosalpinx: return .tubalFactorHydrosalpinx
        case .endometriosisStage1_2: return .endometriosisStage1_2
        case .endometriosisStage3_4: return .endometriosisStage3_4
        case .diminishedOvarianReserve: return .diminishedOvarianReserve
        case .adenomyosis: return .adenomyosis
        case .multipleDiagnoses: return .multipleDiagnoses
        case .other: return .other
        }
    }

    // Convert from String
    static func from(string: String) -> DiagnosisType? {
        return DiagnosisType.allCases.first { $0.rawValue == string }
    }
}

struct OutcomePredictorView: View {
    // MARK: - Input State
    @State private var age: String = ""
    @State private var amhLevel: String = ""
    @State private var estrogenLevel: String = ""
    @State private var retrievedOocytes: String = ""
    @State private var bmi: String = ""
    @State private var selectedDiagnosis: DiagnosisType = .unexplained
    @State private var amhUnit: AMHUnit = .ngPerML
    @State private var estrogenUnit: EstrogenUnit = .pgPerML
    @State private var calculationMode: CalculationMode = .preRetrieval
    
    // MARK: - UI State
    @State private var showResults = false
    @State private var predictionResults: IVFOutcomePredictor.PredictionResults?
    @State private var isCascadeExpanded = false

    // MARK: - Enhanced Validation State
    @State private var validationResult: EnhancedMedicalValidator.MedicalValidationResult?
    @State private var showValidationDetails = false
    @State private var showSafetyWarning = false
    @State private var safetyWarningMessage = ""

    // Legacy validation messages (for backward compatibility)
    @State private var ageValidationMessage: String? = nil
    @State private var amhValidationMessage: String? = nil
    @State private var estrogenValidationMessage: String? = nil
    @State private var oocyteValidationMessage: String? = nil
    @State private var bmiValidationMessage: String? = nil
    
    
    // MARK: - Error Handling
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    // MARK: - Persistence
    @StateObject private var persistenceService = PredictionPersistenceService.shared
    @State private var showingSaveDialog = false
    @State private var predictionNickname = ""
    @State private var showingSavedPredictions = false
    @State private var selectedSavedPrediction: SavedPrediction?
    @State private var showingSavedCascade = false
    @State private var showingRegulatoryDisclaimer = false
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        // Use enhanced medical validator for comprehensive validation
        updateValidationResult()
        return validationResult?.isValid == true
    }

    private var isSafeForPrediction: Bool {
        // Check if inputs are both valid and safe for medical prediction
        return validationResult?.isSafe == true
    }

    // MARK: - Enhanced Validation Methods
    private func updateValidationResult() {
        let result = EnhancedMedicalValidator.validateMedicalInputs(
            age: age,
            amhLevel: amhLevel,
            amhUnit: amhUnit.rawValue,
            estrogenLevel: estrogenLevel,
            estrogenUnit: estrogenUnit.rawValue,
            retrievedOocytes: calculationMode == CalculationMode.postRetrieval ? retrievedOocytes : nil,
            bmi: bmi,
            selectedDiagnosis: selectedDiagnosis.rawValue,
            calculationMode: calculationMode.rawValue
        )

        validationResult = result

        // Update legacy validation messages for UI compatibility
        updateLegacyValidationMessages(from: result)

        // Check for safety warnings
        let hasUnsafeFlags = !result.safetyFlags.isEmpty
        let hasLowConfidence = (result.confidence == EnhancedMedicalValidator.MedicalValidationResult.ClinicalConfidence.low || result.confidence == EnhancedMedicalValidator.MedicalValidationResult.ClinicalConfidence.insufficient)

        if hasUnsafeFlags || hasLowConfidence {
            // Filter for critical safety flags
            let clinicalRiskFlags = result.safetyFlags.filter { $0.type == EnhancedMedicalValidator.SafetyFlag.SafetyType.clinicalRisk }
            let extremeValueFlags = result.safetyFlags.filter { $0.type == EnhancedMedicalValidator.SafetyFlag.SafetyType.extremeValues }
            let criticalFlags = clinicalRiskFlags + extremeValueFlags

            if !criticalFlags.isEmpty {
                safetyWarningMessage = criticalFlags.first?.message ?? "Clinical safety concern detected"
                showSafetyWarning = true
            }
        }
    }

    private func updateLegacyValidationMessages(from result: EnhancedMedicalValidator.MedicalValidationResult) {
        // Clear all messages first
        ageValidationMessage = nil
        amhValidationMessage = nil
        estrogenValidationMessage = nil
        oocyteValidationMessage = nil
        bmiValidationMessage = nil

        // Set error or warning messages for each field
        for error in result.errors {
            switch error.field {
            case "age":
                ageValidationMessage = error.message
            case "amh":
                amhValidationMessage = error.message
            case "estrogen":
                estrogenValidationMessage = error.message
            case "oocytes":
                oocyteValidationMessage = error.message
            case "bmi":
                bmiValidationMessage = error.message
            default:
                break
            }
        }

        // Set warning messages if no errors exist for the field
        for warning in result.warnings {
            switch warning.field {
            case "age" where ageValidationMessage == nil:
                ageValidationMessage = warning.message
            case "amh" where amhValidationMessage == nil:
                amhValidationMessage = warning.message
            case "estrogen" where estrogenValidationMessage == nil:
                estrogenValidationMessage = warning.message
            case "oocytes" where oocyteValidationMessage == nil:
                oocyteValidationMessage = warning.message
            case "bmi" where bmiValidationMessage == nil:
                bmiValidationMessage = warning.message
            default:
                break
            }
        }
    }
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "IVFSuccessLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    // Header
                    headerSection
                    
                    // Saved Predictions (if any)
                    if !persistenceService.savedPredictions.isEmpty {
                        savedPredictionsSection
                    }
                    
                    // Input Form
                    inputFormSection
                    
                    // Educational Purpose Warning
                    RegulatoryWarningView(severity: .standard, context: .dataEntry)

                    // Predict Button
                    predictButton
                    
                    // Results Section
                    if showResults, let results = predictionResults {
                        resultsSection(results)
                        
                        // Save Section
                        saveSection(results)
                    }
                }
                .padding(.vertical, Brand.Spacing.lg)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .foregroundColor(Brand.Color.primary)
                .font(Brand.Typography.labelLarge.weight(.medium))
            }
        }
        .enhancedErrorHandling(
            errorHandler: errorHandler,
            onRetry: {
                // Clear any validation state and allow retry
                showResults = false
                predictionResults = nil
            },
            onNavigateHome: {
                // This would typically be handled by the app's navigation system
                // For now, just clear the current state
                showResults = false
                predictionResults = nil
            }
        )
        .sheet(isPresented: $showingSaveDialog) {
            SavePredictionDialog(
                nickname: $predictionNickname,
                onSave: { nickname in
                    Task {
                        await savePrediction(withNickname: nickname)
                    }
                },
                onCancel: {
                    showingSaveDialog = false
                    predictionNickname = ""
                }
            )
        }
        .sheet(isPresented: $showingSavedPredictions) {
            SavedPredictionsView()
        }
        .sheet(isPresented: $showingSavedCascade) {
            if let savedPrediction = selectedSavedPrediction {
                SavedPredictionCascadeView(prediction: savedPrediction)
            }
        }
        .sheet(isPresented: $showingRegulatoryDisclaimer) {
            RegulatoryDisclaimerModal(isPresented: $showingRegulatoryDisclaimer)
        }
        .alert("Medical Safety Warning", isPresented: $showSafetyWarning) {
            Button("Understood", role: .cancel) {
                showSafetyWarning = false
            }
            Button("View Details", action: {
                showValidationDetails = true
            })
        } message: {
            Text(safetyWarningMessage)
        }
        .sheet(isPresented: $showValidationDetails) {
            MedicalValidationDetailsView(validation: validationResult)
        }
        .onAppear {
            // Show regulatory disclaimer on first use
            if !UserDefaults.standard.bool(forKey: "hasSeenRegulatoryDisclaimer") {
                showingRegulatoryDisclaimer = true
            }

            // VoiceOver announcement
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "IVF outcome predictor loaded. Enter your details to receive personalized success rate predictions."
                )
            }
        }
        .registerForAccessibilityAudit(
            viewName: "OutcomePredictorView",
            hasAccessibilityLabels: true,
            hasDynamicTypeSupport: true,
            hasVoiceOverSupport: true
        )
    }
    
    // MARK: - Keyboard Dismissal
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Brand.Spacing.md) {
            CategoryBadge(
                text: "IVF Outcome Predictor",
                icon: "chart.line.uptrend.xyaxis",
                color: Brand.Color.primary
            )
            
            Text("Personalized IVF Success Estimates")
                .font(Brand.Typography.headlineMedium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Based on Population Data. \n\n Individual Results can Vary From This Personalized IVF Success Estimator")
                .font(Brand.Typography.labelSmall)
                .foregroundColor(Brand.Color.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Saved Predictions Section
    private var savedPredictionsSection: some View {
        EnhancedContentBlock(
            title: "My Predictions",
            icon: "bookmark.fill"
        ) {
            VStack(spacing: Brand.Spacing.sm) {
                // Show recent predictions (max 3)
                ForEach(Array(persistenceService.savedPredictions.prefix(3))) { prediction in
                    SavedPredictionRowCompact(
                        prediction: prediction,
                        onTap: {
                            // Show cascade for this saved prediction
                            showSavedPredictionCascade(prediction)
                        },
                        onDelete: {
                            Task {
                                await persistenceService.deletePrediction(prediction)
                            }
                        }
                    )
                }
                
                // View All button if more than 3
                if persistenceService.savedPredictions.count > 3 {
                    Button {
                        showingSavedPredictions = true
                    } label: {
                        HStack {
                            Text("View All \(persistenceService.savedPredictions.count) Predictions")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(Brand.Color.primary)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Input Form Section
    private var inputFormSection: some View {
        EnhancedContentBlock(
            title: "Patient Parameters",
            icon: "person.text.rectangle"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                // Calculation Mode Selector
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    Text("Calculation Mode")
                        .font(Brand.Typography.labelLarge)
                        .foregroundColor(.primary)
                    
                    Picker("Calculation Mode", selection: $calculationMode) {
                        ForEach(CalculationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(calculationMode.description)
                        .font(Brand.Typography.labelSmall)
                        .foregroundColor(Brand.Color.secondary)
                }

                Divider()
                    .padding(.vertical, Brand.Spacing.xs)
                // Age Input
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    Text("Age (Years)")
                        .font(Brand.Typography.labelLarge)
                        .foregroundColor(.primary)
                    
                    TextField("Enter age (18-50)", text: $age)
                        .keyboardType(.decimalPad)
                        .font(Brand.Typography.bodyMedium)
                        .padding(.horizontal, Brand.Spacing.lg)
                        .padding(.vertical, Brand.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .stroke(ageValidationMessage != nil ? .red : Brand.Color.hairline, lineWidth: 1)
                        )
                        .onChange(of: age) { _, newValue in
                            validateAge(newValue)
                            if let message = ageValidationMessage, message.hasPrefix("✓") {
                                AccessibilityAnnouncement.announce("Age validation: \(message)")
                            }
                        }
                        .inputFieldAccessibility(
                            label: "Age in years",
                            value: age,
                            validationMessage: ageValidationMessage,
                            isRequired: true
                        )
                    
                    if let ageValidationMessage = ageValidationMessage {
                        Text(ageValidationMessage)
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(.red)
                    }
                    
                    Text("Age at Time of Oocyte Retrieval")
                        .font(Brand.Typography.labelSmall)
                        .foregroundColor(Brand.Color.secondary)
                }
                
                // Conditional inputs based on calculation mode
                if calculationMode == .preRetrieval {
                    // AMH Input
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        Text("AMH Level")
                            .font(Brand.Typography.labelLarge)
                            .foregroundColor(.primary)

                        HStack(spacing: Brand.Spacing.md) {
                            TextField("Enter AMH level", text: $amhLevel)
                                .keyboardType(.decimalPad)
                                .font(Brand.Typography.bodyMedium)
                                .padding(.horizontal, Brand.Spacing.lg)
                                .padding(.vertical, Brand.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                        .stroke(getValidationColor(amhValidationMessage), lineWidth: 1)
                                )
                            
                            Picker("AMH Unit", selection: $amhUnit) {
                                ForEach(AMHUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Brand.Color.primary)
                            .frame(minWidth: 80)
                        }
                        
                        if let amhValidationMessage = amhValidationMessage {
                            HStack {
                                if amhValidationMessage.hasPrefix("⚠️") {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(Brand.Typography.labelSmall)
                                } else if amhValidationMessage.hasPrefix("✓") {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(Brand.Typography.labelSmall)
                                }
                                
                                Text(amhValidationMessage)
                                    .font(Brand.Typography.labelSmall)
                                    .foregroundColor(getValidationTextColor(amhValidationMessage))
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("AMH validation: \(amhValidationMessage)")
                        } else {
                            Text("Anti-Müllerian Hormone Level")
                                .font(Brand.Typography.labelSmall)
                                .foregroundColor(Brand.Color.secondary)
                        }
                    }
                    
                    // Estrogen Input
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        Text("Peak Estradiol Level")
                            .font(Brand.Typography.labelLarge)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: Brand.Spacing.md) {
                            TextField("Enter estradiol level", text: $estrogenLevel)
                                .keyboardType(.decimalPad)
                                .font(Brand.Typography.bodyMedium)
                                .padding(.horizontal, Brand.Spacing.lg)
                                .padding(.vertical, Brand.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                        .stroke(Brand.Color.hairline, lineWidth: 1)
                                )
                            
                            Picker("Estrogen Unit", selection: $estrogenUnit) {
                                ForEach(EstrogenUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Brand.Color.primary)
                            .frame(minWidth: 80)
                        }
                        
                        Text("Peak Estradiol on Trigger Day")
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(Brand.Color.secondary)
                    }
                } else {
                    // Retrieved Oocytes Input (for post-retrieval mode)
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        Text("Retrieved Oocytes")
                            .font(Brand.Typography.labelLarge)
                            .foregroundColor(.primary)
                        
                        TextField("Enter number of retrieved oocytes", text: $retrievedOocytes)
                            .keyboardType(.decimalPad)
                            .font(Brand.Typography.bodyMedium)
                            .padding(.horizontal, Brand.Spacing.lg)
                            .padding(.vertical, Brand.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                    .stroke(Brand.Color.hairline, lineWidth: 1)
                            )
                        
                        Text("Total Oocytes Retrieved During Your Cycle")
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(Brand.Color.secondary)
                    }
                }
                
                // Diagnosis Picker
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    Text("Primary Diagnosis")
                        .font(Brand.Typography.labelLarge)
                        .foregroundColor(.primary)
                    
                    Menu {
                        ForEach(IVFOutcomePredictor.PredictionInputs.DiagnosisType.allCases, id: \.self) { diagnosis in
                            Button(diagnosis.displayName) {
                                selectedDiagnosis = DiagnosisType.from(ivfType: diagnosis)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedDiagnosis.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(Brand.Color.primary)
                                .font(Brand.Typography.labelSmall.weight(.medium))
                        }
                        .font(Brand.Typography.bodyMedium)
                        .padding(.horizontal, Brand.Spacing.lg)
                        .padding(.vertical, Brand.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .stroke(Brand.Color.hairline, lineWidth: 1)
                        )
                    }
                    
                    Text("Underlying Fertility Diagnosis")
                        .font(Brand.Typography.labelSmall)
                        .foregroundColor(Brand.Color.secondary)
                }
                
                // BMI Input (Optional)
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    Text("BMI (Optional)")
                        .font(Brand.Typography.labelLarge)
                        .foregroundColor(.primary)
                    
                    TextField("Enter BMI (15-60)", text: $bmi)
                        .keyboardType(.decimalPad)
                        .font(Brand.Typography.bodyMedium)
                        .padding(.horizontal, Brand.Spacing.lg)
                        .padding(.vertical, Brand.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                                .stroke(bmiValidationMessage != nil ? (bmiValidationMessage!.hasPrefix("✓") ? .green : .red) : Brand.Color.hairline, lineWidth: 1)
                        )
                        .onChange(of: bmi) { _, newValue in
                            validateBMI(newValue)
                            if let message = bmiValidationMessage, message.hasPrefix("✓") {
                                AccessibilityAnnouncement.announce("BMI validation: \(message)")
                            }
                        }
                        .inputFieldAccessibility(
                            label: "BMI in kg/m²",
                            value: bmi,
                            validationMessage: bmiValidationMessage,
                            isRequired: false
                        )
                    
                    if let bmiValidationMessage = bmiValidationMessage {
                        Text(bmiValidationMessage)
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(bmiValidationMessage.hasPrefix("✓") ? .green : .red)
                    } else {
                        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                            Text("Body Mass Index (kg/m²) - Affects Cocyte Yield and Success Rates")
                                .font(Brand.Typography.labelSmall)
                                .foregroundColor(Brand.Color.secondary)
                            
                            // Show BMI impact preview if valid BMI entered
                            if !bmi.isEmpty, let bmiValue = Double(bmi), bmiValue >= 15 && bmiValue <= 60 {
                                let impact = getBMIImpactText(bmiValue)
                                Text("Expected impact: \(impact)")
                                    .font(Brand.Typography.labelSmall)
                                    .foregroundColor(bmiValue >= 18.5 && bmiValue <= 24.9 ? .green : .orange)
                                    .italic()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Predict Button
    private var predictButton: some View {
        Button(action: {
            generatePrediction()
            AccessibilityAnnouncement.announce("Generating fertility prediction")
        }) {
            HStack(spacing: Brand.Spacing.sm) {
                Image(systemName: "chart.bar.fill")
                    .font(Brand.Typography.labelLarge)
                Text("Generate Prediction")
                    .font(Brand.Typography.labelLarge.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(Brand.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                    .fill(Brand.Color.primary)
                    .opacity(isFormValid ? 1.0 : 0.6)
            )
        }
        .disabled(!isFormValid)
        .animation(Brand.Motion.easeOut, value: isFormValid)
        .fertilityAccessibility(
            label: "Generate Prediction",
            hint: isFormValid ? "Double tap to generate your fertility prediction" : "Complete all required fields first",
            traits: isFormValid ? .isButton : .isButton
        )
    }
    
    // MARK: - Results Section
    private func resultsSection(_ results: IVFOutcomePredictor.PredictionResults) -> some View {
        VStack(spacing: Brand.Spacing.lg) {
            // Regulatory Warning - Must be prominently displayed
            RegulatoryWarningView(severity: .critical, context: .predictionResults)

            // Oocyte Results with Uncertainty Emphasis
            EnhancedContentBlock(
                title: "Expected Oocytes Retrieved - Population Average Only",
                icon: "circle.grid.2x2"
            ) {
                VStack(spacing: Brand.Spacing.md) {
                    // Compact warning at top
                    CompactRegulatoryWarning()

                    // Enhanced uncertainty range display
                    UncertaintyRangeView(
                        predictedValue: results.expectedOocytes.predicted,
                        range: results.expectedOocytes.range,
                        unit: "oocytes",
                        description: "Your individual result may be significantly different from this population average"
                    )

                    // Uncertainty warning
                    UncertaintyWarningView(
                        predictionType: .oocytes,
                        confidenceLevel: results.confidenceLevel.rawValue
                    )
                    
                    Text(results.expectedOocytes.percentile)
                        .font(Brand.Typography.labelSmall)
                        .foregroundColor(Brand.Color.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Fertilization Results
            EnhancedContentBlock(
                title: "Expected Fertilization",
                icon: "link.circle"
            ) {
                VStack(spacing: Brand.Spacing.md) {
                    // Fertilization Method Comparison Header
                    VStack(spacing: Brand.Spacing.xs) {
                        Text("Fertilization Method Outcomes")
                            .font(Brand.Typography.headlineMedium.weight(.semibold))
                            .foregroundColor(Brand.Color.primary)
                        
                        Text("Statistical Comparison of Both Fertilization Approaches Based on Your Profile")
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(Brand.Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Conventional IVF Results
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        HStack {
                            Image(systemName: "testtube.2")
                                .font(.caption)
                                .foregroundColor(Brand.Color.primary)
                            Text("Conventional IVF")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(results.expectedFertilization.conventionalIVF.fertilizationRate))%")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("\(Int(results.expectedFertilization.conventionalIVF.predicted)) Embryo(s)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Brand.Color.primary)
                            Spacer()
                            Text("(\(Int(results.expectedFertilization.conventionalIVF.range.lowerBound))-\(Int(results.expectedFertilization.conventionalIVF.range.upperBound)))")
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary)
                        }
                        
                        Text(results.expectedFertilization.conventionalIVF.explanation)
                            .font(.caption2)
                            .foregroundColor(Brand.Color.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(Brand.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.sm)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                    .stroke(Brand.Color.hairline, lineWidth: 1)
                            )
                    )
                    
                    // ICSI Results
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "syringe")
                                .font(.caption)
                                .foregroundColor(Brand.Color.primary)
                            Text("ICSI")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(results.expectedFertilization.icsi.fertilizationRate))%")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("\(Int(results.expectedFertilization.icsi.predicted)) Embryo(s)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Brand.Color.primary)
                            Spacer()
                            Text("(\(Int(results.expectedFertilization.icsi.range.lowerBound))-\(Int(results.expectedFertilization.icsi.range.upperBound)))")
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary)
                        }
                        
                        Text(results.expectedFertilization.icsi.explanation)
                            .font(.caption2)
                            .foregroundColor(Brand.Color.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(Brand.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.sm)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                    .stroke(Brand.Color.hairline, lineWidth: 1)
                            )
                    )
                }
            }
            
            // Blastocyst Results
            EnhancedContentBlock(
                title: "Expected Blastocysts",
                icon: "hexagon"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(String(format: "%.1f", results.expectedBlastocysts.predicted))
                                .font(.title.weight(.bold))
                                .foregroundColor(Brand.Color.primary)
                            Text("Predicted")
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(results.expectedBlastocysts.developmentRate))%")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("Development Rate")
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary)
                        }
                    }
                    
                    Text("\(Int(results.expectedBlastocysts.developmentRate))% Development Rate from Fertilized Embryos")
                        .font(.footnote)
                        .foregroundColor(Brand.Color.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Euploidy Results
            EnhancedContentBlock(
                title: "Euploidy Rates",
                icon: "checkmark.seal"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(Int(results.euploidyRates.euploidPercentage * 100))%")
                                .font(.title.weight(.bold))
                                .foregroundColor(Brand.Color.primary)
                            Text("Euploidy Rate")
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.1f", results.euploidyRates.expectedEuploidBlastocysts))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("Expected Normal")
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary)
                        }
                    }
                    
                    Text("Based on \(String(format: "%.0f", results.euploidyRates.euploidPercentage * 100))% Euploidy Rate for Your Age Group")
                        .font(.footnote)
                        .foregroundColor(Brand.Color.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Cascade Flow Visualization
            cascadeFlowSection
            
        }
    }
    // MARK: - Cascade Flow Section
    private var cascadeFlowSection: some View {
        ExpandableSection(
            title: "Embryo Development Cascade",
            subtitle: "Stage-by-stage attrition analysis",
            icon: "arrow.down.forward.and.arrow.up.backward",
            isExpanded: $isCascadeExpanded
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Stage-by-Stage Analysis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                let cascade = predictionResults?.cascadeFlow
                
                VStack(spacing: 12) {
                    // Oocytes Retrieved Stage
                    CascadeStageView(
                        stageNumber: "1",
                        stageName: "Oocytes Retrieved",
                        count: cascade?.totalOocytes ?? 0,
                        lossDescription: "Initial Retrieval From Follicles",
                        nextStageRate: {
                            guard let total = cascade?.totalOocytes, total > 0,
                                  let mature = cascade?.matureOocytes else { return 0 }
                            return (mature / total) * 100
                        }(),
                        isFirstStage: true
                    )
                    
                    // Mature Oocytes Stage
                    CascadeStageView(
                        stageNumber: "2", 
                        stageName: "Mature Oocytes (MII)",
                        count: cascade?.matureOocytes ?? 0,
                        lossDescription: {
                            let immature = cascade?.stageLosses.immatureOocytes ?? 0
                            if immature < 0.1 {
                                return "All Retrieved Oocytes Were Mature"
                            } else {
                                return String(format: "%.1f Immature (GV/MI) Oocytes", immature)
                            }
                        }(),
                        nextStageRate: {
                            guard let mature = cascade?.matureOocytes, mature > 0,
                                  let fertilized = cascade?.fertilizedEmbryos else { return 0 }
                            return (fertilized / mature) * 100
                        }()
                    )
                    
                    // Dual Fertilization Pathways
                    DualFertilizationStageView(cascade: cascade)
                    
                    // Day 3 Dual Pathways
                    DualPathwayStageView(
                        stageNumber: "4",
                        stageName: "Day 3 Embryos (8-cell)",
                        cascade: cascade,
                        pathwayExtractor: { pathway in
                            (pathway.day3Embryos, "embryos")
                        }
                    )
                    
                    // Blastocyst Dual Pathways
                    DualPathwayStageView(
                        stageNumber: "5", 
                        stageName: "Blastocysts (Day 5-6)",
                        cascade: cascade,
                        pathwayExtractor: { pathway in
                            (pathway.blastocysts, "blastocysts")
                        }
                    )
                    
                    // Euploid Dual Pathways
                    DualPathwayStageView(
                        stageNumber: "6",
                        stageName: "Euploid Blastocysts",
                        cascade: cascade,
                        pathwayExtractor: { pathway in
                            (pathway.euploidBlastocysts, "euploid")
                        }
                    )
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("This cascade shows how embryo numbers naturally decrease at each developmental stage. Understanding these transitions helps set realistic expectations for your IVF cycle.")
                    .font(.caption)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    // MARK: - Actions
    private func generatePrediction() {
        // Use enhanced medical validator for comprehensive safety checking
        updateValidationResult()

        guard let validation = validationResult else {
            showValidationError("Unable to validate medical inputs")
            return
        }

        // Check if inputs are valid
        guard validation.isValid else {
            let errorMessage = validation.errors.first?.message ?? "Invalid medical inputs detected"
            showValidationError(errorMessage)
            return
        }

        // Check if inputs are safe for medical prediction
        guard validation.isSafe else {
            showSafetyWarning(validation)
            return
        }

        // Check confidence level and warn if too low
        if validation.confidence == .low || validation.confidence == .insufficient {
            showConfidenceWarning(validation) {
                // User acknowledged warning, proceed with prediction
                self.proceedWithPrediction(validation: validation)
            }
            return
        }

        // Safe to proceed with prediction
        proceedWithPrediction(validation: validation)
    }

    private func proceedWithPrediction(validation: EnhancedMedicalValidator.MedicalValidationResult) {
        guard let validatedInputs = validation.validatedInputs else {
            showValidationError("Unable to process medical inputs")
            return
        }

        // Convert validated inputs to IVF predictor format
        let predictorInputs = convertToIVFPredictorInputs(validatedInputs)

        // Use the IVF predictor with validated inputs
        let predictor = IVFOutcomePredictor()

        switch calculationMode {
        case .preRetrieval:
            predictionResults = predictor.predict(from: predictorInputs)
        case .postRetrieval:
            if let oocyteCount = validatedInputs.oocyteCount ??
               (retrievedOocytes.isEmpty ? nil : Double(retrievedOocytes)) {
                predictionResults = predictor.predictFromRetrievedOocytes(
                    oocyteCount: oocyteCount,
                    inputs: predictorInputs
                )
            } else {
                showValidationError("Valid oocyte count required for post-retrieval predictions")
                return
            }
        }

        // Show results if prediction was successful
        if predictionResults != nil {
            showResults = true

            // Add warnings to results if present
            if !validation.warnings.isEmpty || !validation.safetyFlags.isEmpty {
                addValidationContextToResults(validation: validation)
            }

            // Haptic feedback for successful prediction
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)

            // VoiceOver announcement
            if UIAccessibility.isVoiceOverRunning {
                let confidenceText = validation.confidence.description
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Prediction generated successfully. \(confidenceText)"
                )
            }
        } else {
            showValidationError("Unable to generate prediction with current inputs")
        }
    }
    
    private func showValidationError(_ message: String) {
        Task { @MainActor in
            let error = SynagamyError.invalidInput(details: message)
            errorHandler.presentEnhancedError(
                error,
                onRetry: {
                    // Clear any results and allow retry
                    showResults = false
                    predictionResults = nil
                }
            )
        }

        // Haptic feedback for validation errors
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func showSafetyWarning(_ validation: EnhancedMedicalValidator.MedicalValidationResult) {
        let criticalFlags = validation.safetyFlags.filter { $0.type == .clinicalRisk || $0.type == .extremeValues }
        let warningMessage = criticalFlags.first?.message ?? "Safety concern detected with current inputs"

        safetyWarningMessage = """
        \(warningMessage)

        For your safety, please consult with a fertility specialist before proceeding with these values.
        """
        showSafetyWarning = true

        // Haptic feedback for safety warnings
        let warningFeedback = UINotificationFeedbackGenerator()
        warningFeedback.notificationOccurred(.warning)

        // VoiceOver announcement
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(
                notification: .announcement,
                argument: "Safety warning: \(warningMessage)"
            )
        }
    }

    private func showConfidenceWarning(_ validation: EnhancedMedicalValidator.MedicalValidationResult, onProceed: @escaping () -> Void) {
        let warningMessage: String
        let shouldProceed: Bool

        switch validation.confidence {
        case .low:
            warningMessage = """
            The prediction confidence is low due to:
            • \(validation.warnings.map { $0.message }.joined(separator: "\n• "))

            Results may be less accurate. Consult with a fertility specialist for personalized guidance.
            """
            shouldProceed = true

        case .insufficient:
            warningMessage = """
            Insufficient data quality for reliable predictions:
            • \(validation.errors.map { $0.message }.joined(separator: "\n• "))

            Please verify your inputs or consult with a healthcare provider.
            """
            shouldProceed = false

        default:
            onProceed()
            return
        }

        Task { @MainActor in
            let alert = UIAlertController(
                title: "Prediction Confidence Warning",
                message: warningMessage,
                preferredStyle: .alert
            )

            if shouldProceed {
                alert.addAction(UIAlertAction(title: "Proceed Anyway", style: .default) { _ in
                    onProceed()
                })
            }

            alert.addAction(UIAlertAction(title: "Review Inputs", style: .cancel))

            // Handle medical validation error through ErrorHandler
            let validationError = SynagamyError.invalidInput(details: "Medical input validation failed. Please review your entries.")
            errorHandler.handle(validationError)
        }
    }

    private func addValidationContextToResults(validation: EnhancedMedicalValidator.MedicalValidationResult) {
        // This method would add context about warnings and confidence to the prediction results
        // For now, we'll log the information
        #if DEBUG
        print("Prediction generated with warnings:")
        for warning in validation.warnings {
            print("- \(warning.field): \(warning.message)")
        }
        for flag in validation.safetyFlags {
            print("- Safety: \(flag.type): \(flag.message)")
        }
        print("Confidence: \(validation.confidence.description)")
        #endif
    }

    private func convertToIVFPredictorInputs(_ validatedInputs: EnhancedMedicalValidator.ValidatedInputs) -> IVFOutcomePredictor.PredictionInputs {
        // Convert our validated inputs to the format expected by IVFOutcomePredictor
        return IVFOutcomePredictor.PredictionInputs(
            age: validatedInputs.age,
            amhLevel: validatedInputs.amhLevel,
            estrogenLevel: validatedInputs.estrogenLevel,
            bmI: validatedInputs.bmi,
            priorCycles: validatedInputs.priorCycles,
            diagnosisType: DiagnosisType.from(string: validatedInputs.diagnosisType)?.ivfPredictorType ?? .unexplained,
            maleFactor: nil // Could be extended later
        )
    }

    private func convertDiagnosisType(_ diagnosisType: DiagnosisType) -> IVFOutcomePredictor.PredictionInputs.DiagnosisType {
        // Convert between the two diagnosis type enums
        switch diagnosisType {
        case .unexplained:
            return .unexplained
        case .maleFactorMild:
            return .maleFactorMild
        case .maleFactorSevere:
            return .maleFactorSevere
        case .ovulatory:
            return .ovulatory
        case .pcos:
            return .pcos
        case .tubalFactor:
            return .tubalFactor
        case .tubalFactorHydrosalpinx:
            return .tubalFactorHydrosalpinx
        case .endometriosisStage1_2:
            return .endometriosisStage1_2
        case .endometriosisStage3_4:
            return .endometriosisStage3_4
        case .diminishedOvarianReserve:
            return .diminishedOvarianReserve
        case .adenomyosis:
            return .adenomyosis
        case .multipleDiagnoses:
            return .multipleDiagnoses
        case .other:
            return .other
        }
    }
    
    private func generatePreRetrievalPrediction(age: Double) {
        // Validate AMH using DataValidator
        let amhResult = DataValidator.validateAMH(amhLevel, unit: amhUnit)
        guard amhResult.isValid, let amhValue = amhResult.normalizedValue else {
            Task { @MainActor in
                let error = SynagamyError.invalidInput(details: "AMH " + (amhResult.errorMessage ?? "value is outside expected range"))
                errorHandler.presentEnhancedError(
                    error,
                    onRetry: {
                        showResults = false
                        predictionResults = nil
                    }
                )
            }
            return
        }
        
        // Validate Estrogen using DataValidator
        let estrogenResult = DataValidator.validateEstrogen(estrogenLevel, unit: estrogenUnit)
        guard estrogenResult.isValid, let estrogenValue = estrogenResult.normalizedValue else {
            Task { @MainActor in
                let error = SynagamyError.invalidInput(details: "estradiol " + (estrogenResult.errorMessage ?? "value is outside expected range"))
                errorHandler.presentEnhancedError(
                    error,
                    onRetry: {
                        showResults = false
                        predictionResults = nil
                    }
                )
            }
            return
        }
        
        // Validate BMI if provided
        var bmiValue: Double? = nil
        if !bmi.isEmpty {
            let bmiResult = DataValidator.validateBMI(bmi)
            guard bmiResult.isValid, let validBMI = bmiResult.normalizedValue else {
                showValidationError(bmiResult.errorMessage ?? "Invalid BMI")
                return
            }
            bmiValue = validBMI
        }
        
        // Cross-field validation
        let crossValidation = DataValidator.validateInputCombination(
            age: age,
            amh: amhValue * amhUnit.toNgPerMLFactor,
            estrogen: estrogenValue * estrogenUnit.toPgPerMLFactor,
            diagnosis: selectedDiagnosis.displayName
        )
        
        // Show warning if cross-validation suggests issues
        if !crossValidation.isValid || crossValidation.warningMessage != nil {
            let message = crossValidation.warningMessage ?? crossValidation.errorMessage ?? "Input combination unusual"
            // Show as non-blocking warning
            VoiceOverSupport.announceValue("Input validation warning: \(message)", withLabel: "Warning")
        }
        
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: age,
            amhLevel: amhValue * amhUnit.toNgPerMLFactor,
            estrogenLevel: estrogenValue * estrogenUnit.toPgPerMLFactor,
            bmI: bmiValue,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis.ivfPredictorType,
            maleFactor: nil
        )
        
        let predictor = IVFOutcomePredictor()
        predictionResults = predictor.predict(from: inputs)
        showResults = true
        
        VoiceOverSupport.announceCompletion(of: "IVF prediction calculation")
    }
    
    // MARK: - Save Section
    private func saveSection(_ results: IVFOutcomePredictor.PredictionResults) -> some View {
        EnhancedContentBlock(
            title: "Save This Prediction",
            icon: "bookmark"
        ) {
            VStack(spacing: Brand.Spacing.md) {
                Button(action: {
                    showingSaveDialog = true
                }) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Save Prediction")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.Color.primary)
                    )
                }
                
                Text("Save this prediction to compare with future results or share with your healthcare provider.")
                    .font(.caption)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Save Functions
    private func savePrediction(withNickname nickname: String) async {
        #if DEBUG
        print("📱 [DEBUG] savePrediction called with nickname: '\(nickname)'")
        #endif
        guard let results = predictionResults,
              let ageValue = Double(age) else { 
            #if DEBUG
            print("📱 [DEBUG] Missing predictionResults or age value")
            #endif
            return 
        }
        
        // Create inputs for saving - handle differently based on calculation mode
        let amhInNgML: Double
        let estrogenInPgML: Double
        let originalEstrogenValue: Double?
        let savedAmhUnit: String?
        let savedEstrogenUnit: String?
        
        if calculationMode == CalculationMode.postRetrieval {
            // In post-retrieval mode, use dummy values for calculations but don't save them
            amhInNgML = 2.0 // Dummy value for PredictionInputs (required)
            estrogenInPgML = 2000 // Dummy value for PredictionInputs (required)
            originalEstrogenValue = nil // Don't save hormone values for post-retrieval
            savedAmhUnit = nil
            savedEstrogenUnit = nil
        } else {
            // In pre-retrieval mode, parse and save actual UI inputs
            let amhValue = Double(amhLevel) ?? 0
            let estrogenValue = Double(estrogenLevel) ?? 0
            amhInNgML = amhValue * amhUnit.toNgPerMLFactor
            estrogenInPgML = estrogenValue * estrogenUnit.toPgPerMLFactor
            originalEstrogenValue = estrogenValue
            savedAmhUnit = amhUnit.displayName
            savedEstrogenUnit = estrogenUnit.displayName
        }
        
        let bmiValue = bmi.isEmpty ? nil : Double(bmi)
        
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: ageValue,
            amhLevel: amhInNgML,
            estrogenLevel: estrogenInPgML,
            bmI: bmiValue,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis.ivfPredictorType,
            maleFactor: nil
        )
        
        let savedPrediction = SavedPrediction(
            nickname: nickname.isEmpty ? nil : nickname,
            inputs: inputs,
            results: results,
            calculationMode: calculationMode.displayName,
            amhUnit: savedAmhUnit,
            estrogenUnit: savedEstrogenUnit,
            originalEstrogenValue: originalEstrogenValue,
            retrievedOocytes: calculationMode == CalculationMode.postRetrieval ? Double(retrievedOocytes) : nil
        )
        
        #if DEBUG
        print("📱 [DEBUG] About to call persistenceService.savePrediction")
        #endif
        await persistenceService.savePrediction(savedPrediction)
        #if DEBUG
        print("📱 [DEBUG] Back from persistenceService.savePrediction")
        #endif
        
        showingSaveDialog = false
        predictionNickname = ""
    }
    
    // MARK: - Show Saved Prediction Cascade
    private func showSavedPredictionCascade(_ prediction: SavedPrediction) {
        #if DEBUG
        print("📱 [DEBUG] showSavedPredictionCascade called for: \(prediction.displayName)")
        #endif
        selectedSavedPrediction = prediction
        showingSavedCascade = true
        #if DEBUG
        print("📱 [DEBUG] showingSavedCascade set to true")
        #endif
    }
    
    private func generatePostRetrievalPrediction(age: Double) {
        // Validate oocyte count using DataValidator
        let oocyteResult = DataValidator.validateOocyteCount(retrievedOocytes)
        guard oocyteResult.isValid, let oocyteCount = oocyteResult.normalizedValue else {
            showValidationError(oocyteResult.errorMessage ?? "Invalid oocyte count")
            return
        }
        
        // Validate BMI if provided
        var bmiValue: Double? = nil
        if !bmi.isEmpty {
            let bmiResult = DataValidator.validateBMI(bmi)
            guard bmiResult.isValid, let validBMI = bmiResult.normalizedValue else {
                showValidationError(bmiResult.errorMessage ?? "Invalid BMI")
                return
            }
            bmiValue = validBMI
        }
        
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: age,
            amhLevel: 2.0, // Dummy value for post-retrieval mode
            estrogenLevel: 2000, // Dummy value for post-retrieval mode
            bmI: bmiValue,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis.ivfPredictorType,
            maleFactor: nil
        )
        
        let predictor = IVFOutcomePredictor()
        predictionResults = predictor.predictFromRetrievedOocytes(oocyteCount: oocyteCount, inputs: inputs)
        showResults = true
        
        VoiceOverSupport.announceCompletion(of: "Post-retrieval IVF prediction calculation")
    }
    
    
    // MARK: - Enhanced Validation Functions
    
    private func validateAge(_ value: String) {
        let result = DataValidator.validateAge(value)
        
        if result.isValid {
            if let warning = result.warningMessage {
                ageValidationMessage = "⚠️ " + warning
            } else {
                ageValidationMessage = "✓ Valid age"
            }
        } else {
            ageValidationMessage = result.errorMessage
        }
    }
    
    private func validateAMH(_ value: String) {
        let result = DataValidator.validateAMH(value, unit: amhUnit)
        
        if result.isValid {
            if let warning = result.warningMessage {
                amhValidationMessage = "⚠️ " + warning
            } else {
                amhValidationMessage = "✓ Valid AMH level"
            }
        } else {
            amhValidationMessage = result.errorMessage
        }
    }
    
    
    private func validateEstrogen(_ value: String) {
        let result = DataValidator.validateEstrogen(value, unit: estrogenUnit)
        
        if result.isValid {
            if let warning = result.warningMessage {
                estrogenValidationMessage = "⚠️ " + warning
            } else {
                estrogenValidationMessage = "✓ Valid estradiol level"
            }
        } else {
            estrogenValidationMessage = result.errorMessage
        }
    }
    
    private func validateOocyteCount(_ value: String) {
        let result = DataValidator.validateOocyteCount(value)
        
        if result.isValid {
            if let warning = result.warningMessage {
                oocyteValidationMessage = "⚠️ " + warning
            } else {
                oocyteValidationMessage = "✓ Valid oocyte count"
            }
        } else {
            oocyteValidationMessage = result.errorMessage
        }
    }
    
    private func validateBMI(_ value: String) {
        let result = DataValidator.validateBMI(value)
        
        if result.isValid {
            if let warning = result.warningMessage {
                bmiValidationMessage = "⚠️ " + warning
            } else {
                bmiValidationMessage = "✓ Valid BMI"
            }
        } else {
            bmiValidationMessage = result.errorMessage
        }
    }
    
    // MARK: - BMI Helper Functions
    
    private func getBMIImpactText(_ bmiValue: Double) -> String {
        if bmiValue < 18.5 {
            return "May reduce outcomes by ~12%"
        } else if bmiValue <= 24.9 {
            return "Optimal BMI range"
        } else if bmiValue <= 29.9 {
            return "May reduce outcomes by ~8%"
        } else if bmiValue <= 34.9 {
            return "May reduce outcomes by ~14%"
        } else if bmiValue <= 39.9 {
            return "May reduce outcomes by ~30%"
        } else {
            return "May reduce outcomes by ~68%"
        }
    }
    
    // MARK: - Validation Helper Functions
    
    private func getValidationColor(_ message: String?) -> Color {
        guard let message = message else { return Brand.Color.hairline }
        
        if message.hasPrefix("✓") {
            return .green
        } else {
            return .red
        }
    }
    
    private func getValidationTextColor(_ message: String) -> Color {
        if message.hasPrefix("✓") {
            return .green
        } else {
            return .red
        }
    }
}

// MARK: - Algorithm Step View Component
private struct AlgorithmStepView: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(Brand.Color.primary.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Brand.Color.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Cascade Stage View Component
private struct CascadeStageView: View {
    let stageNumber: String
    let stageName: String
    let count: Double
    let lossDescription: String
    let nextStageRate: Double?
    var isFirstStage: Bool = false
    var isFinalStage: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                // Stage number circle
                ZStack {
                    Circle()
                        .fill(Brand.Color.primary.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text(stageNumber)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Brand.Color.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(stageName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", count))
                            .font(.title2.weight(.bold))
                            .foregroundColor(count > 0 ? Brand.Color.primary : Brand.Color.secondary)
                    }
                    
                    Text(lossDescription)
                        .font(.caption)
                        .foregroundColor(Brand.Color.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Brand.Color.hairline, lineWidth: 1)
                    )
            )
            
            // Arrow and conversion rate (except for final stage)
            if !isFinalStage, let rate = nextStageRate {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Brand.Color.secondary)
                    
                    Text("\(String(format: "%.1f", rate))% progression")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(Brand.Color.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Saved Prediction Cascade View
struct SavedPredictionCascadeView: View {
    let prediction: SavedPrediction
    @Environment(\.dismiss) private var dismiss
    
    init(prediction: SavedPrediction) {
        self.prediction = prediction
        #if DEBUG
        print("📱 [DEBUG] SavedPredictionCascadeView init called for: \(prediction.displayName)")
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Brand.Spacing.lg) {
                // Brand Header with Close Button
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        CategoryBadge(
                            text: "Saved Prediction",
                            icon: "bookmark.fill",
                            color: Brand.Color.primary
                        )
                        
                        Text(prediction.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                            .onAppear {
                                #if DEBUG
                                print("📱 [DEBUG] SavedPredictionCascadeView body rendered for: \(prediction.displayName)")
                                #endif
                            }
                        
                        Text(prediction.summaryText)
                            .font(.subheadline)
                            .foregroundColor(Brand.Color.secondary)
                        
                        Text("Saved: \(DateFormatter.savedPredictionFormatter.string(from: prediction.timestamp))")
                            .font(.caption)
                            .foregroundColor(Brand.Color.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "xmark")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Brand.Color.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, Brand.Spacing.md)
                
                // Recreate the cascade flow section using PersistenceService
                Group {
                    if let results = try? PredictionPersistenceService.shared.createResultsFromSavedPrediction(prediction) {
                        savedCascadeFlowSection(cascadeFlow: results.cascadeFlow)
                    } else {
                        VStack {
                            Text("Unable to load cascade data")
                                .foregroundColor(.red)
                            Text("Debug: Expected Oocytes: \(String(format: "%.1f", prediction.expectedOocytes))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, Brand.Spacing.md)
            .padding(.vertical, Brand.Spacing.lg)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Saved Cascade Flow Section
    private func savedCascadeFlowSection(cascadeFlow: IVFOutcomePredictor.PredictionResults.CascadeFlow) -> some View {
        EnhancedContentBlock(
            title: "Embryo Development Cascade",
            icon: "arrow.down.forward.and.arrow.up.backward"
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Stage-by-Stage Analysis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    // Oocytes Retrieved Stage
                    CascadeStageView(
                        stageNumber: "1",
                        stageName: "Oocytes Retrieved",
                        count: cascadeFlow.totalOocytes,
                        lossDescription: "Initial Retrieval From Follicles",
                        nextStageRate: {
                            guard cascadeFlow.totalOocytes > 0 else { return 0 }
                            return (cascadeFlow.matureOocytes / cascadeFlow.totalOocytes) * 100
                        }(),
                        isFirstStage: true
                    )
                    
                    // Mature Oocytes Stage
                    CascadeStageView(
                        stageNumber: "2", 
                        stageName: "Mature Oocytes (MII)",
                        count: cascadeFlow.matureOocytes,
                        lossDescription: {
                            let immature = cascadeFlow.stageLosses.immatureOocytes
                            if immature < 0.1 {
                                return "All Retrieved Oocytes Were Mature"
                            } else {
                                return String(format: "%.1f Immature (GV/MI) Oocytes", immature)
                            }
                        }(),
                        nextStageRate: {
                            guard cascadeFlow.matureOocytes > 0 else { return 0 }
                            return (cascadeFlow.fertilizedEmbryos / cascadeFlow.matureOocytes) * 100
                        }()
                    )
                    
                    // Dual Fertilization Pathways
                    DualFertilizationStageView(cascade: cascadeFlow)
                    
                    // Day 3 Dual Pathways
                    DualPathwayStageView(
                        stageNumber: "4",
                        stageName: "Day 3 Embryos (8-cell)",
                        cascade: cascadeFlow,
                        pathwayExtractor: { pathway in
                            (pathway.day3Embryos, "embryos")
                        }
                    )
                    
                    // Blastocyst Dual Pathways
                    DualPathwayStageView(
                        stageNumber: "5", 
                        stageName: "Blastocysts (Day 5-6)",
                        cascade: cascadeFlow,
                        pathwayExtractor: { pathway in
                            (pathway.blastocysts, "blastocysts")
                        }
                    )
                    
                    // Euploid Dual Pathways
                    DualPathwayStageView(
                        stageNumber: "6",
                        stageName: "Euploid Blastocysts",
                        cascade: cascadeFlow,
                        pathwayExtractor: { pathway in
                            (pathway.euploidBlastocysts, "euploid")
                        }
                    )
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("This cascade shows how embryo numbers naturally decrease at each developmental stage. Understanding these transitions helps set realistic expectations for your IVF cycle.")
                    .font(.caption)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
}

// MARK: - Saved Prediction Compact Row
struct SavedPredictionRowCompact: View {
    let prediction: SavedPrediction
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(prediction.summaryText)
                        .font(.caption)
                        .foregroundColor(Brand.Color.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Key result
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f", prediction.expectedEuploidBlastocysts))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Brand.Color.primary)
                    
                    Text("euploid")
                        .font(.caption2)
                        .foregroundColor(Brand.Color.secondary)
                }
                
                Menu {
                    Button("View Cascade") {
                        onTap()
                    }
                    
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Brand.Color.secondary)
                        .padding(8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Save Prediction Dialog
struct SavePredictionDialog: View {
    @Binding var nickname: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Brand.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prediction Name (Optional)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("e.g., First IVF Attempt", text: $nickname)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit {
                            onSave(nickname)
                            dismiss()
                        }
                }
                
                Text("Give your prediction a memorable name to easily find it later. If left blank, it will be saved with the current date and time.")
                    .font(.caption)
                    .foregroundColor(Brand.Color.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Save Prediction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(nickname)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Diagnosis Type Extension
extension IVFOutcomePredictor.PredictionInputs.DiagnosisType {
    var displayName: String {
        switch self {
        case .unexplained:
            return "Unexplained Infertility"
        case .maleFactorMild:
            return "Male Factor (Mild)"
        case .maleFactorSevere:
            return "Male Factor (Severe)"
        case .ovulatory:
            return "Ovulatory Disorders"
        case .pcos:
            return "PCOS"
        case .tubalFactor:
            return "Tubal Factor"
        case .tubalFactorHydrosalpinx:
            return "Tubal Factor with Hydrosalpinx"
        case .endometriosisStage1_2:
            return "Endometriosis Stage I-II"
        case .endometriosisStage3_4:
            return "Endometriosis Stage III-IV"
        case .diminishedOvarianReserve:
            return "Diminished Ovarian Reserve"
        case .adenomyosis:
            return "Adenomyosis"
        case .multipleDiagnoses:
            return "Multiple Diagnoses"
        case .other:
            return "Other"
        }
    }
}

// MARK: - Dual Fertilization Pathway View
private struct DualFertilizationStageView: View {
    let cascade: IVFOutcomePredictor.PredictionResults.CascadeFlow?
    
    var body: some View {
        VStack(spacing: 16) {
            // Stage 3 Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Brand.Color.primary.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Text("3")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Brand.Color.primary)
                }
                
                Text("Fertilized Embryos by Method")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Dual pathway comparison
            HStack(alignment: .top, spacing: 16) {
                // IVF Pathway
                PathwayColumn(
                    title: "Conventional IVF",
                    pathway: cascade?.ivfPathway,
                    color: Brand.Color.primary
                )
                
                // Comparison Divider
                VStack {
                    Text("vs")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                    
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: 120)
                
                // ICSI Pathway
                PathwayColumn(
                    title: "ICSI",
                    pathway: cascade?.icsiPathway,
                    color: Brand.Color.secondary
                )
            }
            
            // Statistical comparison summary
            if let cascade = cascade {
                let ivfEuploid = cascade.ivfPathway.euploidBlastocysts
                let icsiEuploid = cascade.icsiPathway.euploidBlastocysts
                let difference = abs(icsiEuploid - ivfEuploid)
                let percentDiff = difference > 0 ? Int((difference / max(ivfEuploid, icsiEuploid)) * 100) : 0
                
                if percentDiff > 5 { // Only show if meaningful difference
                    let comparisonText = icsiEuploid > ivfEuploid ? 
                        "ICSI: +\(percentDiff)% more euploid blastocysts than conventional IVF" :
                        "Conventional IVF: +\(percentDiff)% more euploid blastocysts than ICSI"
                    
                    Text(comparisonText)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary.opacity(0.1))
                        )
                }
            }
            
            // Connection line to next stage
            VStack(spacing: 4) {
                Text("↓")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.6))
                
                Text("Both pathways continue through complete cascade")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Brand.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Pathway Column View
private struct PathwayColumn: View {
    let title: String
    let pathway: IVFOutcomePredictor.PredictionResults.CascadeFlow.FertilizationPathway?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Method header
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            // Fertilization results
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(format: "%.1f", pathway?.fertilizedEmbryos ?? 0))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("fertilized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int((pathway?.fertilizationRate ?? 0) * 100))% fertilization rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Quick cascade preview
                VStack(alignment: .leading, spacing: 2) {
                    Text("→ \(String(format: "%.1f", pathway?.day3Embryos ?? 0)) day 3 embryos")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text("→ \(String(format: "%.1f", pathway?.blastocysts ?? 0)) blastocysts")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text("→ \(String(format: "%.1f", pathway?.euploidBlastocysts ?? 0)) euploid")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Dual Pathway Stage View for Cascade Stages
private struct DualPathwayStageView: View {
    let stageNumber: String
    let stageName: String
    let cascade: IVFOutcomePredictor.PredictionResults.CascadeFlow?
    let pathwayExtractor: (IVFOutcomePredictor.PredictionResults.CascadeFlow.FertilizationPathway) -> (Double, String)
    
    var body: some View {
        VStack(spacing: 16) {
            // Stage Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Brand.Color.primary.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Text(stageNumber)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Brand.Color.primary)
                }
                
                Text(stageName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Dual pathway results
            HStack(alignment: .top, spacing: 16) {
                // IVF Results
                if let cascade = cascade {
                    let (ivfCount, unit) = pathwayExtractor(cascade.ivfPathway)
                    PathwayResultColumn(
                        title: "Conventional IVF",
                        count: ivfCount,
                        unit: unit,
                        color: Brand.Color.primary
                    )
                }
                
                // Comparison Divider
                VStack {
                    Text("vs")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1)
                        .frame(maxHeight: 60)
                }
                
                // ICSI Results
                if let cascade = cascade {
                    let (icsiCount, unit) = pathwayExtractor(cascade.icsiPathway)
                    PathwayResultColumn(
                        title: "ICSI",
                        count: icsiCount,
                        unit: unit,
                        color: Brand.Color.secondary
                    )
                }
            }
        }
        .padding(Brand.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Pathway Result Column
private struct PathwayResultColumn: View {
    let title: String
    let count: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(format: "%.1f", count))
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Unit Enumerations are defined in DataValidator.swift

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let savedPredictionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
