//
//  ResourcesView.swift
//  Synagamy3.0
//
//  Simple Resources view for displaying fertility resources
//

import SwiftUI

struct ResourcesView: View {
    // MARK: - UI state
    @State private var selectedResource: Resource? = nil   // drives the detail sheet
    @State private var resources: [Resource] = []          // loaded from JSON
    @State private var isLoading = false
    @State private var dataSource: ResourceDataSource = .loading
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var networkManager = NetworkStatusManager.shared
    @StateObject private var remoteDataService = RemoteDataService.shared
    @StateObject private var offlineManager = OfflineDataManager.shared
    // Note: Using unified AppDataStore for data access

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "ResourcesLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            // Accessibility header
            Color.clear
                .accessibilityElement()
                .accessibilityLabel("Resources section")
                .accessibilityAddTraits(.isHeader)
                .frame(height: 0)
            VStack(alignment: .leading, spacing: 12) {
                // MARK: - Network Status Check
                if !networkManager.isOnline && resources.isEmpty {
                    ContentLoadingErrorView(
                        title: "Resources Unavailable",
                        message: "Resource information requires an internet connection to access the latest links and guidance."
                    ) {
                        Task { await loadResources() }
                    }
                    .padding(.top, Brand.Spacing.lg)
                    .fertilityAccessibility(
                        label: "Resources unavailable",
                        hint: "Internet connection required. Double tap to retry loading resources",
                        traits: [.isButton]
                    )
                } else if isLoading {
                    LoadingStateView(
                        message: "Loading resources...",
                        showProgress: true
                    )
                    .padding(.top, Brand.Spacing.lg)
                } else if resources.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No resources available",
                        message: "Please check back later. You can still explore Education and Pathways."
                    )
                    .padding(.top, Brand.Spacing.sm)
                    .fertilityAccessibility(
                        label: "No resources available",
                        value: "Please check back later. You can still explore Education and Pathways",
                        traits: [.isStaticText]
                    )
                } else {
                    LazyVStack(spacing: Brand.Spacing.xl) {
                        ForEach(resources, id: \.title) { resource in
                            Button {
                                // Validate URL before opening
                                if validateResourceURL(resource) {
                                    selectedResource = resource
                                    AccessibilityAnnouncement.announce("Opening \(resource.title) resource details")
                                } else {
                                    AccessibilityAnnouncement.announce("Unable to open \(resource.title). Invalid resource link.")
                                }
                            } label: {
                                BrandTile(
                                    title: resource.title,
                                    subtitle: resource.subtitle,
                                    systemIcon: resource.systemImage,
                                    isCompact: true
                                )
                            }
                            .buttonStyle(BrandTileButtonStyle())
                            .fertilityAccessibility(
                                label: "\(resource.title). \(resource.subtitle)",
                                hint: "Double tap to view details and access this fertility resource",
                                traits: [.isButton]
                            )
                        }
                    }
                    .onAppear {
                        AccessibilityAnnouncement.announce("Resources section loaded. \(resources.count) fertility resources available.")
                    }
                    .padding(.top, Brand.Spacing.xs)
                }
            }
        }
        
        .errorAlert(
            onRetry: {
                // Retry loading resources or refresh data
                validateAllResources()
            },
            onNavigateHome: {
                // Navigation handled by parent
            }
        )

        // Detail sheet (uses ResourceDetailSheet which already handles URL opening safely)
        .sheet(item: $selectedResource) { res in
            ResourceDetailSheet(resource: res)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .onAppear {
                    AccessibilityAnnouncement.announce("\(res.title) resource details opened")
                }
        }
        
        // Load resources from JSON on appear
        .task {
            await loadResources()
        }
        .onChange(of: dataSource) { _, newDataSource in
            // Update resources when data source changes
            resources = newDataSource.resources
        }
        .onDynamicTypeChange { size in
            // Handle dynamic type changes for better accessibility
            #if DEBUG
            print("ResourcesView: Dynamic Type size changed to \(size)")
            #endif
        }
    }
    
    // MARK: - Data Loading

    private func loadResources() async {
        isLoading = true
        dataSource = .loading

        // Load resources using RemoteDataService (handles all fallback internally)
        let loadedResources = await remoteDataService.loadResources()

        isLoading = false

        if !loadedResources.isEmpty {
            // Determine data source based on network status
            if networkManager.isOnline {
                dataSource = .remote(loadedResources)
            } else {
                dataSource = .offline(loadedResources)
            }
            resources = loadedResources
            validateAllResources()
        } else {
            dataSource = .error("No resource content available")
            resources = []
        }
    }

    // MARK: - Data Source Status View
    private var dataSourceStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: dataSource.icon)
                .font(.caption)
                .foregroundColor(dataSource.color)

            Text(dataSource.displayText)
                .font(Brand.Typography.labelSmall)
                .foregroundColor(.secondary)

            Spacer()

            if case .offline(_) = dataSource {
                Button("Refresh") {
                    Task { await loadResources() }
                }
                .font(Brand.Typography.labelSmall)
                .foregroundColor(Brand.Color.primary)
            }
        }
        .padding(.horizontal, Brand.Spacing.md)
        .padding(.vertical, Brand.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.sm)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.Radius.sm)
                        .stroke(dataSource.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - URL Validation
    
    private func validateResourceURL(_ resource: Resource) -> Bool {
        guard resource.url.scheme == "http" || resource.url.scheme == "https" else {
            let error = SynagamyError.urlInvalid(url: resource.url.absoluteString)
            errorHandler.handle(error)
            return false
        }
        
        guard resource.url.host != nil && !resource.url.host!.isEmpty else {
            let error = SynagamyError.urlInvalid(url: resource.url.absoluteString)
            errorHandler.handle(error)
            return false
        }
        
        return true
    }
    
    private func validateAllResources() {
        let invalidResources = resources.filter { resource in
            resource.url.scheme != "http" && resource.url.scheme != "https" ||
            resource.url.host?.isEmpty == true
        }
        
        if !invalidResources.isEmpty {
            let error = SynagamyError.dataValidationFailed(
                resource: "Resources",
                issues: invalidResources.map { "Invalid URL: \($0.title)" }
            )
            errorHandler.handle(error)
        }
    }
}
