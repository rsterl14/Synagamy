//
//  SavedPredictionsView.swift
//  Synagamy3.0
//
//  View for displaying and managing saved IVF predictions
//

import SwiftUI

struct SavedPredictionsView: View {
    @StateObject private var persistenceService = PredictionPersistenceService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPrediction: SavedPrediction?
    @State private var showingPredictionDetail = false
    @State private var editingPrediction: SavedPrediction?
    @State private var showingEditAlert = false
    @State private var editNickname = ""
    @State private var showingDeleteConfirmation = false
    @State private var predictionToDelete: SavedPrediction?
    
    var body: some View {
        NavigationView {
            Group {
                if persistenceService.savedPredictions.isEmpty {
                    emptyStateView
                        .onAppear {
                            print("📱 [DEBUG] SavedPredictionsView - No saved predictions found")
                        }
                } else {
                    predictionsList
                        .onAppear {
                            print("📱 [DEBUG] SavedPredictionsView - Found \(persistenceService.savedPredictions.count) predictions")
                        }
                }
            }
            .navigationTitle("Saved Predictions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !persistenceService.savedPredictions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Clear All", role: .destructive) {
                                persistenceService.clearAllPredictions()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedPrediction) { prediction in
            PredictionDetailView(prediction: prediction)
        }
        .alert("Edit Name", isPresented: $showingEditAlert) {
            TextField("Prediction Name", text: $editNickname)
            
            Button("Cancel", role: .cancel) {
                showingEditAlert = false
                editingPrediction = nil
                editNickname = ""
            }
            
            Button("Save") {
                if let prediction = editingPrediction {
                    persistenceService.updatePredictionNickname(
                        prediction.id,
                        nickname: editNickname
                    )
                }
                showingEditAlert = false
                editingPrediction = nil
                editNickname = ""
            }
        } message: {
            Text("Enter a new name for this prediction")
        }
        .alert("Delete Prediction", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                predictionToDelete = nil
            }
            
            Button("Delete", role: .destructive) {
                if let prediction = predictionToDelete {
                    persistenceService.deletePrediction(prediction)
                }
                predictionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this prediction? This action cannot be undone.")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Brand.Spacing.lg) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 48))
                .foregroundColor(Brand.ColorSystem.secondary)
            
            Text("No Saved Predictions")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Text("Generate and save your first IVF outcome prediction to see it here.")
                .font(.body)
                .foregroundColor(Brand.ColorSystem.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var predictionsList: some View {
        List {
            ForEach(persistenceService.savedPredictions) { prediction in
                PredictionRowView(
                    prediction: prediction,
                    onTap: {
                        selectedPrediction = prediction
                    },
                    onEdit: {
                        editingPrediction = prediction
                        editNickname = prediction.nickname ?? ""
                        showingEditAlert = true
                    },
                    onDelete: {
                        predictionToDelete = prediction
                        showingDeleteConfirmation = true
                    }
                )
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Prediction Row View
struct PredictionRowView: View {
    let prediction: SavedPrediction
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prediction.displayName)
                            .font(.headline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        Text(prediction.summaryText)
                            .font(.caption)
                            .foregroundColor(Brand.ColorSystem.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("Edit Name") {
                            onEdit()
                        }
                        
                        Button("Delete", role: .destructive) {
                            onDelete()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Brand.ColorSystem.secondary)
                    }
                }
                
                // Key Results Summary
                HStack(spacing: Brand.Spacing.md) {
                    ResultSummaryItem(
                        title: "Oocytes",
                        value: String(format: "%.0f", prediction.expectedOocytes)
                    )
                    
                    ResultSummaryItem(
                        title: "Blastocysts", 
                        value: String(format: "%.0f", prediction.expectedBlastocysts)
                    )
                    
                    ResultSummaryItem(
                        title: "Euploid",
                        value: String(format: "%.0f", prediction.expectedEuploidBlastocysts)
                    )
                    
                    Spacer()
                    
                    Text(prediction.confidenceLevel)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Brand.ColorSystem.primary.opacity(0.1))
                        )
                        .foregroundColor(Brand.ColorSystem.primary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Result Summary Item
struct ResultSummaryItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(Brand.ColorSystem.secondary)
        }
    }
}

// MARK: - Prediction Detail View
struct PredictionDetailView: View {
    let prediction: SavedPrediction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Brand.Spacing.lg) {
                    // Header Information
                    EnhancedContentBlock(
                        title: "Prediction Details",
                        icon: "info.circle"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            PredictionDetailRow(title: "Name", value: prediction.displayName)
                            PredictionDetailRow(title: "Created", value: formatDate(prediction.timestamp))
                            PredictionDetailRow(title: "Mode", value: prediction.calculationMode)
                            PredictionDetailRow(title: "Age", value: prediction.ageDisplay)
                            if let amhLevel = prediction.amhLevel, let amhUnit = prediction.amhUnit {
                                PredictionDetailRow(title: "AMH", value: "\(String(format: "%.1f", amhLevel)) \(amhUnit)")
                            }
                            if let estrogenLevel = prediction.estrogenLevel, let estrogenUnit = prediction.estrogenUnit {
                                PredictionDetailRow(title: "Estrogen", value: "\(String(format: "%.0f", estrogenLevel)) \(estrogenUnit)")
                            }
                            if let retrievedOocytes = prediction.retrievedOocytes {
                                PredictionDetailRow(title: "Retrieved Oocytes", value: "\(Int(retrievedOocytes))")
                            }
                            if let bmi = prediction.bmi {
                                PredictionDetailRow(title: "BMI", value: String(format: "%.1f", bmi))
                            }
                            PredictionDetailRow(title: "Diagnosis", value: prediction.diagnosisType)
                        }
                    }
                    
                    // Results Summary
                    EnhancedContentBlock(
                        title: "Predicted Outcomes",
                        icon: "chart.bar"
                    ) {
                        VStack(spacing: 12) {
                            ResultDetailRow(
                                title: "Expected Oocytes",
                                value: String(format: "%.1f", prediction.expectedOocytes)
                            )
                            
                            ResultDetailRow(
                                title: "Expected Blastocysts",
                                value: String(format: "%.1f", prediction.expectedBlastocysts)
                            )
                            
                            ResultDetailRow(
                                title: "Expected Euploid Blastocysts",
                                value: String(format: "%.1f", prediction.expectedEuploidBlastocysts)
                            )
                        }
                    }
                    
                    // Pathway Comparison
                    EnhancedContentBlock(
                        title: "Fertilization Pathways",
                        icon: "arrow.triangle.branch"
                    ) {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Conventional IVF")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(Brand.ColorSystem.primary)
                                    Text("\(String(format: "%.1f", prediction.ivfFertilizedEmbryos)) fertilized")
                                        .font(.caption)
                                        .foregroundColor(Brand.ColorSystem.secondary)
                                }
                                
                                Spacer()
                                
                                Text("vs")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Brand.ColorSystem.secondary)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("ICSI")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(Brand.ColorSystem.secondary)
                                    Text("\(String(format: "%.1f", prediction.icsiFertilizedEmbryos)) fertilized")
                                        .font(.caption)
                                        .foregroundColor(Brand.ColorSystem.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Prediction Detail")
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views
struct PredictionDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Brand.ColorSystem.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}

struct ResultDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(Brand.ColorSystem.primary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Brand.ColorSystem.primary.opacity(0.05))
        )
    }
}