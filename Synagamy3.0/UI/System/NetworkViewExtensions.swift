//
//  NetworkViewExtensions.swift
//  Synagamy3.0
//
//  View extensions for network-aware functionality.
//  This file was recreated after accidentally being removed during UI reorganization.
//

import SwiftUI

// MARK: - Network-Aware View Extensions

extension View {
    /// Makes a view network-aware by adding network status monitoring and banner display
    func networkAware() -> some View {
        self.modifier(NetworkAwareModifier())
    }
}

// MARK: - Network Aware Modifier

struct NetworkAwareModifier: ViewModifier {
    @StateObject private var networkManager = NetworkStatusManager.shared

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // Show network status banner when there are issues
            if networkManager.networkStatus.shouldShowNetworkError {
                NetworkStatusBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(Brand.Motion.easeInOut, value: networkManager.networkStatus.shouldShowNetworkError)
            }

            content
        }
        .onAppear {
            // Check connectivity when view appears
            Task {
                await networkManager.checkConnectivity()
            }
        }
    }
}

// MARK: - Additional Network-Related View Extensions

extension View {
    /// Shows an inline network error message
    func inlineNetworkError(for operation: String) -> some View {
        self.modifier(InlineNetworkErrorModifier(operation: operation))
    }

    /// Adds centralized error alert handling
    func errorAlert(
        onRetry: @escaping () -> Void = {},
        onNavigateHome: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(ErrorAlertModifier(onRetry: onRetry, onNavigateHome: onNavigateHome))
    }
}

struct InlineNetworkErrorModifier: ViewModifier {
    let operation: String
    @StateObject private var networkManager = NetworkStatusManager.shared

    func body(content: Content) -> some View {
        VStack {
            content

            if networkManager.networkStatus.shouldShowNetworkError {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("Network issue may affect \(operation)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    let onRetry: () -> Void
    let onNavigateHome: () -> Void
    @State private var showingAlert = false

    func body(content: Content) -> some View {
        content
            .alert("Error Occurred", isPresented: $showingAlert) {
                Button("Retry") {
                    onRetry()
                    showingAlert = false
                }

                Button("Go Home") {
                    onNavigateHome()
                    showingAlert = false
                }

                Button("Dismiss", role: .cancel) {
                    showingAlert = false
                }
            } message: {
                Text("An error occurred. Please try again.")
            }
    }
}

// Note: NSNotification.Name.goHome is defined in HomeButton.swift
