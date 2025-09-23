//
//  NetworkStatusBanner.swift
//  Synagamy3.0
//
//  Network status banner component for displaying connectivity issues
//  with expandable details and recovery suggestions.
//

import SwiftUI

// MARK: - Network Status Banner

struct NetworkStatusBanner: View {
    @StateObject private var networkManager = NetworkStatusManager.shared
    @State private var isExpanded = false

    var body: some View {
        if networkManager.networkStatus.shouldShowNetworkError {
            VStack(spacing: 0) {
                // Main banner
                HStack(spacing: Brand.Spacing.md) {
                    Image(systemName: networkManager.networkStatus.icon)
                        .font(.headline)
                        .foregroundColor(networkManager.networkStatus.color)

                    VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                        Text(networkManager.networkStatus.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        if let reason = networkManager.failureReason {
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(isExpanded ? nil : 1)
                        }
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(Brand.Motion.easeInOut) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, Brand.Spacing.pageMargins)
                .padding(.vertical, Brand.Spacing.md)
                .background(networkManager.networkStatus.color.opacity(0.1))

                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        Divider()
                            .padding(.horizontal, Brand.Spacing.pageMargins)

                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            Text("What you can do:")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.primary)

                            ForEach(Array(networkManager.getRecoverySuggestions().enumerated()), id: \.offset) { index, suggestion in
                                HStack(alignment: .top, spacing: Brand.Spacing.sm) {
                                    Text("\(index + 1).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: Brand.Spacing.lg, alignment: .leading)

                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        .padding(.horizontal, Brand.Spacing.pageMargins)

                        // Action buttons
                        HStack(spacing: Brand.Spacing.md) {
                            Button("Try Again") {
                                Task {
                                    await networkManager.checkConnectivity()
                                }
                            }
                            .buttonStyle(NetworkActionButtonStyle(color: networkManager.networkStatus.color))

                            Button("Dismiss") {
                                withAnimation(Brand.Motion.easeInOut) {
                                    isExpanded = false
                                }
                            }
                            .buttonStyle(NetworkActionButtonStyle(color: .secondary, isSecondary: true))

                            Spacer()
                        }
                        .padding(.horizontal, Brand.Spacing.pageMargins)
                        .padding(.bottom, Brand.Spacing.md)
                    }
                    .background(networkManager.networkStatus.color.opacity(0.05))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Radius.md)
                    .stroke(networkManager.networkStatus.color.opacity(0.3), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(Brand.Motion.easeInOut, value: networkManager.networkStatus)
        }
    }
}

// MARK: - Note: NetworkActionButtonStyle is now in UI/System/ButtonStyles.swift

#Preview {
    NetworkStatusBanner()
        .padding()
}