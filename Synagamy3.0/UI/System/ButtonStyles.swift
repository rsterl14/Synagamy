//
//  ButtonStyles.swift
//  Synagamy3.0
//
//  Shared button styles used across the app.
//  This prevents duplicate declarations and ensures consistency.
//

import SwiftUI

// MARK: - Network Action Button Style

struct NetworkActionButtonStyle: ButtonStyle {
    let color: Color
    let isSecondary: Bool

    init(color: Color, isSecondary: Bool = false) {
        self.color = color
        self.isSecondary = isSecondary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(isSecondary ? color : .white)
            .padding(.horizontal, Brand.Spacing.lg)
            .padding(.vertical, Brand.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.sm)
                    .fill(isSecondary ? Color.clear : color)
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.Radius.sm)
                            .stroke(color, lineWidth: isSecondary ? 1 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(Brand.Motion.userInteraction, value: configuration.isPressed)
    }
}

// MARK: - Additional Button Styles can be added here as needed

#Preview("Network Button Styles") {
    VStack(spacing: 20) {
        Button("Primary Action") {}
            .buttonStyle(NetworkActionButtonStyle(color: .blue))

        Button("Secondary Action") {}
            .buttonStyle(NetworkActionButtonStyle(color: .blue, isSecondary: true))

        Button("Danger Action") {}
            .buttonStyle(NetworkActionButtonStyle(color: .red))
    }
    .padding()
}