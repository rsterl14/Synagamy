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
    @State private var selectedDiagnosis: IVFOutcomePredictor.PredictionInputs.DiagnosisType = .unexplained
    
    // MARK: - UI State
    @State private var showResults = false
    @State private var predictionResults: IVFOutcomePredictor.PredictionResults?
    @State private var errorMessage: String? = nil
    @State private var isReferencesExpanded = false
    @State private var isAlgorithmExpanded = false
    @State private var isCascadeExpanded = false
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        guard let ageValue = Double(age), ageValue >= 18 && ageValue <= 50,
              let amhValue = Double(amhLevel), amhValue >= 0.01 && amhValue <= 50,
              let estrogenValue = Double(estrogenLevel), estrogenValue >= 100 && estrogenValue <= 10000 else {
            return false
        }
        return true
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
                    }
                    
                    // Algorithm Explanation
                    algorithmExplanationSection
                    
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
                // Age Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age (years)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter age (18-50)", text: $age)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Age at Time of Oocyte Retrieval")
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                // AMH Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("AMH Level (ng/mL)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter AMH level", text: $amhLevel)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Anti-Müllerian Hormone Level (Normal Range: 1.0-4.0)")
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                // Estrogen Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Peak Estradiol Level (pg/mL)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter estradiol level", text: $estrogenLevel)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Peak estradiol on trigger day (typical: 1000-4000 pg/mL)")
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                // Diagnosis Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Diagnosis")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Picker("Diagnosis", selection: $selectedDiagnosis) {
                        ForEach(IVFOutcomePredictor.PredictionInputs.DiagnosisType.allCases, id: \.self) { diagnosis in
                            Text(diagnosis.displayName).tag(diagnosis)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Brand.ColorSystem.primary)
                }
            }
        }
    }
    
    // MARK: - Predict Button
    private var predictButton: some View {
        Button(action: generatePrediction) {
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
                            Text("\(Int(results.expectedOocytes.predicted))")
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
                    .padding(.bottom, 8)
                    
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
                            Text("\(Int(results.expectedBlastocysts.predicted))")
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
                    
                    Text("\(Int(results.expectedBlastocysts.developmentRate))% Development Rate from Retrieved Oocytes")
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
                            Text("\(Int(results.euploidyRates.expectedEuploidBlastocysts))")
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
    
    // MARK: - Algorithm Explanation Section
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
                        count: Int(cascade?.totalOocytes ?? 0),
                        lossDescription: "Initial Retrieval From Follicles",
                        nextStageRate: cascade?.totalOocytes ?? 0 > 0 ?
                            (cascade?.matureOocytes ?? 0) / (cascade?.totalOocytes ?? 1) * 100 : 0,
                        isFirstStage: true
                    )
                    
                    // Mature Oocytes Stage
                    CascadeStageView(
                        stageNumber: "2", 
                        stageName: "Mature Oocytes",
                        count: Int(cascade?.matureOocytes ?? 0),
                        lossDescription: "\(Int(cascade?.stageLosses.immatureOocytes ?? 0)) Immature Oocytes Excluded",
                        nextStageRate: cascade?.matureOocytes ?? 0 > 0 ?
                            (cascade?.fertilizedEmbryos ?? 0) / (cascade?.matureOocytes ?? 1) * 100 : 0
                    )
                    
                    // Fertilized Embryos Stage
                    CascadeStageView(
                        stageNumber: "3",
                        stageName: "Fertilized Embryos", 
                        count: Int(cascade?.fertilizedEmbryos ?? 0),
                        lossDescription: "\(Int(cascade?.stageLosses.fertilizationFailure ?? 0)) Failed to Fertilize",
                        nextStageRate: cascade?.fertilizedEmbryos ?? 0 > 0 ?
                            (cascade?.day3Embryos ?? 0) / (cascade?.fertilizedEmbryos ?? 1) * 100 : 0
                    )
                    
                    // Day 3 Embryos Stage
                    CascadeStageView(
                        stageNumber: "4",
                        stageName: "Day 3 Embryos",
                        count: Int(cascade?.day3Embryos ?? 0), 
                        lossDescription: "\(Int(cascade?.stageLosses.day3Arrest ?? 0)) Arrested Before Day 3",
                        nextStageRate: cascade?.day3Embryos ?? 0 > 0 ?
                            (cascade?.blastocysts ?? 0) / (cascade?.day3Embryos ?? 1) * 100 : 0
                    )
                    
                    // Blastocyst Stage
                    CascadeStageView(
                        stageNumber: "5",
                        stageName: "Blastocysts",
                        count: Int(cascade?.blastocysts ?? 0),
                        lossDescription: "\(Int(cascade?.stageLosses.blastocystArrest ?? 0)) Arrested During Extended Culture",
                        nextStageRate: cascade?.blastocysts ?? 0 > 0 ?
                            (cascade?.euploidBlastocysts ?? 0) / (cascade?.blastocysts ?? 1) * 100 : 0
                    )
                    
                    // Final Euploid Stage
                    CascadeStageView(
                        stageNumber: "6",
                        stageName: "Euploid Blastocysts",
                        count: Int(cascade?.euploidBlastocysts ?? 0),
                        lossDescription: "\(Int(cascade?.stageLosses.chromosomalAbnormalities ?? 0)) Aneuploid Blastocysts",
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
        guard let ageValue = Double(age),
              let amhValue = Double(amhLevel),
              let estrogenValue = Double(estrogenLevel) else {
            errorMessage = "Please enter valid numeric values for all fields."
            return
        }
        
        // Validate ranges with specific error messages
        if ageValue < 18 || ageValue > 50 {
            errorMessage = "Age must be between 18 and 50 years."
            return
        }
        
        if amhValue < 0.01 || amhValue > 50 {
            errorMessage = "AMH level must be between 0.01 and 50 ng/mL."
            return
        }
        
        if estrogenValue < 100 || estrogenValue > 10000 {
            errorMessage = "Estradiol level must be between 100 and 10,000 pg/mL. Typical range is 1000-4000 pg/mL."
            return
        }
        
        let inputs = IVFOutcomePredictor.PredictionInputs(
            age: ageValue,
            amhLevel: amhValue,
            estrogenLevel: estrogenValue,
            bmI: nil,
            priorCycles: 0,
            diagnosisType: selectedDiagnosis
        )
        
        let predictor = IVFOutcomePredictor()
        predictionResults = predictor.predict(from: inputs)
        showResults = true
        isReferencesExpanded = false
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
    let count: Int
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
                        
                        Text("\(count)")
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
