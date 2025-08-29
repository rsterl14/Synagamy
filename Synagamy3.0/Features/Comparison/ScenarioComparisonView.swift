//
//  ScenarioComparisonView.swift
//  Synagamy3.0
//
//  Compare multiple prediction scenarios side by side.
//

import SwiftUI

struct ScenarioComparisonView: View {
    @StateObject private var comparisonManager = ScenarioComparisonManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if comparisonManager.scenarios.isEmpty {
                    emptyStateView
                } else {
                    comparisonContentView
                }
            }
            .navigationTitle("Compare Scenarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Actions") {
                        Button("Add Scenario") {
                            // Add new scenario
                        }
                        
                        if !comparisonManager.scenarios.isEmpty {
                            Button("Clear All") {
                                comparisonManager.clearAll()
                            }
                            
                            Button("Export Comparison") {
                                // Export comparison as PDF
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Scenarios to Compare")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text("Add prediction scenarios to compare different parameters and see how they affect your outcomes.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add First Scenario") {
                // Add scenario action
            }
            .font(.headline.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Brand.ColorSystem.primary)
            )
        }
        .padding(40)
    }
    
    // MARK: - Comparison Content
    
    private var comparisonContentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Metrics comparison
                comparisonMetricsView
                
                // Individual scenarios
                ForEach(comparisonManager.scenarios) { scenario in
                    ScenarioCard(scenario: scenario) {
                        comparisonManager.removeScenario(scenario)
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var comparisonMetricsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison Overview")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ComparisonMetric.allCases, id: \.self) { metric in
                        MetricComparisonCard(
                            metric: metric,
                            scenarios: comparisonManager.scenarios
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Supporting Types

class ScenarioComparisonManager: ObservableObject {
    @Published var scenarios: [PredictionScenario] = []
    
    func addScenario(_ scenario: PredictionScenario) {
        scenarios.append(scenario)
    }
    
    func removeScenario(_ scenario: PredictionScenario) {
        scenarios.removeAll { $0.id == scenario.id }
    }
    
    func clearAll() {
        scenarios.removeAll()
    }
}

struct PredictionScenario: Identifiable {
    let id = UUID()
    let name: String
    let age: Double
    let amhLevel: Double
    let estrogenLevel: Double
    let diagnosis: IVFOutcomePredictor.PredictionInputs.DiagnosisType
    let results: IVFOutcomePredictor.PredictionResults
    let createdAt: Date
}

enum ComparisonMetric: String, CaseIterable {
    case oocytes = "Oocytes"
    case fertilized = "Fertilized"
    case blastocysts = "Blastocysts"
    case euploid = "Euploid"
    
    func value(from results: IVFOutcomePredictor.PredictionResults) -> Double {
        switch self {
        case .oocytes:
            return results.expectedOocytes.predicted
        case .fertilized:
            return results.expectedFertilization.icsi.predicted
        case .blastocysts:
            return results.expectedBlastocysts.predicted
        case .euploid:
            return results.euploidyRates.expectedEuploidBlastocysts
        }
    }
}

// MARK: - Supporting Views

private struct ScenarioCard: View {
    let scenario: PredictionScenario
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Created \(scenario.createdAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            // Scenario parameters
            VStack(alignment: .leading, spacing: 8) {
                ParameterRow(label: "Age", value: "\(Int(scenario.age)) years")
                ParameterRow(label: "AMH", value: String(format: "%.1f ng/mL", scenario.amhLevel))
                ParameterRow(label: "Estradiol", value: String(format: "%.0f pg/mL", scenario.estrogenLevel))
                ParameterRow(label: "Diagnosis", value: scenario.diagnosis.rawValue)
            }
            
            Divider()
            
            // Quick results
            HStack {
                QuickResultView(
                    title: "Oocytes",
                    value: String(format: "%.1f", scenario.results.expectedOocytes.predicted),
                    color: .blue
                )
                
                QuickResultView(
                    title: "Blastocysts",
                    value: String(format: "%.1f", scenario.results.expectedBlastocysts.predicted),
                    color: .green
                )
                
                QuickResultView(
                    title: "Euploid",
                    value: String(format: "%.1f", scenario.results.euploidyRates.expectedEuploidBlastocysts),
                    color: .purple
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .stroke(.separator, lineWidth: 0.5)
        )
    }
}

private struct ParameterRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}

private struct QuickResultView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MetricComparisonCard: View {
    let metric: ComparisonMetric
    let scenarios: [PredictionScenario]
    
    var body: some View {
        VStack(spacing: 12) {
            Text(metric.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 6) {
                ForEach(scenarios.indices, id: \.self) { index in
                    let scenario = scenarios[index]
                    let value = metric.value(from: scenario.results)
                    
                    HStack {
                        Circle()
                            .fill(colorForIndex(index))
                            .frame(width: 8, height: 8)
                        
                        Text(scenario.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", value))
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red]
        return colors[index % colors.count]
    }
}

#Preview {
    ScenarioComparisonView()
}