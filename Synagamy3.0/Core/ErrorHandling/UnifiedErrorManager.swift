//
//  UnifiedErrorManager.swift
//  Synagamy3.0
//
//  Unified error handling architecture that consolidates all error management
//  into a single, consistent system across the entire application.
//
//  Features:
//  - Centralized error state management
//  - Consistent user experience across all views
//  - Automatic error recovery and logging
//  - Context-aware error handling
//  - Medical app compliance for error messaging
//

import Foundation
import SwiftUI
import os.log

// Import SynagamyError and related types from ErrorHandler
// Note: This creates a bridge between the new unified system and existing error types

// MARK: - Unified Error Manager

@MainActor
final class UnifiedErrorManager: ObservableObject {
    static let shared = UnifiedErrorManager()

    // MARK: - Published Properties

    @Published private(set) var currentError: ErrorContext?
    @Published var isPresentingError = false
    @Published private(set) var errorHistory: [ErrorHistoryEntry] = []

    // MARK: - Configuration

    private let logger = Logger(subsystem: "com.synagamy.app", category: "UnifiedErrorManager")
    private let maxHistoryEntries = 50
    private var autoRecoveryAttempts: [String: Int] = [:]
    private let maxAutoRecoveryAttempts = 3

    // MARK: - Error Context

    struct ErrorContext: Identifiable {
        let id = UUID()
        let error: SynagamyError
        let viewContext: String
        let timestamp: Date
        let userInfo: [String: Any]
        let recoveryHandler: ErrorRecoveryHandler?

        init(
            error: SynagamyError,
            viewContext: String,
            userInfo: [String: Any] = [:],
            recoveryHandler: ErrorRecoveryHandler? = nil
        ) {
            self.error = error
            self.viewContext = viewContext
            self.timestamp = Date()
            self.userInfo = userInfo
            self.recoveryHandler = recoveryHandler
        }
    }

    // MARK: - Recovery Handler

    struct ErrorRecoveryHandler {
        let onRetry: (() async -> Void)?
        let onNavigateHome: (() -> Void)?
        let onCustomAction: ((String) async -> Void)?

        init(
            onRetry: (() async -> Void)? = nil,
            onNavigateHome: (() -> Void)? = nil,
            onCustomAction: ((String) async -> Void)? = nil
        ) {
            self.onRetry = onRetry
            self.onNavigateHome = onNavigateHome
            self.onCustomAction = onCustomAction
        }
    }

    private init() {
        setupErrorRecovery()
    }

    // MARK: - Public API

    /// Primary method for handling errors throughout the app
    func handleError(
        _ error: SynagamyError,
        in viewContext: String,
        userInfo: [String: Any] = [:],
        recoveryHandler: ErrorRecoveryHandler? = nil,
        shouldPresent: Bool = true
    ) {
        let context = ErrorContext(
            error: error,
            viewContext: viewContext,
            userInfo: userInfo,
            recoveryHandler: recoveryHandler
        )

        // Log the error
        logError(context)

        // Add to history
        addToHistory(context)

        // Attempt automatic recovery if appropriate
        if shouldAttemptAutoRecovery(for: error, in: viewContext) {
            Task {
                await attemptAutoRecovery(context)
            }
        } else if shouldPresent {
            presentError(context)
        }
    }

    /// Handle Swift Error types by converting them to SynagamyError
    func handleSwiftError(
        _ error: Error,
        in viewContext: String,
        userInfo: [String: Any] = [:],
        recoveryHandler: ErrorRecoveryHandler? = nil
    ) {
        let synagamyError = convertToSynagamyError(error, context: viewContext)
        handleError(synagamyError, in: viewContext, userInfo: userInfo, recoveryHandler: recoveryHandler)
    }

    /// Handle network-specific errors with enhanced context
    func handleNetworkError(
        _ error: Error,
        url: String? = nil,
        in viewContext: String,
        recoveryHandler: ErrorRecoveryHandler? = nil
    ) {
        var userInfo: [String: Any] = [:]
        if let url = url {
            userInfo["url"] = url
        }

        let synagamyError: SynagamyError
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                synagamyError = .networkUnavailable
            case .timedOut:
                synagamyError = .requestTimeout(url: url ?? "unknown")
            case .resourceUnavailable:
                synagamyError = .resourceNotFound(url: url ?? "unknown")
            default:
                synagamyError = .networkUnavailable
            }
        } else {
            synagamyError = .networkUnavailable
        }

        handleError(synagamyError, in: viewContext, userInfo: userInfo, recoveryHandler: recoveryHandler)
    }

    /// Handle data loading errors with context
    func handleDataLoadError(
        _ error: Error?,
        resource: String,
        in viewContext: String,
        recoveryHandler: ErrorRecoveryHandler? = nil
    ) {
        let synagamyError: SynagamyError

        if let error = error {
            if error is DecodingError {
                synagamyError = .dataCorrupted(resource: resource, details: error.localizedDescription)
            } else {
                synagamyError = .dataLoadFailed(resource: resource, underlying: error)
            }
        } else {
            synagamyError = .dataMissing(resource: resource)
        }

        let userInfo = ["resource": resource]
        handleError(synagamyError, in: viewContext, userInfo: userInfo, recoveryHandler: recoveryHandler)
    }

    /// Clear current error and dismiss presentation
    func clearError() {
        currentError = nil
        isPresentingError = false
    }

    /// Get error history for debugging
    func getErrorHistory() -> [ErrorHistoryEntry] {
        return errorHistory
    }

    /// Clear error history
    func clearErrorHistory() {
        errorHistory.removeAll()
        autoRecoveryAttempts.removeAll()
    }

    // MARK: - Private Methods

    private func presentError(_ context: ErrorContext) {
        // Defer presentation to avoid SwiftUI update conflicts
        Task {
            try? await Task.sleep(nanoseconds: 16_666_666) // ~1 frame

            currentError = context
            isPresentingError = true

            // Auto-dismiss low severity errors
            if context.error.severity == .low {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                    if currentError?.id == context.id {
                        clearError()
                    }
                }
            }
        }
    }

    private func shouldAttemptAutoRecovery(for error: SynagamyError, in viewContext: String) -> Bool {
        let recoveryKey = "\(error.hashValue)-\(viewContext)"
        let attempts = autoRecoveryAttempts[recoveryKey] ?? 0

        guard attempts < maxAutoRecoveryAttempts else {
            return false
        }

        switch error {
        case .dataLoadFailed, .networkUnavailable, .requestTimeout:
            return true
        case .contentEmpty where viewContext.contains("List") || viewContext.contains("View"):
            return true
        default:
            return false
        }
    }

    private func attemptAutoRecovery(_ context: ErrorContext) async {
        let recoveryKey = "\(context.error.hashValue)-\(context.viewContext)"
        autoRecoveryAttempts[recoveryKey] = (autoRecoveryAttempts[recoveryKey] ?? 0) + 1

        logger.info("Attempting auto-recovery for \(context.error.errorDescription ?? "unknown error") in \(context.viewContext)")

        var recovered = false

        // Attempt specific recovery based on error type
        switch context.error {
        case .dataLoadFailed, .dataMissing:
            // Retry data loading with recovery handler
            if let retryHandler = context.recoveryHandler?.onRetry {
                await retryHandler()
                recovered = true
            }

        case .networkUnavailable, .requestTimeout:
            // Wait briefly and retry
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if let retryHandler = context.recoveryHandler?.onRetry {
                await retryHandler()
                recovered = true
            }

        case .contentEmpty:
            // Trigger a refresh if possible
            if let retryHandler = context.recoveryHandler?.onRetry {
                await retryHandler()
                recovered = true
            }

        default:
            break
        }

        if !recovered {
            // Auto-recovery failed, present error to user
            presentError(context)
        } else {
            logger.info("Auto-recovery successful for \(context.error.errorDescription ?? "unknown error")")
        }
    }

    private func convertToSynagamyError(_ error: Error, context: String) -> SynagamyError {
        if let synagamyError = error as? SynagamyError {
            return synagamyError
        }

        if let decodingError = error as? DecodingError {
            return .dataCorrupted(resource: context, details: decodingError.localizedDescription)
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .networkUnavailable
            case .timedOut:
                return .requestTimeout(url: context)
            case .resourceUnavailable:
                return .resourceNotFound(url: context)
            default:
                return .networkUnavailable
            }
        }

        if error is CocoaError {
            return .dataLoadFailed(resource: context, underlying: error)
        }

        return .criticalSystemError(details: error.localizedDescription)
    }

    private func logError(_ context: ErrorContext) {
        let message = "[\(context.viewContext)] \(context.error.errorDescription ?? "Unknown error")"

        switch context.error.severity {
        case .low:
            logger.info("\(message)")
        case .medium:
            logger.notice("\(message)")
        case .high:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
    }

    private func addToHistory(_ context: ErrorContext) {
        let entry = ErrorHistoryEntry(
            error: context.error,
            timestamp: context.timestamp,
            context: "\(context.viewContext): \(context.userInfo.description)"
        )

        errorHistory.insert(entry, at: 0)

        // Maintain history size
        if errorHistory.count > maxHistoryEntries {
            errorHistory.removeLast(errorHistory.count - maxHistoryEntries)
        }
    }

    private func setupErrorRecovery() {
        // Clear recovery attempts periodically
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // 5 minutes
            Task { @MainActor in
                self.autoRecoveryAttempts.removeAll()
            }
        }
    }
}

// MARK: - Unified Error View Modifier

struct UnifiedErrorHandling: ViewModifier {
    @StateObject private var errorManager = UnifiedErrorManager.shared
    let viewContext: String
    let onRetry: (() async -> Void)?
    let onNavigateHome: (() -> Void)?

    init(
        viewContext: String,
        onRetry: (() async -> Void)? = nil,
        onNavigateHome: (() -> Void)? = nil
    ) {
        self.viewContext = viewContext
        self.onRetry = onRetry
        self.onNavigateHome = onNavigateHome
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if errorManager.isPresentingError,
                       let errorContext = errorManager.currentError {

                        ZStack {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    errorManager.clearError()
                                }

                            UnifiedErrorDialog(
                                error: errorContext.error,
                                viewContext: errorContext.viewContext,
                                recoveryHandler: errorContext.recoveryHandler ?? UnifiedErrorManager.ErrorRecoveryHandler(
                                    onRetry: onRetry,
                                    onNavigateHome: onNavigateHome
                                ),
                                onDismiss: {
                                    errorManager.clearError()
                                }
                            )
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: errorManager.isPresentingError)
                    }
                }
            )
    }
}

// MARK: - Unified Error Dialog

struct UnifiedErrorDialog: View {
    let error: SynagamyError
    let viewContext: String
    let recoveryHandler: UnifiedErrorManager.ErrorRecoveryHandler
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Error Icon and Title
            VStack(spacing: 12) {
                Image(systemName: error.severity.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(error.severity.color)

                Text(error.userFriendlyTitle)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
            }

            // Error Message
            Text(error.userFriendlyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)

            // Recovery Suggestions
            if let suggestion = error.recoverySuggestion {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                        Text("Suggestion")
                            .font(.headline)
                    }

                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.1))
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
            }

            // Action Buttons
            HStack(spacing: 12) {
                // Retry Button
                if let onRetry = recoveryHandler.onRetry {
                    Button("Try Again") {
                        onDismiss()
                        Task {
                            await onRetry()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }

                // Navigate Home Button
                if let onNavigateHome = recoveryHandler.onNavigateHome {
                    Button("Go Home") {
                        onDismiss()
                        onNavigateHome()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }

                // Dismiss Button
                Button(error.severity == .low ? "OK" : "Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(radius: 20)
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - View Extension

extension View {
    /// Apply unified error handling to any view
    func unifiedErrorHandling(
        viewContext: String,
        onRetry: (() async -> Void)? = nil,
        onNavigateHome: (() -> Void)? = nil
    ) -> some View {
        modifier(UnifiedErrorHandling(
            viewContext: viewContext,
            onRetry: onRetry,
            onNavigateHome: onNavigateHome
        ))
    }
}

// MARK: - Legacy ErrorHandler Bridge

extension UnifiedErrorManager {
    /// Bridge method to maintain compatibility with existing ErrorHandler usage
    func bridgeFromLegacyErrorHandler(_ legacyError: SynagamyError, viewContext: String = "Unknown") {
        handleError(legacyError, in: viewContext)
    }
}