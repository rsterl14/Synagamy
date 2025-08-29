//
//  ErrorDetailsView.swift
//  Synagamy3.0
//
//  Detailed error information view for troubleshooting.
//

import SwiftUI

struct ErrorDetailsView: View {
    let error: AppError
    @ObservedObject var errorHandler: AppErrorHandler
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Error Summary
                    errorSummarySection
                    
                    // Details
                    errorDetailsSection
                    
                    // Recent Errors
                    if !errorHandler.errorHistory.isEmpty {
                        recentErrorsSection
                    }
                    
                    // Help Section
                    helpSection
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Error Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Actions") {
                        Button("Copy Error Info") {
                            copyErrorToClipboard()
                        }
                        
                        Button("Clear History") {
                            errorHandler.clearHistory()
                        }
                        
                        if error.severity != .low {
                            Button("Report Issue") {
                                // Would integrate with feedback system
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Error Summary Section
    
    private var errorSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: error.severity.icon)
                    .font(.title2)
                    .foregroundColor(error.severity.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.userFriendlyTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(severityText)
                        .font(.caption.weight(.medium))
                        .foregroundColor(error.severity.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(error.severity.color.opacity(0.1))
                        )
                }
                
                Spacer()
            }
            
            if let description = error.errorDescription {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            if let recovery = error.recoverySuggestion {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Text("Suggested Solution")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                    }
                    
                    Text(recovery)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.05))
                        .stroke(.orange.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Error Details Section
    
    private var errorDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Technical Details")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Error Type", value: String(describing: error))
                DetailRow(title: "Severity", value: severityText)
                DetailRow(title: "Timestamp", value: Date().formatted(date: .abbreviated, time: .complete))
                
                if let currentRecord = errorHandler.errorHistory.first {
                    if let context = currentRecord.context {
                        DetailRow(title: "Context", value: context)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Recent Errors Section
    
    private var recentErrorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Errors")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(errorHandler.errorHistory.prefix(5))) { record in
                    ErrorHistoryRow(record: record)
                }
            }
            
            if errorHandler.errorHistory.count > 5 {
                Text("... and \(errorHandler.errorHistory.count - 5) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Need Help?")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HelpOption(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Restart the App",
                    description: "Close and reopen Synagamy to clear temporary issues"
                )
                
                HelpOption(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Reset App Data",
                    description: "Clear all stored data and start fresh (will lose saved cycles)"
                )
                
                HelpOption(
                    icon: "questionmark.circle.fill",
                    title: "Contact Support",
                    description: "Report persistent issues to our development team"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Computed Properties
    
    private var severityText: String {
        switch error.severity {
        case .low: return "Low Impact"
        case .medium: return "Medium Impact"
        case .high: return "High Impact"
        case .critical: return "Critical"
        }
    }
    
    // MARK: - Actions
    
    private func copyErrorToClipboard() {
        let errorInfo = """
        Synagamy Error Report
        ==================
        
        Error: \(error.userFriendlyTitle)
        Type: \(String(describing: error))
        Severity: \(severityText)
        Description: \(error.errorDescription ?? "Unknown")
        Recovery: \(error.recoverySuggestion ?? "None")
        Timestamp: \(Date().formatted(date: .abbreviated, time: .complete))
        
        Recent Errors:
        \(errorHandler.errorHistory.prefix(3).map { "- \($0.error.userFriendlyTitle) at \($0.formattedTimestamp)" }.joined(separator: "\n"))
        
        App Version: 1.0
        Device: iOS \(UIDevice.current.systemVersion)
        """
        
        UIPasteboard.general.string = errorInfo
        
        // Show confirmation
        withAnimation {
            // Could show a brief success message
        }
    }
}

// MARK: - Supporting Views

private struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

private struct ErrorHistoryRow: View {
    let record: AppErrorHandler.ErrorRecord
    
    var body: some View {
        HStack {
            Image(systemName: record.error.severity.icon)
                .font(.caption)
                .foregroundColor(record.error.severity.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.error.userFriendlyTitle)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(record.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct HelpOption: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ErrorDetailsView(
        error: .calculationFailed("Invalid AMH value"),
        errorHandler: AppErrorHandler()
    )
}