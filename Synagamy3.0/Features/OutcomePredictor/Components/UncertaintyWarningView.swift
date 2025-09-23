//
//  UncertaintyWarningView.swift
//  Synagamy3.0
//
//  Emphasizes prediction uncertainty and individual variation
//  Critical for regulatory compliance and avoiding medical device classification
//

import SwiftUI

/// Component that prominently displays prediction uncertainty and individual variation warnings
struct UncertaintyWarningView: View {
    let predictionType: PredictionType
    let confidenceLevel: String

    enum PredictionType {
        case oocytes
        case fertilization
        case blastocysts
        case euploidBlastocysts

        var uncertaintyFactors: [String] {
            switch self {
            case .oocytes:
                return [
                    "Individual ovarian response varies significantly",
                    "Stimulation protocol and dosing affect outcomes",
                    "Lab quality and techniques impact retrieval success",
                    "Underlying medical conditions influence response"
                ]
            case .fertilization:
                return [
                    "Sperm quality affects fertilization rates",
                    "Egg quality varies between individuals",
                    "Laboratory procedures and timing impact success",
                    "Fertilization method (IVF vs ICSI) influences outcomes"
                ]
            case .blastocysts:
                return [
                    "Embryo development is highly individual",
                    "Laboratory culture conditions affect growth",
                    "Genetic factors influence embryo quality",
                    "Timing of development varies significantly"
                ]
            case .euploidBlastocysts:
                return [
                    "Chromosomal abnormalities increase with age",
                    "Genetic testing accuracy is not 100%",
                    "Mosaicism can affect test results",
                    "Individual genetic factors play a major role"
                ]
            }
        }

        var title: String {
            switch self {
            case .oocytes: return "Oocyte Retrieval Uncertainty"
            case .fertilization: return "Fertilization Rate Uncertainty"
            case .blastocysts: return "Blastocyst Development Uncertainty"
            case .euploidBlastocysts: return "Genetic Testing Uncertainty"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)

                Text(predictionType.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(confidenceLevel)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.orange.opacity(0.1))
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(.orange)
            }

            // Population average warning
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.caption)

                Text("Based on population averages - your individual results may vary significantly")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.blue.opacity(0.05))
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )

            // Uncertainty factors
            Text("Factors affecting individual outcomes:")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(predictionType.uncertaintyFactors, id: \.self) { factor in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(factor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.orange.opacity(0.02))
                .stroke(.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Compact uncertainty badge for smaller spaces
struct UncertaintyBadge: View {
    let text: String
    let level: UncertaintyLevel

    enum UncertaintyLevel {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .yellow
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "questionmark.circle.fill")
                .font(.caption2)
                .foregroundColor(level.color)

            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundColor(level.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(level.color.opacity(0.1))
                .stroke(level.color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Range display component that emphasizes uncertainty
struct UncertaintyRangeView: View {
    let predictedValue: Double
    let range: ClosedRange<Double>
    let unit: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(predictedValue))")
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)

                    Text("Population Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(range.lowerBound)) - \(Int(range.upperBound))")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.orange)

                    Text("Expected Range")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // Visual range indicator
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Possible Range")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("80% of patients fall within this range")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.gray.opacity(0.2))
                            .frame(height: 4)

                        // Range indicator
                        let totalRange = range.upperBound - range.lowerBound
                        let width = geometry.size.width * 0.8 // 80% confidence interval

                        RoundedRectangle(cornerRadius: 2)
                            .fill(.orange)
                            .frame(width: width, height: 4)
                            .offset(x: geometry.size.width * 0.1) // Center the range

                        // Prediction indicator
                        let predictionPosition = geometry.size.width * 0.5 // Center for population average
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .offset(x: predictionPosition - 4)
                    }
                }
                .frame(height: 8)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.05))
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview("Oocyte Uncertainty") {
    UncertaintyWarningView(predictionType: .oocytes, confidenceLevel: "Medium")
        .padding()
}

#Preview("Uncertainty Range") {
    UncertaintyRangeView(
        predictedValue: 12.5,
        range: 8...17,
        unit: "oocytes",
        description: "Individual outcomes vary based on multiple medical and biological factors"
    )
    .padding()
}

#Preview("Uncertainty Badge") {
    HStack {
        UncertaintyBadge(text: "High Uncertainty", level: .high)
        UncertaintyBadge(text: "Medium Uncertainty", level: .medium)
        UncertaintyBadge(text: "Low Uncertainty", level: .low)
    }
    .padding()
}