//
//  MainTabView.swift
//  Synagamy3.0
//
//  Root tab container for the app. Each tab owns its own NavigationStack so deep pushes
//  in one tab don’t affect the others. This version:
//   • Adds a Tab enum for type-safe selection.
//   • Uses one NavigationStack per tab (App Store–friendly navigation).
//   • Includes a small error/alert scaffold (non-technical).
//   • Centralizes tab labels/SF Symbols and keeps accessibility clear.
//   • Avoids force-unwraps and fragile state.
//
//  Prereqs:
//   • All Feature root views exist (HomeView, EducationView, PathwayView, ClinicFinderView,
//     ResourcesView, CommonQuestionsView, CommunityView).
//

import SwiftUI
import Foundation

struct MainTabView: View {
    // MARK: - Tab enumeration for type-safe selection & testability
    enum Tab: Hashable {
        case home, education, pathways, clinics, predictor, resources, questions
    }

    // MARK: - UI state
    @State private var selectedTab: Tab = .home
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var networkManager = NetworkStatusManager.shared

    // MARK: - Per-tab navigation paths (so each tab keeps its own history)
    @State private var homePath = NavigationPath()
    @State private var educationPath = NavigationPath()
    @State private var pathwaysPath = NavigationPath()
    @State private var clinicsPath = NavigationPath()
    @State private var resourcesPath = NavigationPath()
    @State private var questionsPath = NavigationPath()
    @State private var outcomePath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {

            // HOME
            NavigationStack(path: $homePath) {
                HomeView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)
            .accessibilityLabel(Text("Home"))

            // EDUCATION
            NavigationStack(path: $educationPath) {
                EducationView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Education", systemImage: "book.fill") }
            .tag(Tab.education)
            .accessibilityLabel(Text("Education"))

            // PATHWAYS
            NavigationStack(path: $pathwaysPath) {
                PathwayView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Pathways", systemImage: "map.fill") }
            .tag(Tab.pathways)
            .accessibilityLabel(Text("Pathways"))

            // CLINICS
            NavigationStack(path: $clinicsPath) {
                ClinicFinderView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Clinics", systemImage: "building.2.fill") }
            .tag(Tab.clinics)
            .accessibilityLabel(Text("Clinics"))
            
            NavigationStack(path: $outcomePath) {
                OutcomePredictorView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Predictor", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(Tab.predictor)
            .accessibilityLabel(Text("Outcome Predictor"))

            // RESOURCES
            NavigationStack(path: $resourcesPath) {
                ResourcesView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Resources", systemImage: "doc.text.fill") }
            .tag(Tab.resources)
            .accessibilityLabel(Text("Resources"))

            // QUESTIONS
            NavigationStack(path: $questionsPath) {
                CommonQuestionsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Questions", systemImage: "questionmark.bubble.fill") }
            .tag(Tab.questions)
            .accessibilityLabel(Text("Common Questions"))
        }
        // Global tint/brand color for selected tab & prominent buttons
        .tint(Color("BrandPrimary"))

        // Centralized error handling with recovery actions
        .errorAlert(
            onRetry: {
                // Perform health check or reload data
                performHealthCheck()
            },
            onNavigateHome: {
                // Navigate to home tab
                selectedTab = .home
                // Clear all navigation paths
                homePath = NavigationPath()
                educationPath = NavigationPath()
                pathwaysPath = NavigationPath()
                clinicsPath = NavigationPath()
                resourcesPath = NavigationPath()
                questionsPath = NavigationPath()
                outcomePath = NavigationPath()
            }
        )

        // Health check and error detection
        .task {
            // Delay health check to avoid publishing during view updates
            do {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } catch {
                // If sleep is cancelled, continue anyway
            }
            await MainActor.run {
                performHealthCheck()
            }
        }
        .networkAware()
        
        // Listen for home button notifications
        .onReceive(NotificationCenter.default.publisher(for: .goHome)) { _ in
            handleGoHome()
        }
    }
    
    // MARK: - Health Check
    
    private func performHealthCheck() {
        // Check if core data is available
        let topics = AppData.topics
        let pathwayCategories = AppData.pathwayCategories
        let questions = AppData.questions
        
        // Be more lenient during startup - data might still be loading
        // Only show critical errors if ALL data is missing after a delay
        if topics.isEmpty && pathwayCategories.isEmpty && questions.isEmpty {
            // Give remote data loading more time before showing error
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                let updatedTopics = AppData.topics
                let updatedPathways = AppData.pathwayCategories  
                let updatedQuestions = AppData.questions
                
                // Only show error if still no data after waiting
                if updatedTopics.isEmpty && updatedPathways.isEmpty && updatedQuestions.isEmpty {
                    let error = SynagamyError.dataLoadFailed(
                        resource: "core content", 
                        underlying: nil
                    )
                    self.errorHandler.handleSilently(error) // Handle silently to avoid popup
                }
            }
            return
        }
        
        // For partial data loss, just log silently - don't show error popup
        var missingContent: [String] = []
        if topics.isEmpty { missingContent.append("education topics") }
        if pathwayCategories.isEmpty { missingContent.append("pathways") }
        if questions.isEmpty { missingContent.append("questions") }
        
        if !missingContent.isEmpty {
            let error = SynagamyError.contentEmpty(section: missingContent.joined(separator: ", "))
            errorHandler.handleSilently(error) // Handle silently to avoid startup popup
        }
    }
    
    // MARK: - Navigation Helper
    
    private func clearAllNavigationPaths() {
        homePath = NavigationPath()
        educationPath = NavigationPath()
        pathwaysPath = NavigationPath()
        clinicsPath = NavigationPath()
        resourcesPath = NavigationPath()
        questionsPath = NavigationPath()
        outcomePath = NavigationPath()
    }

    // MARK: - Performance Optimized Home Navigation

    @State private var homeNavigationTask: Task<Void, Never>?

    private func handleGoHome() {
        // Cancel any pending navigation
        homeNavigationTask?.cancel()

        // Debounce with a simple Task delay
        homeNavigationTask = Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms debounce

            if !Task.isCancelled {
                await MainActor.run {
                    performOptimizedHomeNavigation()
                }
            }
        }
    }

    private func performOptimizedHomeNavigation() {
        // Immediately switch tab with fast animation
        withAnimation(.easeOut(duration: 0.15)) {
            selectedTab = .home
        }

        // Clear navigation paths asynchronously to prevent blocking
        Task {
            await clearNavigationPathsAsync()
        }
    }

    private func clearNavigationPathsAsync() async {
        await MainActor.run {
            // Clear paths in smaller batches to reduce frame drops
            homePath = NavigationPath()
            educationPath = NavigationPath()
        }

        // Small delay to prevent blocking
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

        await MainActor.run {
            pathwaysPath = NavigationPath()
            clinicsPath = NavigationPath()
        }

        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

        await MainActor.run {
            resourcesPath = NavigationPath()
            questionsPath = NavigationPath()
            outcomePath = NavigationPath()
        }
    }
}
