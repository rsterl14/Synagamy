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

struct OutcomePredictorView: View {
    // MARK: - Input State
    @State private var age: String = ""
    @State private var amhLevel: String = ""
    @State private var estrogenLevel: String = ""
    @State private var retrievedOocytes: String = ""
    @State private var bmi: String = ""
    @State private var selectedDiagnosis: IVFOutcomePredictor.PredictionInputs.DiagnosisType = .unexplained
    @State private var amhUnit: AMHUnit = .ngPerML
    @State private var estrogenUnit: EstrogenUnit = .pgPerML
    @State private var calculationMode: CalculationMode = .preRetrieval
    
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
    
    // MARK: - UI State
    @State private var showResults = false
    @State private var predictionResults: IVFOutcomePredictor.PredictionResults?
    @State private var errorMessage: String? = nil
    @State private var isCascadeExpanded = false
    
    // MARK: - Validation State
    @State private var ageValidationMessage: String? = nil
    @State private var amhValidationMessage: String? = nil
    @State private var estrogenValidationMessage: String? = nil
    @State private var oocyteValidationMessage: String? = nil
    @State private var bmiValidationMessage: String? = nil
    
    
    // MARK: - Error Handling
    @StateObject private var errorHandler = AppErrorHandler()
    
    // MARK: - Persistence
    @StateObject private var persistenceService = PredictionPersistenceService.shared
    @State private var showingSaveDialog = false
    @State private var predictionNickname = ""
    @State private var showingSavedPredictions = false
    @State private var selectedSavedPrediction: SavedPrediction?
    @State private var showingSavedCascade = false
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        guard let ageValue = Double(age), ageValue >= 18 && ageValue <= 50 else {
            return false
        }
        
        switch calculationMode {
        case .preRetrieval:
            // Convert AMH to ng/mL for validation
            guard let amhValue = Double(amhLevel) else { return false }
            let amhInNgML = amhValue * amhUnit.toNgPerMLFactor
            guard amhInNgML >= 0.01 && amhInNgML <= 50 else { return false }
            
            // Convert Estrogen to pg/mL for validation  
            guard let estrogenValue = Double(estrogenLevel) else { return false }
            let estrogenInPgML = estrogenValue * estrogenUnit.toPgPerMLFactor
            guard estrogenInPgML >= 100 && estrogenInPgML <= 10000 else { return false }
            
            return true
            
        case .postRetrieval:
            // Only need oocyte count validation
            guard let oocyteCount = Double(retrievedOocytes), oocyteCount >= 1 && oocyteCount <= 50 else {
                return false
            }
            return true
        }
    }
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: nil,
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
                .foregroundColor(Brand.ColorSystem.primary)
                .font(.headline.weight(.medium))
            }
        }
        .alert("Prediction Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please check your inputs and try again.")
        })
        .errorHandling(errorHandler)
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
    }
    
    // MARK: - Keyboard Dismissal
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            CategoryBadge(
                text: "IVF Outcome Predictor",
                icon: "chart.line.uptrend.xyaxis",
                color: Brand.ColorSystem.primary
            )
            
            Text("Personalized IVF Success Estimates")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Based on Population Data. \n\n Individual Results can Vary From This Personalized IVF Success Estimator")
                .font(.caption)
                .foregroundColor(Brand.ColorSystem.secondary)
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
                            persistenceService.deletePrediction(prediction)
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
                        .foregroundColor(Brand.ColorSystem.primary)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calculation Mode")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Picker("Calculation Mode", selection: $calculationMode) {
                        ForEach(CalculationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(calculationMode.description)
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                Divider()
                    .padding(.vertical, 4)
                // Age Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age (Years)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter age (18-50)", text: $age)
                        .keyboardType(.decimalPad)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(ageValidationMessage != nil ? .red : Brand.ColorToken.hairline, lineWidth: 1)
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
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Text("Age at Time of Oocyte Retrieval")
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                // Conditional inputs based on calculation mode
                if calculationMode == .preRetrieval {
                    // AMH Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMH Level")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            TextField("Enter AMH level", text: $amhLevel)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(getValidationColor(amhValidationMessage), lineWidth: 1)
                                )
                            
                            Picker("AMH Unit", selection: $amhUnit) {
                                ForEach(AMHUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Brand.ColorSystem.primary)
                            .frame(minWidth: 80)
                        }
                        
                        if let amhValidationMessage = amhValidationMessage {
                            Text(amhValidationMessage)
                                .font(.caption)
                                .foregroundColor(getValidationTextColor(amhValidationMessage))
                        } else {
                            Text("Anti-Müllerian Hormone Level")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                    }
                    
                    // Estrogen Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Peak Estradiol Level")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            TextField("Enter estradiol level", text: $estrogenLevel)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                                )
                            
                            Picker("Estrogen Unit", selection: $estrogenUnit) {
                                ForEach(EstrogenUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Brand.ColorSystem.primary)
                            .frame(minWidth: 80)
                        }
                        
                        Text("Peak Estradiol on Trigger Day")
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.secondary)
                    }
                } else {
                    // Retrieved Oocytes Input (for post-retrieval mode)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Retrieved Oocytes")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        TextField("Enter number of retrieved oocytes", text: $retrievedOocytes)
                            .keyboardType(.decimalPad)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                            )
                        
                        Text("Total Oocytes Retrieved During Your Cycle")
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.secondary)
                    }
                }
                
                // Diagnosis Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Diagnosis")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Menu {
                        ForEach(IVFOutcomePredictor.PredictionInputs.DiagnosisType.allCases, id: \.self) { diagnosis in
                            Button(diagnosis.displayName) {
                                selectedDiagnosis = diagnosis
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedDiagnosis.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(Brand.ColorSystem.primary)
                                .font(.caption.weight(.medium))
                        }
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                        )
                    }
                    
                    Text("Underlying Fertility Diagnosis")
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                // BMI Input (Optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("BMI (Optional)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter BMI (15-60)", text: $bmi)
                        .keyboardType(.decimalPad)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(bmiValidationMessage != nil ? (bmiValidationMessage!.hasPrefix("✓") ? .green : .red) : Brand.ColorToken.hairline, lineWidth: 1)
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
                            .font(.caption)
                            .foregroundColor(bmiValidationMessage.hasPrefix("✓") ? .green : .red)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Body Mass Index (kg/m²) - Affects Cocyte Yield and Success Rates")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                            
                            // Show BMI impact preview if valid BMI entered
                            if !bmi.isEmpty, let bmiValue = Double(bmi), bmiValue >= 15 && bmiValue <= 60 {
                                let impact = getBMIImpactText(bmiValue)
                                Text("Expected impact: \(impact)")
                                    .font(.caption)
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
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.headline)
                Text("Generate Prediction")
                    .font(.headline.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.ColorSystem.primary)
                    .opacity(isFormValid ? 1.0 : 0.6)
            )
        }
        .disabled(!isFormValid)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
        .fertilityAccessibility(
            label: "Generate Prediction",
            hint: isFormValid ? "Double tap to generate your fertility prediction" : "Complete all required fields first",
            traits: isFormValid ? .isButton : .isButton
        )
    }
    
    // MARK: - Results Section
    private func resultsSection(_ results: IVFOutcomePredictor.PredictionResults) -> some View {
        VStack(spacing: Brand.Spacing.lg) {
            // Oocyte Results
            EnhancedContentBlock(
                title: "Expected Oocytes Retrieved",
                icon: "circle.grid.2x2"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(String(format: "%.1f", results.expectedOocytes.predicted))
                                .font(.title.weight(.bold))
                                .foregroundColor(Brand.ColorSystem.primary)
                            Text("Predicted")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(results.expectedOocytes.range.lowerBound))-\(Int(results.expectedOocytes.range.upperBound))")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("Range (80% CI)")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                    }
                    
                    Text(results.expectedOocytes.percentile)
                        .font(.footnote)
                        .foregroundColor(Brand.ColorSystem.secondary)
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
                    VStack(spacing: 6) {
                        Text("Fertilization Method Outcomes")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Brand.ColorSystem.primary)
                        
                        Text("Statistical Comparison of Both Fertilization Approaches Based on Your Profile")
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Conventional IVF Results
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "testtube.2")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.primary)
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
                                .foregroundColor(Brand.ColorSystem.primary)
                            Spacer()
                            Text("(\(Int(results.expectedFertilization.conventionalIVF.range.lowerBound))-\(Int(results.expectedFertilization.conventionalIVF.range.upperBound)))")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        Text(results.expectedFertilization.conventionalIVF.explanation)
                            .font(.caption2)
                            .foregroundColor(Brand.ColorSystem.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                            )
                    )
                    
                    // ICSI Results
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "syringe")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.primary)
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
                                .foregroundColor(Brand.ColorSystem.primary)
                            Spacer()
                            Text("(\(Int(results.expectedFertilization.icsi.range.lowerBound))-\(Int(results.expectedFertilization.icsi.range.upperBound)))")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        Text(results.expectedFertilization.icsi.explanation)
                            .font(.caption2)
                            .foregroundColor(Brand.ColorSystem.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Brand.ColorToken.hairline, lineWidth: 1)
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
                                .foregroundColor(Brand.ColorSystem.primary)
                            Text("Predicted")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(results.expectedBlastocysts.developmentRate))%")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("Development Rate")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                    }
                    
                    Text("\(Int(results.expectedBlastocysts.developmentRate))% Development Rate from Fertilized Embryos")
                        .font(.footnote)
                        .foregroundColor(Brand.ColorSystem.secondary)
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
                                .foregroundColor(Brand.ColorSystem.primary)
                            Text("Euploidy Rate")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.1f", results.euploidyRates.expectedEuploidBlastocysts))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("Expected Normal")
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                    }
                    
                    Text("Based on \(String(format: "%.0f", results.euploidyRates.euploidPercentage * 100))% Euploidy Rate for Your Age Group")
                        .font(.footnote)
                        .foregroundColor(Brand.ColorSystem.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Cascade Flow Visualization
            cascadeFlowSection
            
        }
    }
    
    // MARK: - Algorithm Explanation Section (Hidden)
    /*
    private var algorithmExplanationSection: some View {
        ExpandableSection(
            title: "How the Algorithm Works",
            subtitle: "Advanced prediction methodology",
            icon: "brain.head.profile",
            isExpanded: $isAlgorithmExpanded
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Advanced Multi-Factorial Prediction Model")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 10) {
                    AlgorithmStepView(
                        number: "1",
                        title: "Polynomial Regression Analysis",
                        description: "Uses age-AMH interaction coefficients derived from 50,000+ Canadian IVF cycles to predict baseline oocyte yield."
                    )
                    
                    AlgorithmStepView(
                        number: "2",
                        title: "Multi-Parameter Optimization",
                        description: "Integrates estrogen response curves, diagnosis-specific adjustments, and prior cycle learning effects for personalized predictions."
                    )
                    
                    AlgorithmStepView(
                        number: "3",
                        title: "Quality Assessment Modeling",
                        description: "Applies embryo development algorithms that account for mitochondrial function, DNA fragmentation, and chromosomal competence by age."
                    )
                    
                    AlgorithmStepView(
                        number: "4",
                        title: "Statistical Confidence Intervals",
                        description: "Generates 90% confidence ranges using Monte Carlo simulation methods and population variance data."
                    )
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Sources")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(Brand.ColorSystem.primary)
                    
                    Text("• CARTR-BORN Registry (Canadian national fertility data, 2013-2023)")
                    Text("• CDC/SART Registry (US national ART surveillance, 2018-2022)")
                    Text("• SOGC Clinical Practice Guidelines (Canadian reproductive medicine)")
                    Text("• ASRM Practice Committee Guidelines (US reproductive medicine)")
                    Text("• International validation studies (BMJ, Human Reproduction)")
                }
                .font(.caption)
                .foregroundColor(Brand.ColorSystem.secondary)
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Algorithm Accuracy")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(Brand.ColorSystem.primary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Oocyte Prediction")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.primary)
                            Text("R² = 0.78")
                                .font(.caption2)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blastocyst Rate")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.primary)
                            Text("R² = 0.71")
                                .font(.caption2)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Euploidy Rate")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.primary)
                            Text("R² = 0.69")
                                .font(.caption2)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .font(.caption)
            }
        }
    }
    */
    
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
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    // MARK: - Actions
    private func generatePrediction() {
        // Validate age
        let ageResult = errorHandler.validateAge(age)
        guard case .success(let ageValue) = ageResult else {
            if case .failure(let error) = ageResult {
                errorHandler.handle(error, context: "Age validation")
            }
            return
        }
        
        switch calculationMode {
        case .preRetrieval:
            generatePreRetrievalPrediction(age: ageValue)
        case .postRetrieval:
            generatePostRetrievalPrediction(age: ageValue)
        }
    }
    
    private func generatePreRetrievalPrediction(age: Double) {
        guard let amhValue = Double(amhLevel),
              let estrogenValue = Double(estrogenLevel) else {
            errorMessage = "Please enter valid numeric values for AMH and Estradiol levels."
            return
        }
        
        // Convert AMH to ng/mL for calculations
        let amhInNgML = amhValue * amhUnit.toNgPerMLFactor
        let amhUnitText = amhUnit.displayName
        if amhInNgML < 0.01 || amhInNgML > 50 {
            let minValue = amhUnit == .ngPerML ? "0.01" : String(format: "%.1f", 0.01 / amhUnit.toNgPerMLFactor)
            let maxValue = amhUnit == .ngPerML ? "50" : String(format: "%.0f", 50 / amhUnit.toNgPerMLFactor)
            errorMessage = "AMH level must be between \(minValue) and \(maxValue) \(amhUnitText)."
            return
        }
        
        // Convert Estrogen to pg/mL for calculations
        let estrogenInPgML = estrogenValue * estrogenUnit.toPgPerMLFactor
        let estrogenUnitText = estrogenUnit.displayName
        if estrogenInPgML < 100 || estrogenInPgML > 10000 {
            let minValue = estrogenUnit == .pgPerML ? "100" : String(format: "%.0f", 100 / estrogenUnit.toPgPerMLFactor)
            let maxValue = estrogenUnit == .pgPerML ? "10,000" : String(format: "%.0f", 10000 / estrogenUnit.toPgPerMLFactor)
            errorMessage = "Estradiol level must be between \(minValue) and \(maxValue) \(estrogenUnitText)."
            return
        }
        
        // Parse BMI if provided
        let bmiValue = bmi.isEmpty ? nil : Double(bmi)
        
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: age,
            amhLevel: amhInNgML,
            estrogenLevel: estrogenInPgML,
            bmI: bmiValue,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis,
            maleFactor: nil  // No male factor parameters collected in this UI yet
        )
        
        let predictor = IVFOutcomePredictor()
        predictionResults = predictor.predict(from: inputs)
        showResults = true
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
                            .fill(Brand.ColorSystem.primary)
                    )
                }
                
                Text("Save this prediction to compare with future results or share with your healthcare provider.")
                    .font(.caption)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Save Functions
    private func savePrediction(withNickname nickname: String) async {
        print("📱 [DEBUG] savePrediction called with nickname: '\(nickname)'")
        guard let results = predictionResults,
              let ageValue = Double(age) else { 
            print("📱 [DEBUG] Missing predictionResults or age value")
            return 
        }
        
        // Create inputs for saving - handle differently based on calculation mode
        let amhInNgML: Double
        let estrogenInPgML: Double
        let originalEstrogenValue: Double?
        let savedAmhUnit: String?
        let savedEstrogenUnit: String?
        
        if calculationMode == .postRetrieval {
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
            diagnosisType: selectedDiagnosis,
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
            retrievedOocytes: calculationMode == .postRetrieval ? Double(retrievedOocytes) : nil
        )
        
        print("📱 [DEBUG] About to call persistenceService.savePrediction")
        await persistenceService.savePrediction(savedPrediction)
        print("📱 [DEBUG] Back from persistenceService.savePrediction")
        
        showingSaveDialog = false
        predictionNickname = ""
    }
    
    // MARK: - Show Saved Prediction Cascade
    private func showSavedPredictionCascade(_ prediction: SavedPrediction) {
        print("📱 [DEBUG] showSavedPredictionCascade called for: \(prediction.displayName)")
        selectedSavedPrediction = prediction
        showingSavedCascade = true
        print("📱 [DEBUG] showingSavedCascade set to true")
    }
    
    private func generatePostRetrievalPrediction(age: Double) {
        guard let oocyteCount = Double(retrievedOocytes) else {
            errorMessage = "Please enter a valid number of retrieved oocytes."
            return
        }
        
        if oocyteCount < 1 || oocyteCount > 50 {
            errorMessage = "Number of retrieved oocytes must be between 1 and 50."
            return
        }
        
        // Parse BMI if provided  
        let bmiValue = bmi.isEmpty ? nil : Double(bmi)
        
        // Create inputs with dummy values for AMH/E2 since we're starting from known oocyte count
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: age,
            amhLevel: 2.0, // Dummy value
            estrogenLevel: 2000, // Dummy value
            bmI: bmiValue,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis,
            maleFactor: nil  // No male factor parameters collected in this UI yet
        )
        
        let predictor = IVFOutcomePredictor()
        predictionResults = predictor.predictFromRetrievedOocytes(oocyteCount: oocyteCount, inputs: inputs)
        showResults = true
    }
    
    
    // MARK: - Real-time Validation Functions
    
    private func validateAge(_ value: String) {
        guard !value.isEmpty else {
            ageValidationMessage = nil
            return
        }
        
        guard let ageValue = Double(value) else {
            ageValidationMessage = "Please enter a valid number"
            return
        }
        
        if ageValue < 18 {
            ageValidationMessage = "Age must be at least 18 years"
        } else if ageValue > 50 {
            ageValidationMessage = "Age must be 50 years or less"
        } else {
            ageValidationMessage = nil
        }
    }
    
    
    private func validateEstrogen(_ value: String) {
        guard !value.isEmpty else {
            estrogenValidationMessage = nil
            return
        }
        
        guard let estrogenValue = Double(value) else {
            estrogenValidationMessage = "Please enter a valid number"
            return
        }
        
        let estrogenInPgML = estrogenValue * estrogenUnit.toPgPerMLFactor
        let unitText = estrogenUnit.displayName
        
        if estrogenInPgML < 100 {
            let minValue = estrogenUnit == .pgPerML ? "100" : String(format: "%.0f", 100 / estrogenUnit.toPgPerMLFactor)
            estrogenValidationMessage = "Estradiol must be at least \(minValue) \(unitText)"
        } else if estrogenInPgML > 10000 {
            let maxValue = estrogenUnit == .pgPerML ? "10000" : String(format: "%.0f", 10000 / estrogenUnit.toPgPerMLFactor)
            estrogenValidationMessage = "Estradiol must be \(maxValue) \(unitText) or less"
        } else {
            // Show helpful range information
            if estrogenInPgML < 1500 {
                estrogenValidationMessage = "✓ Valid (low stimulation response)"
            } else if estrogenInPgML > 4000 {
                estrogenValidationMessage = "✓ Valid (high stimulation response)"
            } else {
                estrogenValidationMessage = "✓ Normal stimulation response"
            }
        }
    }
    
    private func validateOocyteCount(_ value: String) {
        guard !value.isEmpty else {
            oocyteValidationMessage = nil
            return
        }
        
        guard let oocyteValue = Double(value) else {
            oocyteValidationMessage = "Please enter a valid number"
            return
        }
        
        if oocyteValue < 1 {
            oocyteValidationMessage = "Must have at least 1 retrieved oocyte"
        } else if oocyteValue > 50 {
            oocyteValidationMessage = "Maximum 50 oocytes allowed"
        } else {
            // Show helpful context
            if oocyteValue < 5 {
                oocyteValidationMessage = "✓ Low yield (may suggest diminished ovarian reserve)"
            } else if oocyteValue > 20 {
                oocyteValidationMessage = "✓ High yield (excellent ovarian response)"
            } else {
                oocyteValidationMessage = "✓ Normal range"
            }
        }
    }
    
    private func validateBMI(_ value: String) {
        guard !value.isEmpty else {
            bmiValidationMessage = nil
            return
        }
        
        guard let bmiValue = Double(value) else {
            bmiValidationMessage = "Please enter a valid number"
            return
        }
        
        if bmiValue < 15 {
            bmiValidationMessage = "BMI must be at least 15 kg/m²"
        } else if bmiValue > 60 {
            bmiValidationMessage = "BMI must be 60 kg/m² or less"
        } else {
            // Show helpful BMI category information based on research data
            if bmiValue < 18.5 {
                bmiValidationMessage = "✓ Underweight (may reduce success rates by 12%)"
            } else if bmiValue <= 24.9 {
                bmiValidationMessage = "✓ Normal weight (optimal for IVF outcomes)"
            } else if bmiValue <= 29.9 {
                bmiValidationMessage = "✓ Overweight (may reduce success rates by 8%)"
            } else if bmiValue <= 34.9 {
                bmiValidationMessage = "✓ Obese Class I (may reduce success rates by 14%)"
            } else if bmiValue <= 39.9 {
                bmiValidationMessage = "✓ Obese Class II (may reduce success rates by 30%)"
            } else {
                bmiValidationMessage = "✓ Obese Class III (may reduce success rates by 68%)"
            }
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
        guard let message = message else { return Brand.ColorToken.hairline }
        
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
                    .fill(Brand.ColorSystem.primary.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Brand.ColorSystem.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(Brand.ColorSystem.secondary)
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
                        .fill(Brand.ColorSystem.primary.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text(stageNumber)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Brand.ColorSystem.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(stageName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", count))
                            .font(.title2.weight(.bold))
                            .foregroundColor(count > 0 ? Brand.ColorSystem.primary : Brand.ColorSystem.secondary)
                    }
                    
                    Text(lossDescription)
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
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
                            .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                    )
            )
            
            // Arrow and conversion rate (except for final stage)
            if !isFinalStage, let rate = nextStageRate {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Brand.ColorSystem.secondary)
                    
                    Text("\(String(format: "%.1f", rate))% progression")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(Brand.ColorSystem.secondary)
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
        print("📱 [DEBUG] SavedPredictionCascadeView init called for: \(prediction.displayName)")
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
                            color: Brand.ColorSystem.primary
                        )
                        
                        Text(prediction.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                            .onAppear {
                                print("📱 [DEBUG] SavedPredictionCascadeView body rendered for: \(prediction.displayName)")
                            }
                        
                        Text(prediction.summaryText)
                            .font(.subheadline)
                            .foregroundColor(Brand.ColorSystem.secondary)
                        
                        Text("Saved: \(DateFormatter.savedPredictionFormatter.string(from: prediction.timestamp))")
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.secondary)
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
                                .foregroundColor(Brand.ColorSystem.secondary)
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
                    .foregroundColor(Brand.ColorSystem.secondary)
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
                        .foregroundColor(Brand.ColorSystem.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Key result
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f", prediction.expectedEuploidBlastocysts))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Brand.ColorSystem.primary)
                    
                    Text("euploid")
                        .font(.caption2)
                        .foregroundColor(Brand.ColorSystem.secondary)
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
                        .foregroundColor(Brand.ColorSystem.secondary)
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
                    .foregroundColor(Brand.ColorSystem.secondary)
                
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
                        .fill(Brand.ColorSystem.primary.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Text("3")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Brand.ColorSystem.primary)
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
                    color: Brand.ColorSystem.primary
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
                    color: Brand.ColorSystem.secondary
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
        .padding(16)
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
                        .fill(Brand.ColorSystem.primary.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Text(stageNumber)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Brand.ColorSystem.primary)
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
                        color: Brand.ColorSystem.primary
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
                        color: Brand.ColorSystem.secondary
                    )
                }
            }
        }
        .padding(16)
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

// MARK: - Unit Enumerations
enum AMHUnit: String, CaseIterable {
    case ngPerML = "ng/mL"
    case pmolPerL = "pmol/L"
    
    var displayName: String { self.rawValue }
    
    // Conversion factor to ng/mL (standard for calculations)
    var toNgPerMLFactor: Double {
        switch self {
        case .ngPerML: return 1.0
        case .pmolPerL: return 0.14  // 1 pmol/L ≈ 0.14 ng/mL
        }
    }
}

enum EstrogenUnit: String, CaseIterable {
    case pgPerML = "pg/mL"
    case pmolPerL = "pmol/L"
    
    var displayName: String { self.rawValue }
    
    // Conversion factor to pg/mL (standard for calculations)  
    var toPgPerMLFactor: Double {
        switch self {
        case .pgPerML: return 1.0
        case .pmolPerL: return 0.272  // 1 pmol/L ≈ 0.272 pg/mL
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let savedPredictionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
