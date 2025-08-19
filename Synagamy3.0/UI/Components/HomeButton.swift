//
//  HomeButton.swift
//  Synagamy3.0
//
//  A reusable button for returning to Home.
//  By default, it *navigates* to HomeView (keeps existing behavior).
//  Optionally, you can enable "pop-to-root" mode to clear the current stack
//  via a notification the root TabView listens for.
//
//  How to use:
//    // Current behavior (pushes a new HomeView on the stack):
//    HomeButton()
//
//    // Preferred: pop-to-root (no duplicate Home screens):
//    // 1) Use HomeButton(usePopToRoot: true)
//    // 2) In MainTabView, listen for `.goHome` and clear the current path (see note below).
//

import SwiftUI
import Combine

struct HomeButton: View {
    /// When `true`, the button emits a `.goHome` notification instead of pushing a new HomeView.
    /// Your MainTabView should observe this and clear its navigation path for the current tab.
    let usePopToRoot: Bool

    /// Optional customization for size and icon.
    var size: CGFloat = 44
    var systemIcon: String = "house.fill"

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    init(usePopToRoot: Bool = false, size: CGFloat = 44, systemIcon: String = "house.fill") {
        self.usePopToRoot = usePopToRoot
        self.size = size
        self.systemIcon = systemIcon
    }

    var body: some View {
        Group {
            if usePopToRoot {
                // POP-TO-ROOT MODE: Emit a notification that MainTabView listens for.
                Button(action: goHome) {
                    icon
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Go to Home"))
                .accessibilityHint(Text("Returns to the Home screen without opening a new page."))
            } else {
                // LEGACY MODE: Pushes a *new* HomeView onto the current stack.
                NavigationLink(destination: HomeView()) {
                    icon
                }
                .accessibilityLabel(Text("Go to Home"))
                .accessibilityHint(Text("Opens the Home screen."))
            }
        }
    }

    // MARK: - Visuals

    private var icon: some View {
        Image(systemName: systemIcon)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Color("BrandSecondary"))
            .clipShape(Circle())
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isPressed)
    }

    // MARK: - Actions

    private func goHome() {
        // Gentle haptic for affordance (App Store–friendly).
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Post a notification; MainTabView (or your root container) should observe
        // `Notification.Name.goHome` and clear the active navigation path + select .home.
        NotificationCenter.default.post(name: .goHome, object: nil)
    }
}

// MARK: - Notification name used for pop-to-root coordination

extension Notification.Name {
    static let goHome = Notification.Name("Synagamy.GoHome")
}
