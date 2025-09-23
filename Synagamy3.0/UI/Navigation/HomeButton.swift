//
//  HomeButton.swift
//  Synagamy3.0
//
//  Enhanced home button with improved performance, better visual feedback,
//  and proper pop-to-root functionality.
//

import SwiftUI
import Foundation

struct HomeButton: View {
    let usePopToRoot: Bool
    var size: CGFloat = 56
    var systemIcon: String = "house.fill"

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var lastTapTime: Date = .distantPast

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
                                    Brand.Color.primary,
                                    Brand.Color.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Brand.Color.primary.opacity(0.3),
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
        // Immediate haptic feedback for responsiveness
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()
        impactGenerator.impactOccurred()

        if usePopToRoot {
            // Simple throttling to prevent rapid successive taps
            let now = Date()
            guard now.timeIntervalSince(lastTapTime) >= 0.3 else { return }
            lastTapTime = now

            NotificationCenter.default.post(name: .goHome, object: nil)
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let goHome = Notification.Name("Synagamy.GoHome")
}
