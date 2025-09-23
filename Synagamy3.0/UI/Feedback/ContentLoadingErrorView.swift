//
//  ContentLoadingErrorView.swift
//  Synagamy3.0
//
//  Error view component for displaying content loading failures
//  with network status information and retry actions.
//

import SwiftUI

// MARK: - Content Loading Error View

struct ContentLoadingErrorView: View {
    let title: String
    let message: String
    let onRetry: (() -> Void)?

    @StateObject private var networkManager = NetworkStatusManager.shared

    init(title: String = "Content Unavailable", message: String = "Unable to load content", onRetry: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: Brand.Spacing.spacing6) {
            // Error illustration
            VStack(spacing: Brand.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: Brand.Spacing.spacing8 * 2.5, height: Brand.Spacing.spacing8 * 2.5)

                    Image(systemName: networkManager.networkStatus.icon)
                        .font(.system(size: 36))
                        .foregroundColor(networkManager.networkStatus.color)
                }

                VStack(spacing: Brand.Spacing.sm) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(networkManager.getErrorMessage(for: "load this content"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            // Network status info
            if networkManager.networkStatus.shouldShowNetworkError {
                VStack(spacing: Brand.Spacing.md) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)

                        Text("Network Status")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        Spacer()

                        NetworkStatusIndicator(showText: true)
                    }

                    VStack(alignment: .leading, spacing: Brand.Spacing.xs + Brand.Spacing.spacing1) {
                        Text("Suggestions:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)

                        ForEach(Array(networkManager.getRecoverySuggestions().prefix(3).enumerated()), id: \.offset) { index, suggestion in
                            HStack(alignment: .top, spacing: Brand.Spacing.xs + Brand.Spacing.spacing1) {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(Brand.Radius.sm)
                }
                .padding(.horizontal)
            }

            // Action buttons
            VStack(spacing: Brand.Spacing.md) {
                if let onRetry = onRetry {
                    Button(action: {
                        Task {
                            await networkManager.checkConnectivity()
                            onRetry()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                            Text("Try Again")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Brand.Spacing.xl)
                        .padding(.vertical, Brand.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.md)
                                .fill(Color.blue)
                        )
                    }
                    .accessibilityLabel("Retry loading content")
                    .accessibilityHint("Attempts to reload the content")
                }

                Button("Check Connection") {
                    Task {
                        await networkManager.checkConnectivity()
                    }
                }
                .buttonStyle(NetworkActionButtonStyle(color: .secondary, isSecondary: true))
            }
        }
        .padding(Brand.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Note: NetworkActionButtonStyle is now in UI/System/ButtonStyles.swift

#Preview {
    ContentLoadingErrorView(
        title: "Unable to Load Topics",
        message: "Please check your connection and try again"
    ) {
        print("Retry tapped")
    }
}