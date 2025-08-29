//
//  AppErrorHandler.swift
//  Synagamy3.0
//
//  Centralized error handling and user-friendly error messaging.
//

import SwiftUI
import os.log

// MARK: - App Error Types

enum AppError: LocalizedError, Equatable {
    case dataLoadingFailed(String)
    case validationFailed(String)
    case calculationFailed(String)
    case exportFailed(String)
    case networkUnavailable
    case invalidInput(String)
    case fileSystemError(String)
    case unexpectedError(String)
    
    var errorDescription: String? {
        switch self {
        case .dataLoadingFailed(let details):
            return "Failed to load data: \(details)"
        case .validationFailed(let details):
            return "Validation error: \(details)"
        case .calculationFailed(let details):
            return "Calculation error: \(details)"
        case .exportFailed(let details):
            return "Export failed: \(details)"
        case .networkUnavailable:
            return "Network unavailable"
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .fileSystemError(let details):
            return "File system error: \(details)"
        case .unexpectedError(let details):
            return "Unexpected error: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataLoadingFailed:
            return "Please restart the app or check your internet connection."
        case .validationFailed, .invalidInput:
            return "Please check your input values and try again."
        case .calculationFailed:
            return "Please verify your input values are within normal ranges."
        case .exportFailed:
            return "Please try exporting again or free up device storage."
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .fileSystemError:
            return "Please free up device storage and try again."
        case .unexpectedError:
            return "Please restart the app. If the problem persists, contact support."
        }
    }
    
    var userFriendlyTitle: String {
        switch self {
        case .dataLoadingFailed:
            return "Loading Problem"
        case .validationFailed, .invalidInput:
            return "Input Error"
        case .calculationFailed:
            return "Calculation Problem"
        case .exportFailed:
            return "Export Problem"
        case .networkUnavailable:
            return "No Internet"
        case .fileSystemError:
            return "Storage Problem"
        case .unexpectedError:
            return "Something Went Wrong"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .dataLoadingFailed, .networkUnavailable, .fileSystemError:
            return .high
        case .validationFailed, .invalidInput, .calculationFailed:
            return .medium
        case .exportFailed:
            return .low
        case .unexpectedError:
            return .critical
        }
    }
}

// ErrorSeverity enum is now defined in ErrorHandler.swift to avoid duplication

// MARK: - Error Handler

@MainActor
class AppErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorRecord] = []
    @Published var showingErrorAlert = false
    @Published var showingErrorDetails = false
    
    private let logger = Logger(subsystem: "com.synagamy.app", category: "ErrorHandler")
    private let maxHistorySize = 50
    
    struct ErrorRecord: Identifiable {
        let id = UUID()
        let error: AppError
        let timestamp: Date
        let context: String?
        
        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter.string(from: timestamp)
        }
    }
    
    // MARK: - Public Methods
    
    func handle(_ error: AppError, context: String? = nil, showAlert: Bool = true) {
        logger.error("\(error.errorDescription ?? "Unknown error") - Context: \(context ?? "None")")
        
        let record = ErrorRecord(error: error, timestamp: Date(), context: context)
        
        currentError = error
        errorHistory.insert(record, at: 0)
        
        // Limit history size
        if errorHistory.count > maxHistorySize {
            errorHistory = Array(errorHistory.prefix(maxHistorySize))
        }
        
        if showAlert {
            showingErrorAlert = true
        }
        
        // Auto-dismiss low severity errors
        if error.severity == .low {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.currentError == error {
                    self.currentError = nil
                    self.showingErrorAlert = false
                }
            }
        }
    }
    
    func handle(_ error: Error, context: String? = nil, showAlert: Bool = true) {
        let appError: AppError
        
        if let appErr = error as? AppError {
            appError = appErr
        } else {
            appError = .unexpectedError(error.localizedDescription)
        }
        
        handle(appError, context: context, showAlert: showAlert)
    }
    
    func clearCurrentError() {
        currentError = nil
        showingErrorAlert = false
        showingErrorDetails = false
    }
    
    func clearHistory() {
        errorHistory.removeAll()
    }
    
    func retryLastAction() {
        // Override in specific implementations
        clearCurrentError()
    }
    
    // MARK: - Validation Helpers
    
    func validateAge(_ age: String) -> Result<Double, AppError> {
        guard let ageValue = Double(age) else {
            return .failure(.invalidInput("Age must be a valid number"))
        }
        
        guard ageValue >= 18 && ageValue <= 50 else {
            return .failure(.validationFailed("Age must be between 18 and 50 years"))
        }
        
        return .success(ageValue)
    }
    
    func validateAMH(_ amh: String, unit: AMHUnit) -> Result<Double, AppError> {
        guard let amhValue = Double(amh) else {
            return .failure(.invalidInput("AMH must be a valid number"))
        }
        
        let amhInNgML = amhValue * unit.toNgPerMLFactor
        
        guard amhInNgML >= 0.01 && amhInNgML <= 50 else {
            let unitText = unit.displayName
            let minValue = unit == .ngPerML ? "0.01" : String(format: "%.1f", 0.01 / unit.toNgPerMLFactor)
            let maxValue = unit == .ngPerML ? "50" : String(format: "%.0f", 50 / unit.toNgPerMLFactor)
            return .failure(.validationFailed("AMH must be between \(minValue) and \(maxValue) \(unitText)"))
        }
        
        return .success(amhValue)
    }
    
    func validateEstrogen(_ estrogen: String, unit: EstrogenUnit) -> Result<Double, AppError> {
        guard let estrogenValue = Double(estrogen) else {
            return .failure(.invalidInput("Estradiol must be a valid number"))
        }
        
        let estrogenInPgML = estrogenValue * unit.toPgPerMLFactor
        
        guard estrogenInPgML >= 100 && estrogenInPgML <= 10000 else {
            let unitText = unit.displayName
            let minValue = unit == .pgPerML ? "100" : String(format: "%.0f", 100 / unit.toPgPerMLFactor)
            let maxValue = unit == .pgPerML ? "10000" : String(format: "%.0f", 10000 / unit.toPgPerMLFactor)
            return .failure(.validationFailed("Estradiol must be between \(minValue) and \(maxValue) \(unitText)"))
        }
        
        return .success(estrogenValue)
    }
    
    func validateOocyteCount(_ oocytes: String) -> Result<Double, AppError> {
        guard let oocyteValue = Double(oocytes) else {
            return .failure(.invalidInput("Oocyte count must be a valid number"))
        }
        
        guard oocyteValue >= 1 && oocyteValue <= 50 else {
            return .failure(.validationFailed("Oocyte count must be between 1 and 50"))
        }
        
        return .success(oocyteValue)
    }
}

// MARK: - Error Recovery Strategies
// ErrorRecoveryAction enum is now defined in ErrorHandler.swift to avoid duplication

extension AppErrorHandler {
    func getRecoveryActions(for error: AppError) -> [ErrorRecoveryAction] {
        switch error {
        case .dataLoadingFailed:
            return [.retry]
            
        case .calculationFailed:
            return [.restart]
            
        case .exportFailed:
            return [.retry]
            
        default:
            return [.none]
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let retryDataLoad = Notification.Name("retryDataLoad")
    static let switchToOfflineMode = Notification.Name("switchToOfflineMode")
    static let resetInputs = Notification.Name("resetInputs")
    static let useDefaultValues = Notification.Name("useDefaultValues")
    static let retryExport = Notification.Name("retryExport")
    static let shareAsText = Notification.Name("shareAsText")
}

// MARK: - Error Display Components

// ErrorAlertModifier is now defined in ErrorHandler.swift to avoid duplication

extension View {
    func errorHandling(_ errorHandler: AppErrorHandler) -> some View {
        // Use the ErrorAlertModifier from ErrorHandler.swift
        self.alert(
            errorHandler.currentError?.userFriendlyTitle ?? "Error",
            isPresented: .constant(errorHandler.showingErrorAlert)
        ) {
            Button("OK") {
                errorHandler.clearCurrentError()
            }
        } message: {
            if let error = errorHandler.currentError {
                Text(error.errorDescription ?? "An error occurred")
            }
        }
    }
}