//
//  EmbryoTransferPredictorView.swift
//  Synagamy3.0
//
//  Interactive tool for predicting embryo transfer success rates.
//  Provides evidence-based predictions for live birth rates pre-transfer.
//

import SwiftUI

struct EmbryoTransferPredictorView: View {
    @StateObject private var viewModel = EmbryoTransferViewModel()
    @State private var showingResults = false
    @State private var showingInfoSheet = false
    @State private var isAboutExpanded = false
    @State private var isReferencesExpanded = false
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EmbryoTransferLogo",
            showHomeButton: true,
            usePopToRoot: true,
            showBackButton: true
        ) {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Input Form
                    inputFormSection
                    
                    // MARK: - Calculate Button
                    calculateButton
                    
                    // MARK: - Results Section
                    if showingResults, let prediction = viewModel.prediction {
                        resultsSection(prediction: prediction)
                    }
                    
                    // MARK: - About Section
                    aboutSection
                }
                .padding(.vertical, Brand.Spacing.lg)
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            EmbryoTransferInfoSheet()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Brand.Spacing.md) {
            CategoryBadge(
                text: "Embryo Transfer Predictor",
                icon: "chart.line.uptrend.xyaxis",
                color: Brand.Color.primary
            )
            
            Text("Pre-Transfer Success Rate Calculator")
                .font(Brand.Typography.headlineMedium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Evidence-based predictions for single embryo transfer")
                .font(.caption)
                .foregroundColor(Brand.Color.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingInfoSheet = true
            } label: {
                HStack(spacing: Brand.Spacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text("Learn More")
                        .font(Brand.Typography.labelSmall)
                }
                .foregroundColor(Brand.Color.primary)
            }
        }
    }
    
    // MARK: - Input Form Section
    private var inputFormSection: some View {
        VStack(spacing: Brand.Spacing.lg) {
            // Oocyte Age Input
            EnhancedContentBlock(
                title: "Maternal Age at Egg Retrieval",
                icon: "person.fill"
            ) {
                VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                    HStack {
                        Text("\(viewModel.input.oocyteAge) years")
                            .font(Brand.Typography.headlineMedium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: Brand.Spacing.lg) {
                            Button {
                                if viewModel.input.oocyteAge > 20 {
                                    viewModel.input.oocyteAge -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Brand.Color.primary)
                            }
                            
                            Button {
                                if viewModel.input.oocyteAge < 50 {
                                    viewModel.input.oocyteAge += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Brand.Color.primary)
                            }
                        }
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.input.oocyteAge) },
                            set: { viewModel.input.oocyteAge = Int($0) }
                        ),
                        in: 20...50,
                        step: 1
                    )
                    .tint(Brand.Color.primary)
                    
                    Text("Age at the time of oocyte retrieval")
                        .font(.caption2)
                        .foregroundColor(Brand.Color.secondary)
                }
            }
            
            // Embryo Day Selection
            EnhancedContentBlock(
                title: "Embryo Development Day",
                icon: "calendar"
            ) {
                VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                    Picker("Embryo Day", selection: $viewModel.input.embryoDay) {
                        ForEach(EmbryoDay.allCases) { day in
                            Text(day.rawValue).tag(day)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text("Day of blastocyst development")
                        .font(.caption2)
                        .foregroundColor(Brand.Color.secondary)
                }
            }
            
            // Blastocyst Grade Selection
            EnhancedContentBlock(
                title: "Blastocyst Grade",
                icon: "hexagon.fill"
            ) {
                VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                    // Current Grade Display
                    HStack {
                        Text("Current Grade")
                            .font(Brand.Typography.labelLarge)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(viewModel.input.blastocystGrade.displayName)
                            .font(Brand.Typography.headlineMedium)
                            .foregroundColor(Brand.Color.primary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, Brand.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.sm)
                            .fill(Brand.Color.primary.opacity(0.08))
                    )
                    
                    // Grade Components
                    HStack(spacing: Brand.Spacing.xl) {
                        Spacer()
                        // Expansion
                        VStack(spacing: Brand.Spacing.sm) {
                            Text("Expansion")
                                .font(Brand.Typography.labelSmall)
                                .foregroundColor(.primary)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: Brand.Spacing.xs) {
                                    ForEach(BlastocystExpansion.allCases, id: \.self) { expansion in
                                        Button {
                                            viewModel.input.blastocystGrade = BlastocystGrade(
                                                expansion: expansion,
                                                icmGrade: viewModel.input.blastocystGrade.icmGrade,
                                                teGrade: viewModel.input.blastocystGrade.teGrade
                                            )
                                        } label: {
                                            Text("\(expansion.rawValue)")
                                                .font(Brand.Typography.labelLarge)
                                                .foregroundColor(viewModel.input.blastocystGrade.expansion == expansion ? .white : Brand.Color.primary)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(viewModel.input.blastocystGrade.expansion == expansion ? 
                                                              Brand.Color.primary : 
                                                              Brand.Color.primary.opacity(0.1))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .frame(height: 120)
                        }
                        
                        // ICM
                        VStack(spacing: Brand.Spacing.sm) {
                            Text("ICM")
                                .font(Brand.Typography.labelSmall)
                                .foregroundColor(.primary)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: Brand.Spacing.xs) {
                                    ForEach(CellQuality.allCases, id: \.self) { quality in
                                        Button {
                                            viewModel.input.blastocystGrade = BlastocystGrade(
                                                expansion: viewModel.input.blastocystGrade.expansion,
                                                icmGrade: quality,
                                                teGrade: viewModel.input.blastocystGrade.teGrade
                                            )
                                        } label: {
                                            Text(String(quality.rawValue.first!))
                                                .font(Brand.Typography.labelLarge)
                                                .foregroundColor(viewModel.input.blastocystGrade.icmGrade == quality ? .white : Brand.Color.primary)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(viewModel.input.blastocystGrade.icmGrade == quality ? 
                                                              Brand.Color.primary : 
                                                              Brand.Color.primary.opacity(0.1))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .frame(height: 120)
                        }
                        
                        // Trophectoderm
                        VStack(spacing: Brand.Spacing.sm) {
                            Text("TE")
                                .font(Brand.Typography.labelSmall)
                                .foregroundColor(.primary)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: Brand.Spacing.xs) {
                                    ForEach(CellQuality.allCases, id: \.self) { quality in
                                        Button {
                                            viewModel.input.blastocystGrade = BlastocystGrade(
                                                expansion: viewModel.input.blastocystGrade.expansion,
                                                icmGrade: viewModel.input.blastocystGrade.icmGrade,
                                                teGrade: quality
                                            )
                                        } label: {
                                            Text(String(quality.rawValue.first!))
                                                .font(Brand.Typography.labelLarge)
                                                .foregroundColor(viewModel.input.blastocystGrade.teGrade == quality ? .white : Brand.Color.primary)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(viewModel.input.blastocystGrade.teGrade == quality ? 
                                                              Brand.Color.primary : 
                                                              Brand.Color.primary.opacity(0.1))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .frame(height: 120)
                        }
                        Spacer()
                    }
                    
                    Text("Scroll each column to build your grade • \(viewModel.input.blastocystGrade.qualityCategory) quality")
                        .font(.caption)
                        .foregroundColor(Brand.Color.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Genetic Status Selection
            EnhancedContentBlock(
                title: "Genetic Testing Status",
                icon: "waveform.path.ecg"
            ) {
                VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                    ForEach(GeneticStatus.allCases) { status in
                        Button {
                            viewModel.input.geneticStatus = status
                            if status != .mosaic {
                                viewModel.input.mosaicType = nil
                            }
                        } label: {
                            HStack {
                                Text(status.rawValue)
                                    .font(Brand.Typography.labelLarge)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if viewModel.input.geneticStatus == status {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Brand.Color.primary)
                                }
                            }
                            .padding(Brand.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                    .fill(viewModel.input.geneticStatus == status ? 
                                          Brand.Color.primary.opacity(0.1) : 
                                          Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                            .stroke(viewModel.input.geneticStatus == status ?
                                                   Brand.Color.primary :
                                                   Brand.Color.hairline, lineWidth: 1)
                                    )
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Mosaic Type Selection (if mosaic is selected)
                    if viewModel.input.geneticStatus == .mosaic {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("Mosaic Type")
                            .font(Brand.Typography.labelLarge)
                            .foregroundColor(.primary)
                        
                        ForEach(MosaicType.allCases) { type in
                            Button {
                                viewModel.input.mosaicType = type
                            } label: {
                                HStack {
                                    Text(type.rawValue)
                                        .font(Brand.Typography.labelLarge)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if viewModel.input.mosaicType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Brand.Color.primary)
                                    }
                                }
                                .padding(Brand.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                        .fill(viewModel.input.mosaicType == type ? 
                                              Brand.Color.primary.opacity(0.08) : 
                                              Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                                                .stroke(viewModel.input.mosaicType == type ?
                                                       Brand.Color.primary.opacity(0.5) :
                                                       Brand.Color.hairline.opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Calculate Button
    private var calculateButton: some View {
        Button {
            viewModel.calculatePrediction()
            withAnimation(.spring()) {
                showingResults = true
            }
        } label: {
            HStack(spacing: Brand.Spacing.sm) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(Brand.Typography.labelLarge)
                Text("Calculate Success Rates")
                    .font(Brand.Typography.labelLarge)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Brand.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                    .fill(Brand.Color.primary)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Results Section
    private func resultsSection(prediction: EmbryoTransferPrediction) -> some View {
        VStack(spacing: Brand.Spacing.lg) {
            EnhancedContentBlock(
                title: "Predicted Outcomes",
                icon: "chart.bar.fill"
            ) {
                VStack(spacing: Brand.Spacing.lg) {
                    // Live Birth Rate (Primary Outcome)
                    VStack(spacing: Brand.Spacing.sm) {
                        HStack {
                            Text("Live Birth Rate")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(prediction.liveBirthRateFormatted)
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.Color.success)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                    .fill(Brand.Color.hairline.opacity(0.3))
                                    .frame(height: 24)
                                
                                RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                    .fill(
                                        LinearGradient(
                                            colors: [Brand.Color.success.opacity(0.8), Brand.Color.success],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * prediction.liveBirthRate, height: 24)
                                    .animation(.spring(), value: prediction.liveBirthRate)
                            }
                        }
                        .frame(height: 24)
                    }
                    
                    Divider()
                    
                    // Secondary Outcomes
                    VStack(spacing: Brand.Spacing.md) {
                        OutcomeRow(
                            title: "Clinical Pregnancy Rate",
                            value: prediction.clinicalPregnancyRateFormatted,
                            color: Brand.Color.primary
                        )
                        
                        OutcomeRow(
                            title: "Implantation Rate",
                            value: prediction.implantationRateFormatted,
                            color: Brand.Color.primary
                        )
                        
                        OutcomeRow(
                            title: "Miscarriage Rate",
                            value: prediction.miscarriageRateFormatted,
                            color: .orange
                        )
                    }
                    
                }
            }
            
            
            // References
            ExpandableSection(
                title: "Medical References",
                subtitle: "Peer-reviewed sources",
                icon: "doc.text",
                isExpanded: $isReferencesExpanded
            ) {
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    ForEach(prediction.references, id: \.self) { reference in
                        HStack(alignment: .top, spacing: Brand.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(Brand.Color.success)
                                .padding(.top, 2)
                            
                            Text(reference)
                                .font(.caption2)
                                .foregroundColor(Brand.Color.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        ExpandableSection(
            title: "About This Calculator",
            subtitle: "Evidence-based methodology",
            icon: "questionmark.circle",
            isExpanded: $isAboutExpanded
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("How It Works")
                    .font(Brand.Typography.labelLarge)
                    .foregroundColor(.primary)
                
                Text("This calculator uses data from peer-reviewed studies involving thousands of embryo transfers to predict success rates based on:")
                    .font(.caption)
                    .foregroundColor(Brand.Color.secondary)
                
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    BulletPoint(text: "Maternal age at transfer")
                    BulletPoint(text: "Embryo morphology grade")
                    BulletPoint(text: "Day of blastocyst development")
                    BulletPoint(text: "Genetic testing results (PGT-A)")
                }
                
                Text("Limitations")
                    .font(Brand.Typography.labelLarge)
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                
                Text("This calculator provides population-based estimates. Individual outcomes depend on many factors not captured here, including:")
                    .font(.caption)
                    .foregroundColor(Brand.Color.secondary)
                
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    BulletPoint(text: "Underlying fertility diagnosis")
                    BulletPoint(text: "Endometrial receptivity")
                    BulletPoint(text: "Previous transfer history")
                    BulletPoint(text: "Laboratory conditions")
                    BulletPoint(text: "Transfer technique")
                }
            }
        }
    }
    
}

// MARK: - Supporting Views

private struct OutcomeRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(Brand.Typography.labelSmall)
                .foregroundColor(Brand.Color.secondary)
            Spacer()
            Text(value)
                .font(Brand.Typography.labelLarge)
                .foregroundColor(color)
        }
    }
}

private struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Brand.Spacing.sm) {
            Circle()
                .fill(Brand.Color.primary)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Brand.Color.secondary)
        }
    }
}

private struct GradeExplanationRow: View {
    let title: String
    let description: String
    let examples: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
            Text(title)
                .font(Brand.Typography.labelSmall)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(Brand.Color.secondary)
            
            Text("e.g., \(examples)")
                .font(.caption2)
                .foregroundColor(Brand.Color.secondary.opacity(0.8))
                .italic()
        }
    }
}

private struct BlastocystComponentPicker<T: CaseIterable & Identifiable>: View where T: Hashable {
    let title: String
    let description: String
    @Binding var selection: T
    let options: [T]
    let displayValue: (T) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                    Text(title)
                        .font(Brand.Typography.labelLarge)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(Brand.Color.secondary)
                }
                
                Spacer()
            }
            
            // Picker Wheel
            HStack {
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(displayValue(option))
                            .tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipped()
                
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.sm, style: .continuous)
                    .fill(Brand.Color.primary.opacity(0.05))
            )
        }
    }
}

// MARK: - View Model

class EmbryoTransferViewModel: ObservableObject {
    @Published var input = EmbryoTransferInput()
    @Published var prediction: EmbryoTransferPrediction?
    
    func calculatePrediction() {
        prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
    }
}

// MARK: - Info Sheet

struct EmbryoTransferInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                    // Understanding Embryo Grading
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Text("Understanding Embryo Grading")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Embryos are graded based on their appearance under a microscope. The grading system evaluates:")
                            .font(.subheadline)
                            .foregroundColor(Brand.Color.secondary)
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            InfoPoint(
                                title: "Expansion",
                                description: "How expanded the blastocyst cavity is (1-6 scale)"
                            )
                            
                            InfoPoint(
                                title: "Inner Cell Mass (ICM)",
                                description: "Quality of cells that become the baby (A, B, or C)"
                            )
                            
                            InfoPoint(
                                title: "Trophectoderm",
                                description: "Quality of cells that become the placenta (A, B, or C)"
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Genetic Testing Explained
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Text("Genetic Testing (PGT-A)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            InfoPoint(
                                title: "Euploid",
                                description: "Normal number of chromosomes (46). Best chance of success."
                            )
                            
                            InfoPoint(
                                title: "Mosaic",
                                description: "Mix of normal and abnormal cells. Intermediate success rates."
                            )
                            
                            InfoPoint(
                                title: "Aneuploid",
                                description: "Abnormal chromosome number. Associated with lower success rates."
                            )
                            
                            InfoPoint(
                                title: "Untested",
                                description: "No genetic testing performed. Success depends heavily on age."
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Day 5 vs Day 6
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Text("Development Day")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Embryos that reach blastocyst stage on Day 5 generally have higher success rates than Day 6, though high-quality Day 6 embryos can still be very successful.")
                            .font(.subheadline)
                            .foregroundColor(Brand.Color.secondary)
                    }
                    
                    Divider()
                    
                    // Oocyte Age vs Current Age
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Text("Why Oocyte Age Matters")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("The age when eggs were retrieved determines embryo quality, not your current age at transfer. For example:")
                            .font(.subheadline)
                            .foregroundColor(Brand.Color.secondary)
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            InfoPoint(
                                title: "Fresh Transfer",
                                description: "Oocyte age = your current age"
                            )
                            
                            InfoPoint(
                                title: "Frozen Transfer",
                                description: "Oocyte age = your age when eggs were retrieved (could be years ago)"
                            )
                            
                            InfoPoint(
                                title: "Donor Eggs",
                                description: "Oocyte age = donor's age at retrieval"
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Learn More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct InfoPoint: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.caption)
                .foregroundColor(Brand.Color.primary)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                Text(title)
                    .font(Brand.Typography.labelLarge)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Brand.Color.secondary)
            }
        }
    }
}


#Preview {
    NavigationStack {
        EmbryoTransferPredictorView()
    }
}
