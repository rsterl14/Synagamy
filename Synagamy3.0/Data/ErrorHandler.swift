//
//  ErrorHandler.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  Centralized error handling system for the Synagamy app. Provides consistent
//  error management, user-friendly messaging, recovery mechanisms, and debugging
//  support throughout the application.
//
//  Features
//  --------
//  • Categorized error types for different domains (data, network, UI, etc.)
//  • User-friendly error messages that avoid technical jargon
//  • Automatic error recovery suggestions and actions
//  • Debug logging for development and troubleshooting
//  • App Store compliant error presentation for medical content
//
//  Error Categories
//  ---------------
//  • DataError: JSON loading, parsing, validation issues
//  • NetworkError: URL loading, connectivity, external resource problems
//  • UIError: Interface state issues, navigation problems
//  • ContentError: Missing or invalid educational content
//  • SystemError: Device-level issues, permissions, storage
//

import Foundation
import SwiftUI
import os.log

// MARK: - App Error Types

/// Primary error categories used throughout the Synagamy app
enum SynagamyError: LocalizedError, Equatable, Hashable {
    
    // MARK: Data Errors
    case dataLoadFailed(resource: String, underlying: Error?)
    case dataCorrupted(resource: String, details: String?)
    case dataValidationFailed(resource: String, issues: [String])
    case dataMissing(resource: String)
    
    // MARK: Network Errors
    case networkUnavailable
    case urlInvalid(url: String)
    case resourceNotFound(url: String)
    case requestTimeout(url: String)
    
    // MARK: Content Errors
    case contentEmpty(section: String)
    case contentMalformed(item: String, details: String?)
    case searchNoResults(query: String)
    case topicNotFound(topicId: String)
    
    // MARK: UI Errors
    case navigationFailed(destination: String)
    case stateInconsistent(view: String, details: String?)
    case assetMissing(assetName: String)
    case displayFailed(component: String)
    
    // MARK: System Errors
    case permissionDenied(permission: String)
    case storageUnavailable
    case deviceCapabilityMissing(capability: String)
    case criticalSystemError(details: String)
    
    // MARK: LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        // Data Errors
        case .dataLoadFailed(let resource, _):
            return "Failed to load \(resource) data"
        case .dataCorrupted(let resource, _):
            return "\(resource) data appears to be corrupted"
        case .dataValidationFailed(let resource, _):
            return "\(resource) data validation failed"
        case .dataMissing(let resource):
            return "Required \(resource) data is missing"
            
        // Network Errors
        case .networkUnavailable:
            return "Network connection unavailable"
        case .urlInvalid(let url):
            return "Invalid URL: \(url)"
        case .resourceNotFound(let url):
            return "Resource not found: \(url)"
        case .requestTimeout(let url):
            return "Request timed out: \(url)"
            
        // Content Errors
        case .contentEmpty(let section):
            return "No content available in \(section)"
        case .contentMalformed(let item, _):
            return "Content format error in \(item)"
        case .searchNoResults(let query):
            return "No results found for '\(query)'"
        case .topicNotFound(let topicId):
            return "Topic '\(topicId)' not found"
            
        // UI Errors
        case .navigationFailed(let destination):
            return "Cannot navigate to \(destination)"
        case .stateInconsistent(let view, _):
            return "\(view) is in an inconsistent state"
        case .assetMissing(let assetName):
            return "Missing asset: \(assetName)"
        case .displayFailed(let component):
            return "\(component) failed to display"
            
        // System Errors
        case .permissionDenied(let permission):
            return "\(permission) permission denied"
        case .storageUnavailable:
            return "Device storage unavailable"
        case .deviceCapabilityMissing(let capability):
            return "Device missing required \(capability)"
        case .criticalSystemError(let details):
            return "Critical system error: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        // Data Errors
        case .dataLoadFailed, .dataCorrupted, .dataMissing:
            return "Try restarting the app. If the problem persists, please reinstall the app."
        case .dataValidationFailed:
            return "Some content may not display correctly. Try updating the app."
            
        // Network Errors
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .urlInvalid, .resourceNotFound:
            return "This link may be outdated. Try visiting the website directly."
        case .requestTimeout:
            return "Check your internet connection and try again."
            
        // Content Errors
        case .contentEmpty:
            return "Content may be loading. Try refreshing or check back later."
        case .contentMalformed:
            return "This content may not display correctly. Try updating the app."
        case .searchNoResults:
            return "Try different search terms or browse by category."
        case .topicNotFound:
            return "This topic may have been moved. Try browsing the Education section."
            
        // UI Errors
        case .navigationFailed:
            return "Try using the Home button or restarting the app."
        case .stateInconsistent:
            return "Try going back and trying again."
        case .assetMissing:
            return "Some images may not display. Try updating the app."
        case .displayFailed:
            return "Try scrolling or rotating your device."
            
        // System Errors
        case .permissionDenied:
            return "Check app permissions in Settings."
        case .storageUnavailable:
            return "Free up device storage space."
        case .deviceCapabilityMissing:
            return "This feature requires a newer device or iOS version."
        case .criticalSystemError:
            return "Please restart the app. Contact support if this continues."
        }
    }
    
    // MARK: User-Friendly Messages
    
    /// Returns a user-friendly message suitable for display in alerts
    var userFriendlyMessage: String {
        switch self {
        // Data Errors
        case .dataLoadFailed, .dataCorrupted, .dataMissing:
            return "Some content isn't available right now. You can still browse other sections."
        case .dataValidationFailed:
            return "Some content may not display perfectly, but the app is still usable."
            
        // Network Errors
        case .networkUnavailable:
            return "You're not connected to the internet. Some features may not work."
        case .urlInvalid, .resourceNotFound:
            return "We couldn't open this link. You can try visiting the website directly."
        case .requestTimeout:
            return "The connection is slow. Please try again."
            
        // Content Errors
        case .contentEmpty:
            return "This section is empty right now. Try checking other sections."
        case .contentMalformed:
            return "This content isn't displaying correctly, but other sections should work fine."
        case .searchNoResults:
            return "No results found. Try different search terms or browse by category."
        case .topicNotFound:
            return "We couldn't find that topic. Try browsing the Education section."
            
        // UI Errors
        case .navigationFailed:
            return "We couldn't open that section. Try using the Home button."
        case .stateInconsistent, .displayFailed:
            return "Something went wrong with the display. Try going back and trying again."
        case .assetMissing:
            return "Some images aren't showing. The content is still available to read."
            
        // System Errors
        case .permissionDenied:
            return "The app needs permission to work properly. Check your device settings."
        case .storageUnavailable:
            return "Your device is low on storage. Some features may not work."
        case .deviceCapabilityMissing:
            return "This feature isn't available on your device."
        case .criticalSystemError:
            return "Something went wrong. Please restart the app."
        }
    }
    
    // MARK: Error Severity
    
    var severity: ErrorSeverity {
        switch self {
        case .criticalSystemError:
            return .critical
        case .dataLoadFailed, .dataMissing:
            return .high
        case .dataCorrupted, .dataValidationFailed, .networkUnavailable, .permissionDenied, .storageUnavailable, .navigationFailed, .stateInconsistent:
            return .medium
        case .contentEmpty, .searchNoResults, .topicNotFound, .assetMissing, .urlInvalid, .resourceNotFound, .requestTimeout, .contentMalformed, .displayFailed, .deviceCapabilityMissing:
            return .low
        }
    }
    
    // MARK: Equatable Implementation
    
    static func == (lhs: SynagamyError, rhs: SynagamyError) -> Bool {
        switch (lhs, rhs) {
        case (.dataLoadFailed(let lResource, _), .dataLoadFailed(let rResource, _)):
            return lResource == rResource
        case (.dataCorrupted(let lResource, _), .dataCorrupted(let rResource, _)):
            return lResource == rResource
        case (.urlInvalid(let lUrl), .urlInvalid(let rUrl)):
            return lUrl == rUrl
        case (.contentEmpty(let lSection), .contentEmpty(let rSection)):
            return lSection == rSection
        case (.networkUnavailable, .networkUnavailable),
             (.storageUnavailable, .storageUnavailable):
            return true
        default:
            return false
        }
    }
    
    // MARK: Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .dataLoadFailed(let resource, _):
            hasher.combine("dataLoadFailed")
            hasher.combine(resource)
        case .dataCorrupted(let resource, _):
            hasher.combine("dataCorrupted")
            hasher.combine(resource)
        case .dataValidationFailed(let resource, _):
            hasher.combine("dataValidationFailed")
            hasher.combine(resource)
        case .dataMissing(let resource):
            hasher.combine("dataMissing")
            hasher.combine(resource)
        case .networkUnavailable:
            hasher.combine("networkUnavailable")
        case .urlInvalid(let url):
            hasher.combine("urlInvalid")
            hasher.combine(url)
        case .resourceNotFound(let url):
            hasher.combine("resourceNotFound")
            hasher.combine(url)
        case .requestTimeout(let url):
            hasher.combine("requestTimeout")
            hasher.combine(url)
        case .contentEmpty(let section):
            hasher.combine("contentEmpty")
            hasher.combine(section)
        case .contentMalformed(let item, _):
            hasher.combine("contentMalformed")
            hasher.combine(item)
        case .searchNoResults(let query):
            hasher.combine("searchNoResults")
            hasher.combine(query)
        case .topicNotFound(let topicId):
            hasher.combine("topicNotFound")
            hasher.combine(topicId)
        case .navigationFailed(let destination):
            hasher.combine("navigationFailed")
            hasher.combine(destination)
        case .stateInconsistent(let view, _):
            hasher.combine("stateInconsistent")
            hasher.combine(view)
        case .assetMissing(let assetName):
            hasher.combine("assetMissing")
            hasher.combine(assetName)
        case .displayFailed(let component):
            hasher.combine("displayFailed")
            hasher.combine(component)
        case .permissionDenied(let permission):
            hasher.combine("permissionDenied")
            hasher.combine(permission)
        case .storageUnavailable:
            hasher.combine("storageUnavailable")
        case .deviceCapabilityMissing(let capability):
            hasher.combine("deviceCapabilityMissing")
            hasher.combine(capability)
        case .criticalSystemError(let details):
            hasher.combine("criticalSystemError")
            hasher.combine(details)
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Error Recovery Actions

enum ErrorRecoveryAction {
    case retry
    case refresh
    case navigateHome
    case restart
    case contactSupport
    case none
    
    var title: String {
        switch self {
        case .retry: return "Try Again"
        case .refresh: return "Refresh"
        case .navigateHome: return "Go Home"
        case .restart: return "Restart App"
        case .contactSupport: return "Get Help"
        case .none: return "OK"
        }
    }
}

// MARK: - Error Handler

final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published private(set) var currentError: SynagamyError?
    @Published var isErrorPresented = false
    @Published private(set) var shouldAttemptAutoRecovery = true
    
    private let logger = Logger(subsystem: "com.synagamy.app", category: "ErrorHandler")
    @MainActor
    private var recoveryManager: ErrorRecoveryManager {
        ErrorRecoveryManager.shared
    }
    
    // Error tracking for analytics and debugging
    private var errorHistory: [ErrorHistoryEntry] = []
    private let maxHistorySize = 100
    
    private init() {}
    
    // MARK: Error Presentation
    
    @MainActor
    func handle(_ error: SynagamyError) {
        logError(error)
        trackError(error)
        
        // Attempt automatic recovery for certain error types
        if shouldAttemptAutoRecovery && canAutoRecover(error) {
            attemptAutoRecovery(error)
        } else {
            presentError(error)
        }
    }
    
    @MainActor 
    func handleSilently(_ error: SynagamyError) {
        logError(error)
        trackError(error)
        // Don't present to user, just log and track
    }
    
    @MainActor
    private func presentError(_ error: SynagamyError) {
        currentError = error
        isErrorPresented = true
    }
    
    func handleError(_ error: Error, context: String = "") {
        Task { @MainActor in
            let synagamyError: SynagamyError
            
            // Convert common Swift errors to SynagamyError
            if let decodingError = error as? DecodingError {
                synagamyError = .dataCorrupted(resource: context, details: decodingError.localizedDescription)
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    synagamyError = .networkUnavailable
                case .timedOut:
                    synagamyError = .requestTimeout(url: context)
                case .resourceUnavailable:
                    synagamyError = .resourceNotFound(url: context)
                default:
                    synagamyError = .networkUnavailable
                }
            } else if error is CocoaError {
                synagamyError = .dataLoadFailed(resource: context, underlying: error)
            } else {
                synagamyError = .criticalSystemError(details: error.localizedDescription)
            }
            
            handle(synagamyError)
        }
    }
    
    @MainActor
    func clearError() {
        currentError = nil
        isErrorPresented = false
    }
    
    // MARK: - Auto Recovery
    
    private func canAutoRecover(_ error: SynagamyError) -> Bool {
        switch error {
        case .dataLoadFailed, .dataCorrupted, .contentEmpty:
            return true
        case .networkUnavailable, .requestTimeout:
            return true
        case .stateInconsistent, .displayFailed:
            return true
        default:
            return false
        }
    }
    
    private func attemptAutoRecovery(_ error: SynagamyError) {
        Task {
            let success = await recoveryManager.attemptRecovery(for: error)
            
            await MainActor.run {
                if !success {
                    // Auto recovery failed, present error to user
                    presentError(error)
                }
                // If successful, error is resolved silently
            }
        }
    }
    
    // MARK: - Error Tracking
    
    private func trackError(_ error: SynagamyError) {
        let entry = ErrorHistoryEntry(
            error: error,
            timestamp: Date(),
            context: Thread.callStackSymbols.first ?? "Unknown"
        )
        
        errorHistory.append(entry)
        
        // Maintain history size
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxHistorySize)
        }
        
        // Check for error patterns
        analyzeErrorPatterns()
    }
    
    private func analyzeErrorPatterns() {
        let recentErrors = errorHistory.suffix(10)
        let errorCounts = Dictionary(grouping: recentErrors) { $0.error }
        
        // Check for repeated errors (potential infinite loops or systematic issues)
        for (error, occurrences) in errorCounts {
            if occurrences.count >= 3 {
                logger.warning("Repeated error detected: \(error.localizedDescription) (\(occurrences.count) times)")
                
                // Disable auto recovery for this error temporarily
                if case let currentError = error, canAutoRecover(currentError) {
                    shouldAttemptAutoRecovery = false
                    
                    // Re-enable after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        self.shouldAttemptAutoRecovery = true
                    }
                }
            }
        }
    }
    
    // MARK: - Debug Support
    
    func getErrorHistory() -> [ErrorHistoryEntry] {
        return errorHistory
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    func getErrorSummary() -> ErrorSummary {
        let totalErrors = errorHistory.count
        let errorsByType = Dictionary(grouping: errorHistory) { $0.error.severity }
        let mostCommonErrors = Dictionary(grouping: errorHistory) { $0.error }
            .sorted { $0.value.count > $1.value.count }
            .prefix(5)
        
        return ErrorSummary(
            totalErrors: totalErrors,
            highSeverityCount: errorsByType[.high]?.count ?? 0,
            mediumSeverityCount: errorsByType[.medium]?.count ?? 0,
            lowSeverityCount: errorsByType[.low]?.count ?? 0,
            mostCommonErrors: Array(mostCommonErrors.map { ($0.key, $0.value.count) })
        )
    }
    
    // MARK: Error Logging
    
    private func logError(_ error: SynagamyError) {
        let message = "[\(error.severity.description)] \(error.errorDescription ?? "Unknown error")"
        
        switch error.severity {
        case .low:
            logger.info("\(message)")
        case .medium:
            logger.notice("\(message)")
        case .high:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        @unknown default:
            logger.error("\(message)")
        }
    }
    
    // MARK: Recovery Actions
    
    func recoveryActions(for error: SynagamyError) -> [ErrorRecoveryAction] {
        switch error {
        case .dataLoadFailed, .dataCorrupted, .dataMissing:
            return [.retry, .restart]
        case .networkUnavailable, .requestTimeout:
            return [.retry]
        case .urlInvalid, .resourceNotFound:
            return [.none]
        case .contentEmpty, .searchNoResults:
            return [.refresh, .navigateHome]
        case .navigationFailed, .stateInconsistent:
            return [.navigateHome]
        case .criticalSystemError:
            return [.restart, .contactSupport]
        default:
            return [.retry, .none]
        }
    }
}

// MARK: - SwiftUI Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    let onRetry: (() -> Void)?
    let onNavigateHome: (() -> Void)?
    
    init(onRetry: (() -> Void)? = nil, onNavigateHome: (() -> Void)? = nil) {
        self.onRetry = onRetry
        self.onNavigateHome = onNavigateHome
    }
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Something went wrong",
                isPresented: $errorHandler.isErrorPresented,
                actions: {
                    if let error = errorHandler.currentError {
                        ForEach(errorHandler.recoveryActions(for: error), id: \.title) { action in
                            Button(action.title) {
                                handleRecoveryAction(action, for: error)
                            }
                        }
                    }
                },
                message: {
                    if let error = errorHandler.currentError {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(error.userFriendlyMessage)
                            if let suggestion = error.recoverySuggestion {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            )
    }
    
    private func handleRecoveryAction(_ action: ErrorRecoveryAction, for error: SynagamyError) {
        switch action {
        case .retry:
            onRetry?()
        case .refresh:
            onRetry?() // Same as retry for most cases
        case .navigateHome:
            onNavigateHome?()
        case .restart:
            // Force app restart by calling exit - only for critical errors
            if error.severity == .high {
                exit(0)
            }
        case .contactSupport:
            // Open support URL or mail app
            if let url = URL(string: "https://fertilitymatters.ca/support/") {
                UIApplication.shared.open(url)
            }
        case .none:
            break
        }
        
        errorHandler.clearError()
    }
}

// MARK: - View Extension

extension View {
    func errorAlert(
        onRetry: (() -> Void)? = nil,
        onNavigateHome: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorAlertModifier(onRetry: onRetry, onNavigateHome: onNavigateHome))
    }
}

// MARK: - Error Tracking Models

struct ErrorHistoryEntry: Identifiable {
    let id = UUID()
    let error: SynagamyError
    let timestamp: Date
    let context: String
}

struct ErrorSummary {
    let totalErrors: Int
    let highSeverityCount: Int
    let mediumSeverityCount: Int
    let lowSeverityCount: Int
    let mostCommonErrors: [(SynagamyError, Int)]
}