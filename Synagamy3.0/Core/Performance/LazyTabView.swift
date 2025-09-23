//
//  LazyTabView.swift
//  Synagamy3.0
//
//  Lazy-loading tab view system that only initializes tabs when first accessed.
//  Significantly reduces memory usage and improves app launch performance.
//
//  Features:
//  - Lazy tab content loading
//  - Memory pressure handling
//  - Tab state preservation
//  - Performance monitoring
//

import SwiftUI
import Combine

// MARK: - Lazy Tab View

struct LazyTabView<SelectionValue>: View where SelectionValue: Hashable {
    @Binding private var selection: SelectionValue
    private let tabs: [LazyTab<SelectionValue>]

    @State private var loadedTabs: Set<SelectionValue> = []
    @State private var isLowMemoryMode = false

    @Environment(\.appEnvironment) private var appEnvironment

    init(selection: Binding<SelectionValue>, @LazyTabBuilder<SelectionValue> content: () -> [LazyTab<SelectionValue>]) {
        self._selection = selection
        self.tabs = content()
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs, id: \.tag) { tab in
                Group {
                    if loadedTabs.contains(tab.tag) {
                        // Tab is loaded, show content
                        NavigationStack(path: .constant(NavigationPath())) {
                            tab.content()
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbarBackground(.hidden, for: .navigationBar)
                                .trackPerformance(viewName: tab.title)
                        }
                    } else {
                        // Tab not loaded yet, show placeholder
                        LazyTabPlaceholder(title: tab.title, icon: tab.icon)
                            .trackPerformance(viewName: "\(tab.title)_Placeholder")
                    }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab.tag)
                .accessibilityLabel(Text(tab.accessibilityLabel))
            }
        }
        .onChange(of: selection) { _, newSelection in
            loadTabIfNeeded(newSelection)
        }
        .onAppear {
            // Always load the initial tab
            loadTabIfNeeded(selection)
        }
        .onReceive(NotificationCenter.default.publisher(for: .lowMemoryMode)) { _ in
            handleLowMemoryMode()
        }
        .tint(Color("BrandPrimary"))
    }

    private func loadTabIfNeeded(_ tabTag: SelectionValue) {
        guard !loadedTabs.contains(tabTag) else { return }

        // In low memory mode, only load essential tabs
        if isLowMemoryMode {
            let tab = tabs.first { $0.tag == tabTag }
            guard tab?.isEssential == true else { return }
        }

        loadedTabs.insert(tabTag)

        #if DEBUG
        let tabName = tabs.first { $0.tag == tabTag }?.title ?? "Unknown"
        print("🚀 LazyTabView: Loaded tab '\(tabName)' (\(loadedTabs.count)/\(tabs.count) loaded)")
        #endif
    }

    private func handleLowMemoryMode() {
        isLowMemoryMode = true

        // Unload non-essential tabs in low memory mode
        let currentSelection = selection
        loadedTabs = loadedTabs.filter { tabTag in
            let tab = tabs.first { $0.tag == tabTag }
            return tab?.isEssential == true || tabTag == currentSelection
        }

        #if DEBUG
        print("🧹 LazyTabView: Low memory mode - kept \(loadedTabs.count)/\(tabs.count) tabs")
        #endif
    }
}

// MARK: - Lazy Tab

struct LazyTab<SelectionValue: Hashable> {
    let tag: SelectionValue
    let title: String
    let icon: String
    let accessibilityLabel: String
    let isEssential: Bool
    let content: () -> AnyView

    init<Content: View>(
        tag: SelectionValue,
        title: String,
        icon: String,
        accessibilityLabel: String? = nil,
        isEssential: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tag = tag
        self.title = title
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel ?? title
        self.isEssential = isEssential
        self.content = { AnyView(content()) }
    }
}

// MARK: - Tab Placeholder

struct LazyTabPlaceholder: View {
    let title: String
    let icon: String

    @Environment(\.appEnvironment) private var appEnvironment

    var body: some View {
        VStack(spacing: 20) {
            // Loading indicator
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.primary)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)

                Text("Loading \(title)...")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Preparing content for you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Performance info in debug mode
            #if DEBUG
            if appEnvironment.isLowMemoryMode {
                Text("⚡ Low Memory Mode")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.orange.opacity(0.1))
                    )
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

// MARK: - Tab Builder

@resultBuilder
struct LazyTabBuilder<SelectionValue: Hashable> {
    static func buildBlock(_ components: LazyTab<SelectionValue>...) -> [LazyTab<SelectionValue>] {
        components
    }
}

// MARK: - Enhanced MainTabView

struct OptimizedMainTabView: View {
    // MARK: - Tab enumeration for type-safe selection
    enum Tab: Hashable, CaseIterable {
        case home, education, pathways, clinics, predictor, resources, questions

        var title: String {
            switch self {
            case .home: return "Home"
            case .education: return "Education"
            case .pathways: return "Pathways"
            case .clinics: return "Clinics"
            case .predictor: return "Predictor"
            case .resources: return "Resources"
            case .questions: return "Questions"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .education: return "book.fill"
            case .pathways: return "map.fill"
            case .clinics: return "building.2.fill"
            case .predictor: return "chart.line.uptrend.xyaxis"
            case .resources: return "doc.text.fill"
            case .questions: return "questionmark.bubble.fill"
            }
        }

        var isEssential: Bool {
            switch self {
            case .home, .education: return true  // Essential tabs always loaded
            default: return false  // Non-essential tabs loaded on demand
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .home: return "Home"
            case .education: return "Education"
            case .pathways: return "Pathways"
            case .clinics: return "Clinics"
            case .predictor: return "Outcome Predictor"
            case .resources: return "Resources"
            case .questions: return "Common Questions"
            }
        }
    }

    @State private var selectedTab: Tab = .home
    @Environment(\.appEnvironment) private var appEnvironment

    var body: some View {
        LazyTabView(selection: $selectedTab) {
            LazyTab(
                tag: Tab.home,
                title: Tab.home.title,
                icon: Tab.home.icon,
                accessibilityLabel: Tab.home.accessibilityLabel,
                isEssential: Tab.home.isEssential
            ) {
                HomeView()
            }

            LazyTab(
                tag: Tab.education,
                title: Tab.education.title,
                icon: Tab.education.icon,
                accessibilityLabel: Tab.education.accessibilityLabel,
                isEssential: Tab.education.isEssential
            ) {
                EducationView()
            }

            LazyTab(
                tag: Tab.pathways,
                title: Tab.pathways.title,
                icon: Tab.pathways.icon,
                accessibilityLabel: Tab.pathways.accessibilityLabel,
                isEssential: Tab.pathways.isEssential
            ) {
                PathwayView()
            }

            LazyTab(
                tag: Tab.clinics,
                title: Tab.clinics.title,
                icon: Tab.clinics.icon,
                accessibilityLabel: Tab.clinics.accessibilityLabel,
                isEssential: Tab.clinics.isEssential
            ) {
                ClinicFinderView()
            }

            LazyTab(
                tag: Tab.predictor,
                title: Tab.predictor.title,
                icon: Tab.predictor.icon,
                accessibilityLabel: Tab.predictor.accessibilityLabel,
                isEssential: Tab.predictor.isEssential
            ) {
                OutcomePredictorView()
            }

            LazyTab(
                tag: Tab.resources,
                title: Tab.resources.title,
                icon: Tab.resources.icon,
                accessibilityLabel: Tab.resources.accessibilityLabel,
                isEssential: Tab.resources.isEssential
            ) {
                ResourcesView()
            }

            LazyTab(
                tag: Tab.questions,
                title: Tab.questions.title,
                icon: Tab.questions.icon,
                accessibilityLabel: Tab.questions.accessibilityLabel,
                isEssential: Tab.questions.isEssential
            ) {
                CommonQuestionsView()
            }
        }
        .unifiedErrorHandling(
            viewContext: "MainTabView",
            onRetry: {
                // Perform health check or reload data
                await performHealthCheck()
            },
            onNavigateHome: {
                // Navigate to home tab
                selectedTab = .home
            }
        )
        .environmentObject(appEnvironment)
    }

    private func performHealthCheck() async {
        // Health check implementation
        await appEnvironment.networkManager.checkConnectivity()
    }
}

// MARK: - Performance Extensions

extension LazyTabView {
    /// Get performance metrics for debugging
    func getPerformanceMetrics() -> TabPerformanceMetrics {
        TabPerformanceMetrics(
            totalTabs: tabs.count,
            loadedTabs: loadedTabs.count,
            memoryOptimized: isLowMemoryMode,
            currentSelection: selection
        )
    }
}

struct TabPerformanceMetrics {
    let totalTabs: Int
    let loadedTabs: Int
    let memoryOptimized: Bool
    let currentSelection: Any

    var loadingPercentage: Double {
        guard totalTabs > 0 else { return 0 }
        return Double(loadedTabs) / Double(totalTabs) * 100
    }
}