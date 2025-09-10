//
//  PDFExportService.swift
//  Synagamy3.0
//
//  PDF export service for fertility predictions and cycle data.
//

import SwiftUI
import PDFKit

@MainActor
class PDFExportService: ObservableObject {
    
    // MARK: - Public Methods
    
    func exportPredictionResults(
        _ results: IVFOutcomePredictor.PredictionResults,
        patientAge: Double,
        calculationMode: String
    ) async -> URL? {
        
        let renderer = ImageRenderer(content: createPredictionPDFContent(
            results: results,
            patientAge: patientAge,
            calculationMode: calculationMode
        ))
        
        renderer.proposedSize = .init(width: 612, height: 792) // US Letter size
        
        let pdfData = await createPDFData(from: renderer)
        
        return await savePDFToTempDirectory(data: pdfData, filename: "Synagamy_IVF_Prediction_\(formattedDate()).pdf")
    }
    
    func exportCycleData(
        _ cycle: MenstrualCycle,
        timingAnalysis: [IntercourseTiming],
        fertilityStatus: FertilityStatus
    ) async -> URL? {
        
        let renderer = ImageRenderer(content: createCyclePDFContent(
            cycle: cycle,
            timingAnalysis: timingAnalysis,
            fertilityStatus: fertilityStatus
        ))
        
        renderer.proposedSize = .init(width: 612, height: 792)
        
        let pdfData = await createPDFData(from: renderer)
        
        return await savePDFToTempDirectory(data: pdfData, filename: "Synagamy_Cycle_Tracking_\(formattedDate()).pdf")
    }
    
    // MARK: - Private Methods
    
    private func createPDFData(from renderer: ImageRenderer<some View>) async -> Data {
        return await MainActor.run {
            let mutableData = NSMutableData()
            let consumer = CGDataConsumer(data: mutableData)!
            var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
            
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                return Data()
            }
            
            context.beginPDFPage(nil)
            
            // Render the view to get UIImage first, then draw into PDF context
            let uiImage = renderer.uiImage
            if let cgImage = uiImage?.cgImage {
                context.draw(cgImage, in: mediaBox)
            }
            
            context.endPDFPage()
            context.closePDF()
            
            return mutableData as Data
        }
    }
    
    private func savePDFToTempDirectory(data: Data, filename: String) async -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter.string(from: Date())
    }
    
    // MARK: - PDF Content Views
    
    @ViewBuilder
    private func createPredictionPDFContent(
        results: IVFOutcomePredictor.PredictionResults,
        patientAge: Double,
        calculationMode: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Synagamy IVF Outcome Prediction")
                        .font(.title.bold())
                        .foregroundColor(Brand.ColorSystem.primary)
                    
                    Spacer()
                    
                    Text("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Educational Tool - Consult Your Healthcare Provider")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Divider()
            }
            
            // Patient Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Patient Information")
                    .font(.headline.bold())
                    .foregroundColor(Brand.ColorSystem.primary)
                
                HStack {
                    Text("Age: \(String(format: "%.0f", patientAge)) years")
                    Spacer()
                    Text("Calculation Mode: \(calculationMode)")
                }
                .font(.subheadline)
            }
            
            // Prediction Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Prediction Summary")
                    .font(.headline.bold())
                    .foregroundColor(Brand.ColorSystem.primary)
                
                predictionSummaryTable(results)
            }
            
            // Cascade Flow
            VStack(alignment: .leading, spacing: 12) {
                Text("Embryo Development Cascade")
                    .font(.headline.bold())
                    .foregroundColor(Brand.ColorSystem.primary)
                
                cascadeFlowTable(results.cascadeFlow)
            }
            
            // Confidence and Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Clinical Notes")
                    .font(.headline.bold())
                    .foregroundColor(Brand.ColorSystem.primary)
                
                Text("Confidence Level: \(results.confidenceLevel.rawValue)")
                    .font(.subheadline.weight(.medium))
                
                ForEach(results.clinicalNotes.prefix(5), id: \.self) { note in
                    Text("• \(note)")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
            
            // Medical Disclaimer
            disclaimerSection
        }
        .padding(40)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }
    
    @ViewBuilder
    private func createCyclePDFContent(
        cycle: MenstrualCycle,
        timingAnalysis: [IntercourseTiming],
        fertilityStatus: FertilityStatus
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Synagamy Cycle Tracking Report")
                        .font(.title.bold())
                        .foregroundColor(Brand.ColorSystem.primary)
                    
                    Spacer()
                    
                    Text("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Educational Tool - Consult Your Healthcare Provider")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Divider()
            }
            
            // Cycle Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Cycle Information")
                    .font(.headline.bold())
                    .foregroundColor(Brand.ColorSystem.primary)
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                    GridRow {
                        Text("Last Period Date:")
                        Text(cycle.lastPeriodDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    GridRow {
                        Text("Cycle Length:")
                        Text("\(cycle.averageLength) days")
                    }
                    GridRow {
                        Text("Current Day:")
                        Text("Day \(cycle.currentDay)")
                    }
                    GridRow {
                        Text("Next Period:")
                        Text(cycle.nextPeriodDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    GridRow {
                        Text("Ovulation Date:")
                        Text(cycle.ovulationDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.subheadline)
            }
            
            // Current Fertility Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Fertility Status")
                    .font(.headline.bold())
                    .foregroundColor(Brand.ColorSystem.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase: \(fertilityStatus.title)")
                        .font(.subheadline.weight(.medium))
                    
                    Text("Fertility Level: \(fertilityStatus.fertilityLevel.description)")
                        .font(.subheadline)
                    
                    Text(fertilityStatus.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Timing Analysis
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Timing Analysis")
                    .font(.headline.bold())
                    .foregroundColor(Brand.ColorSystem.primary)
                
                ForEach(timingAnalysis.prefix(3), id: \.id) { timing in
                    HStack(alignment: .top) {
                        Circle()
                            .fill(timing.priority.color)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timing.title)
                                .font(.subheadline.weight(.medium))
                            
                            Text(timing.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            // Medical Disclaimer
            disclaimerSection
        }
        .padding(40)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }
    
    @ViewBuilder
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Important Medical Disclaimer")
                .font(.headline.bold())
                .foregroundColor(.orange)
            
            Text("This report is generated by the Synagamy educational fertility app and is intended for informational purposes only. The predictions and analysis provided should not be used as a substitute for professional medical advice, diagnosis, or treatment. Always consult with qualified healthcare professionals, including reproductive endocrinologists or fertility specialists, for personalized medical guidance regarding fertility, reproductive health, and treatment decisions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func predictionSummaryTable(_ results: IVFOutcomePredictor.PredictionResults) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
            GridRow {
                Text("Metric")
                    .font(.subheadline.bold())
                Text("Predicted Value")
                    .font(.subheadline.bold())
                Text("Range")
                    .font(.subheadline.bold())
            }
            .foregroundColor(Brand.ColorSystem.primary)
            
            Divider()
            
            GridRow {
                Text("Oocytes Retrieved")
                Text(String(format: "%.1f", results.expectedOocytes.predicted))
                Text("\(String(format: "%.1f", results.expectedOocytes.range.lowerBound))-\(String(format: "%.1f", results.expectedOocytes.range.upperBound))")
            }
            
            GridRow {
                Text("Fertilized Embryos (ICSI)")
                Text(String(format: "%.1f", results.expectedFertilization.icsi.predicted))
                Text("\(String(format: "%.1f", results.expectedFertilization.icsi.range.lowerBound))-\(String(format: "%.1f", results.expectedFertilization.icsi.range.upperBound))")
            }
            
            GridRow {
                Text("Blastocysts")
                Text(String(format: "%.1f", results.expectedBlastocysts.predicted))
                Text("\(String(format: "%.1f", results.expectedBlastocysts.range.lowerBound))-\(String(format: "%.1f", results.expectedBlastocysts.range.upperBound))")
            }
            
            GridRow {
                Text("Euploid Blastocysts")
                Text(String(format: "%.1f", results.euploidyRates.expectedEuploidBlastocysts))
                Text("\(String(format: "%.0f", results.euploidyRates.range.lowerBound * 100))%-\(String(format: "%.0f", results.euploidyRates.range.upperBound * 100))%")
            }
        }
        .font(.caption)
    }
    
    @ViewBuilder
    private func cascadeFlowTable(_ cascade: IVFOutcomePredictor.PredictionResults.CascadeFlow) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 4) {
            GridRow {
                Text("Stage")
                    .font(.subheadline.bold())
                Text("Count")
                    .font(.subheadline.bold())
                Text("Loss")
                    .font(.subheadline.bold())
            }
            .foregroundColor(Brand.ColorSystem.primary)
            
            Divider()
            
            GridRow {
                Text("Total Oocytes")
                Text(String(format: "%.1f", cascade.totalOocytes))
                Text(String(format: "%.1f immature", cascade.stageLosses.immatureOocytes))
            }
            
            GridRow {
                Text("Mature Oocytes")
                Text(String(format: "%.1f", cascade.matureOocytes))
                Text(String(format: "%.1f failed fertilization", cascade.stageLosses.fertilizationFailure))
            }
            
            GridRow {
                Text("Fertilized Embryos")
                Text(String(format: "%.1f", cascade.fertilizedEmbryos))
                Text(String(format: "%.1f Day 3 arrest", cascade.stageLosses.day3Arrest))
            }
            
            GridRow {
                Text("Day 3 Embryos")
                Text(String(format: "%.1f", cascade.day3Embryos))
                Text(String(format: "%.1f blastocyst arrest", cascade.stageLosses.blastocystArrest))
            }
            
            GridRow {
                Text("Blastocysts")
                Text(String(format: "%.1f", cascade.blastocysts))
                Text(String(format: "%.1f aneuploid", cascade.aneuploidBlastocysts))
            }
            
            GridRow {
                Text("Euploid Blastocysts")
                    .foregroundColor(Brand.ColorSystem.primary)
                    .font(.subheadline.bold())
                Text(String(format: "%.1f", cascade.euploidBlastocysts))
                    .foregroundColor(Brand.ColorSystem.primary)
                    .font(.subheadline.bold())
                Text("Final result")
                    .foregroundColor(Brand.ColorSystem.primary)
            }
        }
        .font(.caption)
    }
}