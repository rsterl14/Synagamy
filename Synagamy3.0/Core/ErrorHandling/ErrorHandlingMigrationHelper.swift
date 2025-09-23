//
//  ErrorHandlingMigrationHelper.swift
//  Synagamy3.0
//
//  Migration utilities to help convert existing views from scattered
//  error handling patterns to the unified error handling system.
//

import SwiftUI

// MARK: - Migration Helper

struct ErrorHandlingMigrationHelper {

    /// Convert individual @State error handling to unified system
    ///
    /// Before (scattered pattern):
    /// ```
    /// @State private var errorMessage: String? = nil
    /// @State private var showingErrorAlert = false
    ///
    /// .alert("Error", isPresented: $showingErrorAlert) {
    ///     Button("OK") { }
    /// } message: {
    ///     Text(errorMessage ?? "")
    /// }
    /// ```
    ///
    /// After (unified pattern):
    /// ```
    /// .unifiedErrorHandling(
    ///     viewContext: "EducationView",
    ///     onRetry: { await loadEducationContent() },
    ///     onNavigateHome: { /* navigation logic */ }
    /// )
    /// ```
    static func migrateFromStateErrorHandling() -> String {
        return """
        // REMOVE these @State variables:
        // @State private var errorMessage: String? = nil
        // @State private var showingErrorAlert = false

        // REMOVE alert modifiers like:
        // .alert("Error", isPresented: $showingErrorAlert) { ... }

        // ADD unified error handling:
        .unifiedErrorHandling(
            viewContext: "YourViewName",
            onRetry: { await yourRetryFunction() },
            onNavigateHome: { /* your navigation logic */ }
        )

        // REPLACE error handling calls:
        // OLD: errorMessage = "Something went wrong"; showingErrorAlert = true
        // NEW: UnifiedErrorManager.shared.handleError(.dataLoadFailed(resource: "content", underlying: error), in: "YourViewName")
        """
    }

    /// Convert ErrorHandler.shared usage to unified system
    static func migrateFromLegacyErrorHandler() -> String {
        return """
        // REMOVE:
        // @StateObject private var errorHandler = ErrorHandler.shared

        // UPDATE error handling calls:
        // OLD: errorHandler.handle(.networkUnavailable)
        // NEW: UnifiedErrorManager.shared.handleError(.networkUnavailable, in: "YourViewName")

        // UPDATE view modifiers:
        // OLD: .enhancedErrorHandling(errorHandler: errorHandler, onRetry: { ... })
        // NEW: .unifiedErrorHandling(viewContext: "YourViewName", onRetry: { ... })
        """
    }
}

// MARK: - View-Specific Migration Templates

extension ErrorHandlingMigrationHelper {

    /// Template for data loading views (Education, Resources, etc.)
    static func dataLoadingViewTemplate() -> String {
        return """
        struct YourDataView: View {
            @State private var data: [YourDataType] = []
            @State private var isLoading = false

            var body: some View {
                StandardPageLayout(...) {
                    // Your content here
                }
                .unifiedErrorHandling(
                    viewContext: "YourDataView",
                    onRetry: { await loadData() },
                    onNavigateHome: { /* navigation logic */ }
                )
                .task {
                    await loadData()
                }
            }

            private func loadData() async {
                isLoading = true
                defer { isLoading = false }

                do {
                    // Your data loading logic
                    data = try await dataService.loadData()
                } catch {
                    UnifiedErrorManager.shared.handleDataLoadError(
                        error,
                        resource: "your_data",
                        in: "YourDataView",
                        recoveryHandler: UnifiedErrorManager.ErrorRecoveryHandler(
                            onRetry: { await loadData() }
                        )
                    )
                }
            }
        }
        """
    }

    /// Template for network-dependent views
    static func networkViewTemplate() -> String {
        return """
        struct YourNetworkView: View {
            @StateObject private var networkManager = NetworkStatusManager.shared

            var body: some View {
                StandardPageLayout(...) {
                    if networkManager.isOnline {
                        // Your online content
                    } else {
                        OfflineContentView()
                    }
                }
                .unifiedErrorHandling(
                    viewContext: "YourNetworkView",
                    onRetry: { await refreshContent() }
                )
            }

            private func handleNetworkError(_ error: Error, url: String? = nil) {
                UnifiedErrorManager.shared.handleNetworkError(
                    error,
                    url: url,
                    in: "YourNetworkView",
                    recoveryHandler: UnifiedErrorManager.ErrorRecoveryHandler(
                        onRetry: { await refreshContent() }
                    )
                )
            }
        }
        """
    }

    /// Template for input validation views
    static func inputValidationViewTemplate() -> String {
        return """
        struct YourInputView: View {
            @State private var inputValue = ""

            var body: some View {
                Form {
                    TextField("Enter value", text: $inputValue)

                    Button("Calculate") {
                        validateAndCalculate()
                    }
                }
                .unifiedErrorHandling(
                    viewContext: "YourInputView",
                    onRetry: { /* no retry for input errors */ }
                )
            }

            private func validateAndCalculate() {
                do {
                    let result = try validateInput(inputValue)
                    // Use validated result
                } catch let synagamyError as SynagamyError {
                    UnifiedErrorManager.shared.handleError(
                        synagamyError,
                        in: "YourInputView"
                    )
                } catch {
                    UnifiedErrorManager.shared.handleSwiftError(
                        error,
                        in: "YourInputView"
                    )
                }
            }
        }
        """
    }
}

// MARK: - Common Error Patterns

extension ErrorHandlingMigrationHelper {

    /// Common patterns for handling different error scenarios
    enum ErrorPattern {
        case dataLoading
        case networkOperation
        case userInput
        case navigation
        case export

        var template: String {
            switch self {
            case .dataLoading:
                return """
                // Data Loading Error Pattern
                do {
                    let data = try await dataService.loadData()
                    // Handle success
                } catch {
                    UnifiedErrorManager.shared.handleDataLoadError(
                        error,
                        resource: "data_name",
                        in: "ViewName",
                        recoveryHandler: UnifiedErrorManager.ErrorRecoveryHandler(
                            onRetry: { await loadData() }
                        )
                    )
                }
                """

            case .networkOperation:
                return """
                // Network Operation Error Pattern
                do {
                    let response = try await networkService.fetchData(from: url)
                    // Handle success
                } catch {
                    UnifiedErrorManager.shared.handleNetworkError(
                        error,
                        url: url.absoluteString,
                        in: "ViewName",
                        recoveryHandler: UnifiedErrorManager.ErrorRecoveryHandler(
                            onRetry: { await fetchData() }
                        )
                    )
                }
                """

            case .userInput:
                return """
                // User Input Validation Error Pattern
                guard let validatedValue = validateInput(userInput) else {
                    UnifiedErrorManager.shared.handleError(
                        .invalidInput(details: "Description of what's wrong"),
                        in: "ViewName"
                    )
                    return
                }
                """

            case .navigation:
                return """
                // Navigation Error Pattern
                guard let destination = determineDestination() else {
                    UnifiedErrorManager.shared.handleError(
                        .navigationFailed(destination: "destination_name"),
                        in: "ViewName"
                    )
                    return
                }
                """

            case .export:
                return """
                // Export Error Pattern
                do {
                    try await exportService.exportData(data)
                    // Handle success
                } catch {
                    UnifiedErrorManager.shared.handleError(
                        .exportFailed(details: error.localizedDescription),
                        in: "ViewName",
                        recoveryHandler: UnifiedErrorManager.ErrorRecoveryHandler(
                            onRetry: { await retryExport() }
                        )
                    )
                }
                """
            }
        }
    }
}

// MARK: - Testing Helpers

extension ErrorHandlingMigrationHelper {

    /// Helper to test error handling in different scenarios
    static func createTestError(for scenario: ErrorPattern) -> SynagamyError {
        switch scenario {
        case .dataLoading:
            return .dataLoadFailed(resource: "test_data", underlying: nil)
        case .networkOperation:
            return .networkUnavailable
        case .userInput:
            return .invalidInput(details: "Test input error")
        case .navigation:
            return .navigationFailed(destination: "test_destination")
        case .export:
            return .exportFailed(details: "Test export error")
        }
    }

    /// Test unified error handling in a view
    @MainActor
    static func testErrorHandling(in viewContext: String, error: SynagamyError) {
        UnifiedErrorManager.shared.handleError(
            error,
            in: viewContext,
            shouldPresent: true
        )
    }
}