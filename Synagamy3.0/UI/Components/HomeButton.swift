//
//  HomeButton.swift
//  Synagamy3.0
//
//  Enhanced home button with improved performance, better visual feedback,
//  and proper pop-to-root functionality.
//

import SwiftUI

struct HomeButton: View {
    let usePopToRoot: Bool
    var size: CGFloat = 56
    var systemIcon: String = "house.fill"

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    init(usePopToRoot: Bool = true, size: CGFloat = 56, systemIcon: String = "house.fill") {
        self.usePopToRoot = usePopToRoot
        self.size = size
        self.systemIcon = systemIcon
    }

    var body: some View {
        Button(action: handleTap) {
            Image(systemName: systemIcon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Brand.ColorSystem.primary,
                                    Brand.ColorSystem.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Brand.ColorSystem.primary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("Go to Home")
        .accessibilityHint("Returns to the main home screen")
    }

    private func handleTap() {
        // Optimized haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()
        impactGenerator.impactOccurred()

        if usePopToRoot {
            NotificationCenter.default.post(name: .goHome, object: nil)
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let goHome = Notification.Name("Synagamy.GoHome")
}
