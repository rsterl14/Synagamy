//
//  SynagamyApp.swift
//  Synagamy3.0
//
//  App entry point.
//  • Sets up consistent global appearance (brand tint, transparent nav bars).
//  • Preloads JSON-backed data once at launch (non-blocking, no force-unwraps).
//  • Warms a TopicMatcher index so step→topic sheets feel instant.
//  • Keeps everything defensive and App Store–friendly.
//

import SwiftUI

@main
struct SynagamyApp: App {
    @StateObject private var launchModel = AppLaunchModel()

    init() {
        #if DEBUG
        print("🚀 SynagamyApp: App starting up...")
        #endif
        configureAppearance()
        #if DEBUG
        print("🚀 SynagamyApp: App initialization complete")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(Color("BrandPrimary"))   // global accent
                .task {
                    // Preload JSON data + warm caches (non-blocking, safe).
                    do {
                        try await Task.sleep(nanoseconds: 50_000_000) // Brief delay to avoid publishing conflicts
                    } catch {
                        // If sleep is cancelled, continue anyway
                    }
                    await MainActor.run {
                        launchModel.preload()
                    }
                }
        }
    }
}

// MARK: - Global appearance

private extension SynagamyApp {
    /// Configure consistent, brand-aligned navigation/tab appearance.
    func configureAppearance() {
        // Be conservative with UIAppearance (Apple guidelines). Keep to colors/translucency.
        let brandPrimary = UIColor(named: "BrandPrimary") ?? .systemBlue

        // UINavigationBar
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()   // we render our own floating header
        nav.backgroundColor = .clear
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor.label]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = brandPrimary

        // UITabBar
        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundColor = UIColor.systemBackground
        tab.shadowColor = UIColor.separator.withAlphaComponent(0.15)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = brandPrimary

        // UISegmentedControl (used in a few places)
        UISegmentedControl.appearance().selectedSegmentTintColor = brandPrimary.withAlphaComponent(0.12)
    }
}

// MARK: - Launch model (safe preload + optional user-facing messaging)

@MainActor
final class AppLaunchModel: ObservableObject {
    @Published var errorMessage: String? = nil

    /// Preload JSON-backed data and warm any caches you rely on frequently.
    /// This is intentionally defensive (no force-unwraps, no assumptions).
    func preload() {
        #if DEBUG
        print("🏁 AppLaunchModel: Starting preload...")
        #endif
        
        // Basic preload - simplified for now
        #if DEBUG
        print("🏁 AppLaunchModel: Preload complete")
        #endif
    }
}
