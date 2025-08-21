//
//  ResourcesView.swift
//  Synagamy3.0
//
//  Curated Canada-focused resources with a floating header and detail sheet.
//  This refactor:
//   • Uses the shared OnChangeHeightModifier (no file-local duplicates).
//   • Adds friendly empty-state handling if the list is ever empty.
//   • Improves a11y labels and avoids force-unwrap pitfalls.
//   • Keeps sheet presentation safe (no crashes on odd state).
//
//  Prereqs:
//   • UI/Modifiers/OnChangeHeightModifier.swift
//   • UI/Components/{BrandTile,BrandCard,EmptyStateView,HomeButton,FloatingLogoHeader}.swift
//   • Features/Resources/ResourceDetailSheet.swift
//

import SwiftUI

struct ResourcesView: View {
    // MARK: - UI state
    @State private var selectedResource: Resource? = nil   // drives the detail sheet
    @State private var resources: [Resource] = []          // loaded from JSON
    @StateObject private var errorHandler = ErrorHandler.shared
    // Note: DataCache will be injected via environment when available

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "ResourcesLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if resources.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No resources available",
                        message: "Please check back later. You can still explore Education and Pathways."
                    )
                    .padding(.top, 8)
                } else {
                    LazyVStack(spacing: Brand.Spacing.xl) {
                        ForEach(resources, id: \.title) { resource in
                            Button {
                                // Validate URL before opening
                                if validateResourceURL(resource) {
                                    selectedResource = resource
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
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        
        // Centralized error handling
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
        }
        
        // Load resources from JSON on appear
        .task {
            loadResources()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadResources() {
        // Load resources from JSON (will be optimized with cache when integrated)
        resources = Resource.loadFromJSON()
        validateAllResources()
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
