//
//  NetworkStatusIndicator.swift
//  Synagamy3.0
//
//  Small network status indicator component for displaying
//  connectivity status in compact spaces.
//

import SwiftUI

// MARK: - Network Status Indicator

struct NetworkStatusIndicator: View {
    @StateObject private var networkManager = NetworkStatusManager.shared
    let showText: Bool

    init(showText: Bool = false) {
        self.showText = showText
    }

    var body: some View {
        HStack(spacing: Brand.Spacing.xs + Brand.Spacing.spacing1) {
            Image(systemName: networkManager.networkStatus.icon)
                .font(.caption)
                .foregroundColor(networkManager.networkStatus.color)

            if showText {
                Text(networkManager.networkStatus.displayName)
                    .font(.caption)
                    .foregroundColor(networkManager.networkStatus.color)
            }

            if !networkManager.isOnline {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, Brand.Spacing.sm)
        .padding(.vertical, Brand.Spacing.xs)
        .background(
            Capsule()
                .fill(networkManager.networkStatus.color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(networkManager.networkStatus.color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview("Indicator Only") {
    NetworkStatusIndicator(showText: false)
        .padding()
}

#Preview("Indicator with Text") {
    NetworkStatusIndicator(showText: true)
        .padding()
}