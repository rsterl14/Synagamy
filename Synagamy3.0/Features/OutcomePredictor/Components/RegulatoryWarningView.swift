//
//  RegulatoryWarningView.swift
//  Synagamy3.0
//
//  Regulatory compliance warnings for medical device risk mitigation
//  Prevents FDA/Health Canada classification as medical device
//

import SwiftUI

/// Prominent regulatory warning component for prediction results
struct RegulatoryWarningView: View {
    let severity: WarningSeverity
    let context: WarningContext

    enum WarningSeverity {
        case critical    // Red background, high visibility
        case high        // Orange background, prominent
        case standard    // Blue background, informational

        var backgroundColor: Color {
            switch self {
            case .critical: return .red.opacity(0.1)
            case .high: return .orange.opacity(0.1)
            case .standard: return .blue.opacity(0.05)
            }
        }

        var borderColor: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .standard: return .blue
            }
        }

        var iconColor: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .standard: return .blue
            }
        }
    }

    enum WarningContext {
        case predictionResults
        case savedPredictions
        case educationalContent
        case dataEntry

        var icon: String {
            switch self {
            case .predictionResults: return "exclamationmark.triangle.fill"
            case .savedPredictions: return "info.circle.fill"
            case .educationalContent: return "book.circle.fill"
            case .dataEntry: return "shield.fill"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 8) {
                Image(systemName: context.icon)
                    .font(.title3.weight(.bold))
                    .foregroundColor(severity.iconColor)

                Text(warningTitle)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)

                Spacer()
            }

            // Main warning content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(warningMessages, id: \.self) { message in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body.weight(.bold))
                            .foregroundColor(severity.iconColor)

                        Text(message)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                }
            }

            // Regulatory compliance statement
            if severity == .critical {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.caption.weight(.bold))
                        .foregroundColor(severity.iconColor)

                    Text("This application is not regulated as a medical device by FDA or Health Canada")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(severity.backgroundColor)
                .stroke(severity.borderColor, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Important medical warning: \(warningMessages.joined(separator: ". "))")
    }

    private var warningTitle: String {
        switch (severity, context) {
        case (.critical, .predictionResults):
            return "NOT FOR MEDICAL DECISIONS"
        case (.high, .predictionResults):
            return "Educational Tool Only"
        case (.critical, _):
            return "IMPORTANT MEDICAL WARNING"
        case (.high, _):
            return "Medical Disclaimer"
        case (.standard, _):
            return "Educational Information"
        }
    }

    private var warningMessages: [String] {
        switch context {
        case .predictionResults:
            return [
                "These predictions are for educational purposes only and must not be used for medical decision making",
                "Results are based on population averages and may not reflect your individual situation",
                "Always consult with qualified fertility specialists for personalized medical advice",
                "This tool does not diagnose, treat, or replace professional medical consultation"
            ]
        case .savedPredictions:
            return [
                "Saved predictions are educational estimates only",
                "Do not use these results to make treatment decisions",
                "Consult healthcare professionals for medical guidance"
            ]
        case .educationalContent:
            return [
                "Content is for educational purposes only",
                "Always verify information with healthcare professionals",
                "Individual medical situations vary significantly"
            ]
        case .dataEntry:
            return [
                "Enter data for educational exploration only",
                "This tool does not provide medical advice or diagnosis",
                "Consult fertility specialists for medical evaluation"
            ]
        }
    }
}

/// Compact regulatory warning for smaller spaces
struct CompactRegulatoryWarning: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
                .foregroundColor(.red)

            Text("NOT FOR MEDICAL DECISIONS")
                .font(.caption.weight(.bold))
                .foregroundColor(.red)

            Text("• Educational only • Consult healthcare professionals")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.red.opacity(0.05))
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Regulatory disclaimer modal for first-time use
struct RegulatoryDisclaimerModal: View {
    @Binding var isPresented: Bool
    @AppStorage("hasSeenRegulatoryDisclaimer") private var hasSeenDisclaimer = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title section
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)

                        Text("Regulatory Notice")
                            .font(.title.weight(.bold))

                        Text("Important information about this educational tool")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)

                    // Warning sections
                    VStack(spacing: 16) {
                        RegulatoryWarningView(severity: .critical, context: .predictionResults)

                        // FDA/Health Canada specific notice
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.blue)
                                Text("Regulatory Compliance")
                                    .font(.headline.weight(.semibold))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("🇺🇸 FDA Notice: This software is not intended for use in the diagnosis of disease or other conditions, or in the cure, mitigation, treatment, or prevention of disease.")
                                    .font(.caption)
                                    .padding(.horizontal)

                                Text("🇨🇦 Health Canada Notice: This application is not a medical device and has not been evaluated by Health Canada for safety or effectiveness.")
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.opacity(0.05))
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )

                        // User acknowledgment
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By continuing, you acknowledge:")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 6) {
                                AcknowledgmentRow(text: "This is an educational tool only")
                                AcknowledgmentRow(text: "Results are not medical advice")
                                AcknowledgmentRow(text: "You will consult healthcare professionals for medical decisions")
                                AcknowledgmentRow(text: "You understand the regulatory status of this application")
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.green.opacity(0.05))
                                .stroke(.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Important Notice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("I Understand") {
                        hasSeenDisclaimer = true
                        isPresented = false
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.blue)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

struct AcknowledgmentRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview("Critical Warning") {
    RegulatoryWarningView(severity: .critical, context: .predictionResults)
        .padding()
}

#Preview("Compact Warning") {
    CompactRegulatoryWarning()
        .padding()
}

#Preview("Disclaimer Modal") {
    RegulatoryDisclaimerModal(isPresented: .constant(true))
}