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

struct MainTabView: View {
    // MARK: - Tab enumeration for type-safe selection & testability
    enum Tab: Hashable {
        case home, education, pathways, clinics, resources, questions, community
    }

    // MARK: - UI state
    @State private var selectedTab: Tab = .home
    @State private var errorMessage: String? = nil   // user-facing, non-technical alert text

    // MARK: - Per-tab navigation paths (so each tab keeps its own history)
    @State private var homePath = NavigationPath()
    @State private var educationPath = NavigationPath()
    @State private var pathwaysPath = NavigationPath()
    @State private var clinicsPath = NavigationPath()
    @State private var resourcesPath = NavigationPath()
    @State private var questionsPath = NavigationPath()
    @State private var communityPath = NavigationPath()
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
                EducationView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Education", systemImage: "book.fill") }
            .tag(Tab.education)
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

            // COMMUNITY
            NavigationStack(path: $communityPath) {
                CommunityView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Community", systemImage: "person.3.fill") }
            .tag(Tab.community)
            .accessibilityLabel(Text("Community"))
        }
        // Global tint/brand color for selected tab & prominent buttons
        .tint(Color("BrandPrimary"))

        // Friendly, non-technical alert that you can reuse for recoverable issues
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Example defensive hook: if something in your environment indicates a bad state,
        // you can surface it here without crashing UI (kept idle by default).
        .task {
            // Leave this empty or wire to a lightweight health check if you add one later.
            // If a problem is detected, set `errorMessage = "…"`.
        }
    }
}
