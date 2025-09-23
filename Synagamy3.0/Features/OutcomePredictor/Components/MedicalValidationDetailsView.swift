//
//  MedicalValidationDetailsView.swift
//  Synagamy3.0
//
//  Detailed view showing medical validation results, warnings, and safety information
//

import SwiftUI

struct MedicalValidationDetailsView: View {
    let validation: EnhancedMedicalValidator.MedicalValidationResult?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let validation = validation {
                        // Confidence Section
                        confidenceSection(validation)

                        // Errors Section
                        if !validation.errors.isEmpty {
                            errorsSection(validation.errors)
                        }

                        // Warnings Section
                        if !validation.warnings.isEmpty {
                            warningsSection(validation.warnings)
                        }

                        // Safety Flags Section
                        if !validation.safetyFlags.isEmpty {
                            safetyFlagsSection(validation.safetyFlags)
                        }

                        // Clinical Recommendations
                        clinicalRecommendationsSection(validation)

                    } else {
                        EmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "No Validation Data",
                            message: "Unable to display validation details"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Validation Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func confidenceSection(_ validation: EnhancedMedicalValidator.MedicalValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Prediction Confidence", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(Brand.Color.primary)

            HStack {
                confidenceIndicator(validation.confidence)
                Spacer()
            }

            Text(validation.confidence.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Brand.Color.hairline, lineWidth: 1)
                )
        )
    }

    private func confidenceIndicator(_ confidence: EnhancedMedicalValidator.MedicalValidationResult.ClinicalConfidence) -> some View {
        HStack(spacing: 8) {
            Image(systemName: confidenceIcon(confidence))
                .foregroundColor(confidenceColor(confidence))

            Text(confidenceLabel(confidence))
                .font(.subheadline.weight(.medium))
                .foregroundColor(confidenceColor(confidence))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(confidenceColor(confidence).opacity(0.1))
        )
    }

    private func confidenceIcon(_ confidence: EnhancedMedicalValidator.MedicalValidationResult.ClinicalConfidence) -> String {
        switch confidence {
        case .high: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "exclamationmark.triangle.fill"
        case .insufficient: return "xmark.circle.fill"
        }
    }

    private func confidenceColor(_ confidence: EnhancedMedicalValidator.MedicalValidationResult.ClinicalConfidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        case .insufficient: return .red
        }
    }

    private func confidenceLabel(_ confidence: EnhancedMedicalValidator.MedicalValidationResult.ClinicalConfidence) -> String {
        switch confidence {
        case .high: return "High Confidence"
        case .medium: return "Medium Confidence"
        case .low: return "Low Confidence"
        case .insufficient: return "Insufficient Data"
        }
    }

    private func errorsSection(_ errors: [EnhancedMedicalValidator.MedicalError]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Validation Errors", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundColor(.red)

            ForEach(errors.indices, id: \.self) { index in
                let error = errors[index]
                errorRow(error)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func errorRow(_ error: EnhancedMedicalValidator.MedicalError) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(error.field.capitalized)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(error.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(error.severity.description)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            Spacer()
        }
    }

    private func warningsSection(_ warnings: [EnhancedMedicalValidator.MedicalWarning]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Clinical Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            ForEach(warnings.indices, id: \.self) { index in
                let warning = warnings[index]
                warningRow(warning)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func warningRow(_ warning: EnhancedMedicalValidator.MedicalWarning) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.field.capitalized)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(warning.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(warning.clinicalImpact.description)
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }

            Spacer()
        }
    }

    private func safetyFlagsSection(_ flags: [EnhancedMedicalValidator.SafetyFlag]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Safety Concerns", systemImage: "shield.fill")
                .font(.headline)
                .foregroundColor(.red)

            ForEach(flags.indices, id: \.self) { index in
                let flag = flags[index]
                safetyFlagRow(flag)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func safetyFlagRow(_ flag: EnhancedMedicalValidator.SafetyFlag) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.fill")
                .foregroundColor(.red)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(flag.type.description)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(flag.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    private func clinicalRecommendationsSection(_ validation: EnhancedMedicalValidator.MedicalValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Clinical Recommendations", systemImage: "stethoscope")
                .font(.headline)
                .foregroundColor(Brand.Color.primary)

            VStack(alignment: .leading, spacing: 8) {
                recommendationRow(
                    icon: "person.fill",
                    title: "Consult Healthcare Provider",
                    description: "Discuss these results with your fertility specialist for personalized interpretation"
                )

                if validation.confidence == .low || validation.confidence == .insufficient {
                    recommendationRow(
                        icon: "arrow.clockwise",
                        title: "Verify Input Values",
                        description: "Double-check your lab results and measurements for accuracy"
                    )
                }

                if !validation.safetyFlags.isEmpty {
                    recommendationRow(
                        icon: "exclamationmark.shield",
                        title: "Address Safety Concerns",
                        description: "Discuss the identified safety concerns with your medical team before proceeding"
                    )
                }

                recommendationRow(
                    icon: "info.circle",
                    title: "Educational Purpose Only",
                    description: "These predictions are for educational purposes and do not replace professional medical advice"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Brand.Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Brand.Color.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func recommendationRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Brand.Color.primary)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

#Preview {
    // Create sample validation result for preview
    let sampleValidation = EnhancedMedicalValidator.MedicalValidationResult(
        isValid: true,
        isSafe: false,
        validatedInputs: nil,
        errors: [
            EnhancedMedicalValidator.MedicalError(
                field: "age",
                message: "Age seems unusually high for fertility treatment",
                severity: .medium
            )
        ],
        warnings: [
            EnhancedMedicalValidator.MedicalWarning(
                field: "amh",
                message: "Low AMH suggests diminished ovarian reserve",
                clinicalImpact: .medium
            )
        ],
        confidence: .low,
        safetyFlags: [
            EnhancedMedicalValidator.SafetyFlag(
                type: .clinicalRisk,
                message: "High estradiol levels increase OHSS risk"
            )
        ]
    )

    MedicalValidationDetailsView(validation: sampleValidation)
}