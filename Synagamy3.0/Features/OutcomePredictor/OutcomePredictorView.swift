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
                return "Predict oocytes and all subsequent outcomes"
            case .postRetrieval:
                return "Enter known oocyte count and predict remaining stages"
            }
        }
    }
    
    // MARK: - UI State
    @State private var showResults = false
    @State private var predictionResults: IVFOutcomePredictor.PredictionResults?
    @State private var errorMessage: String? = nil
    @State private var isReferencesExpanded = false
    @State private var isCascadeExpanded = false
    
    // MARK: - Validation State
    @State private var ageValidationMessage: String? = nil
    @State private var amhValidationMessage: String? = nil
    @State private var estrogenValidationMessage: String? = nil
    @State private var oocyteValidationMessage: String? = nil
    
    // MARK: - Export State
    @State private var showingShareSheet = false
    @State private var pdfURL: URL? = nil
    @State private var isExporting = false
    @StateObject private var pdfExporter = PDFExportService()
    
    // MARK: - Error Handling
    @StateObject private var errorHandler = AppErrorHandler()
    
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
                    
                    // Input Form
                    inputFormSection
                    
                    // Predict Button
                    predictButton
                    
                    // Results Section
                    if showResults, let results = predictionResults {
                        resultsSection(results)
                        
                        // Export Section
                        exportSection
                    }
                    
                    // Disclaimer
                    disclaimerSection
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
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
        .errorHandling(errorHandler)
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
            
            Text("Based on North American Data (CARTR-BORN & CDC/SART)")
                .font(.caption)
                .foregroundColor(Brand.ColorSystem.secondary)
                .multilineTextAlignment(.center)
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
                    Text("Age (years)")
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
                                .onChange(of: amhLevel) { _, newValue in
                                    validateAMH(newValue)
                                }
                                .onChange(of: amhUnit) { _, _ in
                                    validateAMH(amhLevel)
                                }
                            
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
                            Text("Anti-Müllerian Hormone Level (Normal Range: \(amhUnit == .ngPerML ? "1.0-4.0 ng/mL" : "7.0-28.6 pmol/L"))")
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
                        
                        Text("Peak estradiol on trigger day (typical: \(estrogenUnit == .pgPerML ? "1000-4000 pg/mL" : "3676-14706 pmol/L"))")
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
                        
                        Text("Total oocytes retrieved during your cycle")
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.secondary)
                    }
                }
                
                // Diagnosis Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Diagnosis")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Picker("Select Diagnosis", selection: $selectedDiagnosis) {
                        ForEach(IVFOutcomePredictor.PredictionInputs.DiagnosisType.allCases, id: \.self) { diagnosis in
                            Text(diagnosis.displayName).tag(diagnosis)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Brand.ColorSystem.primary)
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
                    
                    Text("Underlying fertility diagnosis affecting treatment approach")
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
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
                    // Recommendation Header
                    VStack(spacing: 6) {
                        Text(results.expectedFertilization.recommendedProcedure)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Brand.ColorSystem.primary)
                        
                        Text(results.expectedFertilization.explanation)
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
            
            // References Section
            ExpandableSection(
                title: "Clinical References",
                subtitle: "\(results.references.count) sources",
                icon: "doc.text",
                isExpanded: $isReferencesExpanded
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(results.references.enumerated()), id: \.offset) { index, reference in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(Brand.ColorSystem.primary)
                                .frame(minWidth: 20, alignment: .leading)
                            
                            Text(reference)
                                .font(.footnote)
                                .foregroundColor(Brand.ColorSystem.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        if index < results.references.count - 1 {
                            Divider()
                        }
                    }
                }
            }
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
                    
                    // Fertilized Embryos Stage
                    CascadeStageView(
                        stageNumber: "3",
                        stageName: "Fertilized Embryos (2PN)", 
                        count: cascade?.fertilizedEmbryos ?? 0,
                        lossDescription: {
                            let failed = cascade?.stageLosses.fertilizationFailure ?? 0
                            if failed < 0.1 {
                                return "All Mature Oocytes Fertilized Successfully"
                            } else {
                                return String(format: "%.1f Failed Fertilization", failed)
                            }
                        }(),
                        nextStageRate: {
                            guard let fertilized = cascade?.fertilizedEmbryos, fertilized > 0,
                                  let day3 = cascade?.day3Embryos else { return 0 }
                            return (day3 / fertilized) * 100
                        }()
                    )
                    
                    // Day 3 Embryos Stage
                    CascadeStageView(
                        stageNumber: "4",
                        stageName: "Day 3 Embryos (8-cell)",
                        count: cascade?.day3Embryos ?? 0, 
                        lossDescription: {
                            let arrested = cascade?.stageLosses.day3Arrest ?? 0
                            if arrested < 0.1 {
                                return "All Fertilized Embryos Progressed to Day 3"
                            } else {
                                return String(format: "%.1f Failed to Reach 8-Cell Stage", arrested)
                            }
                        }(),
                        nextStageRate: {
                            guard let day3 = cascade?.day3Embryos, day3 > 0,
                                  let blasts = cascade?.blastocysts else { return 0 }
                            return (blasts / day3) * 100
                        }()
                    )
                    
                    // Blastocyst Stage
                    CascadeStageView(
                        stageNumber: "5",
                        stageName: "Blastocysts (Day 5-6)",
                        count: cascade?.blastocysts ?? 0,
                        lossDescription: {
                            let arrested = cascade?.stageLosses.blastocystArrest ?? 0
                            if arrested < 0.1 {
                                return "All Day 3 Embryos Reached Blastocyst Stage"
                            } else {
                                return String(format: "%.1f Arrested During Extended Culture", arrested)
                            }
                        }(),
                        nextStageRate: {
                            guard let blasts = cascade?.blastocysts, blasts > 0,
                                  let euploid = cascade?.euploidBlastocysts else { return 0 }
                            return (euploid / blasts) * 100
                        }()
                    )
                    
                    // Final Euploid Stage
                    CascadeStageView(
                        stageNumber: "6",
                        stageName: "Euploid Blastocysts",
                        count: cascade?.euploidBlastocysts ?? 0,
                        lossDescription: {
                            let aneuploid = cascade?.stageLosses.chromosomalAbnormalities ?? 0
                            if aneuploid < 0.1 {
                                return "All Blastocysts Are Chromosomally Normal"
                            } else {
                                return String(format: "%.1f Aneuploid (Abnormal)", aneuploid)
                            }
                        }(),
                        nextStageRate: nil,
                        isFinalStage: true
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
    
    // MARK: - Disclaimer Section
    private var disclaimerSection: some View {
        EnhancedContentBlock(
            title: "Important Medical Disclaimer",
            icon: "exclamationmark.triangle"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Educational Tool Only")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text("These predictions are based on population averages and should not replace personalized medical advice. Individual outcomes may vary significantly based on many factors not captured in this calculator.")
                    .font(.footnote)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.leading)
                
                Text("Always consult with your fertility specialist for personalized treatment planning and outcome expectations.")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Brand.ColorSystem.primary)
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
            let typicalMin = estrogenUnit == .pgPerML ? "1000" : String(format: "%.0f", 1000 / estrogenUnit.toPgPerMLFactor)
            let typicalMax = estrogenUnit == .pgPerML ? "4000" : String(format: "%.0f", 4000 / estrogenUnit.toPgPerMLFactor)
            errorMessage = "Estradiol level must be between \(minValue) and \(maxValue) \(estrogenUnitText). Typical range is \(typicalMin)-\(typicalMax) \(estrogenUnitText)."
            return
        }
        
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: age,
            amhLevel: amhInNgML,
            estrogenLevel: estrogenInPgML,
            bmI: nil,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis
        )
        
        let predictor = IVFOutcomePredictor()
        predictionResults = predictor.predict(from: inputs)
        showResults = true
        isReferencesExpanded = false
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
        
        // Create inputs with dummy values for AMH/E2 since we're starting from known oocyte count
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: age,
            amhLevel: 2.0, // Dummy value
            estrogenLevel: 2000, // Dummy value
            bmI: nil,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis
        )
        
        let predictor = IVFOutcomePredictor()
        predictionResults = predictor.predictFromRetrievedOocytes(oocyteCount: oocyteCount, inputs: inputs)
        showResults = true
        isReferencesExpanded = false
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        EnhancedContentBlock(
            title: "Export & Share",
            icon: "square.and.arrow.up"
        ) {
            VStack(spacing: Brand.Spacing.md) {
                HStack(spacing: 12) {
                    Button(action: exportToPDF) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.fill")
                            }
                            Text(isExporting ? "Generating..." : "Export PDF")
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
                    .disabled(isExporting)
                    
                    Button(action: shareResults) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Summary")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Brand.ColorSystem.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Brand.ColorSystem.primary, lineWidth: 1.5)
                        )
                    }
                }
                
                Text("Share your prediction results with your healthcare provider or save for your records.")
                    .font(.caption)
                    .foregroundColor(Brand.ColorSystem.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Export Functions
    
    private func exportToPDF() {
        guard let results = predictionResults,
              let ageValue = Double(age) else { return }
        
        isExporting = true
        
        Task { @MainActor in
            let url = await pdfExporter.exportPredictionResults(
                results,
                patientAge: ageValue,
                calculationMode: calculationMode.displayName
            )
            
            isExporting = false
            
            if let url = url {
                pdfURL = url
                showingShareSheet = true
            }
        }
    }
    
    private func shareResults() {
        guard let results = predictionResults else { return }
        
        let summary = createShareSummary(results)
        let activityVC = UIActivityViewController(activityItems: [summary], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func createShareSummary(_ results: IVFOutcomePredictor.PredictionResults) -> String {
        let ageText = age.isEmpty ? "N/A" : age
        let modeText = calculationMode.displayName
        
        return """
        Synagamy IVF Prediction Summary
        
        Patient Age: \(ageText) years
        Calculation Mode: \(modeText)
        Generated: \(Date().formatted(date: .abbreviated, time: .shortened))
        
        PREDICTIONS:
        • Oocytes: \(String(format: "%.1f", results.expectedOocytes.predicted))
        • Fertilized Embryos: \(String(format: "%.1f", results.expectedFertilization.icsi.predicted))
        • Blastocysts: \(String(format: "%.1f", results.expectedBlastocysts.predicted))
        • Euploid Blastocysts: \(String(format: "%.1f", results.euploidyRates.expectedEuploidBlastocysts))
        
        Confidence: \(results.confidenceLevel.rawValue)
        
        DISCLAIMER: This is an educational tool. Always consult your healthcare provider for personalized medical advice.
        
        Generated by Synagamy - Educational Fertility App
        """
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
    
    private func validateAMH(_ value: String) {
        guard !value.isEmpty else {
            amhValidationMessage = nil
            return
        }
        
        guard let amhValue = Double(value) else {
            amhValidationMessage = "Please enter a valid number"
            return
        }
        
        let amhInNgML = amhValue * amhUnit.toNgPerMLFactor
        let unitText = amhUnit.displayName
        
        if amhInNgML < 0.01 {
            let minValue = amhUnit == .ngPerML ? "0.01" : String(format: "%.1f", 0.01 / amhUnit.toNgPerMLFactor)
            amhValidationMessage = "AMH must be at least \(minValue) \(unitText)"
        } else if amhInNgML > 50 {
            let maxValue = amhUnit == .ngPerML ? "50" : String(format: "%.0f", 50 / amhUnit.toNgPerMLFactor)
            amhValidationMessage = "AMH must be \(maxValue) \(unitText) or less"
        } else {
            // Show helpful range information
            let normalRange = amhUnit == .ngPerML ? "1.0-4.0" : "7.0-28.6"
            if amhInNgML < (amhUnit == .ngPerML ? 1.0 : 7.0) {
                amhValidationMessage = "✓ Valid (below normal range \(normalRange) \(unitText))"
            } else if amhInNgML > (amhUnit == .ngPerML ? 4.0 : 28.6) {
                amhValidationMessage = "✓ Valid (above normal range \(normalRange) \(unitText))"
            } else {
                amhValidationMessage = "✓ Normal range"
            }
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
        case .tubalFactor:
            return "Tubal Factor"
        case .endometriosis:
            return "Endometriosis"
        case .diminishedOvarianReserve:
            return "Diminished Ovarian Reserve"
        case .other:
            return "Other"
        }
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
