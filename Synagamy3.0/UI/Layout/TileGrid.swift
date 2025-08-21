//
//  TileGrid.swift
//  Synagamy3.0
//
//  A reusable grid component for displaying BrandTiles with consistent
//  spacing and layout patterns.
//

import SwiftUI

/// Reusable tile grid with consistent spacing and styling
struct TileGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    // MARK: - Properties
    
    let data: Data
    let content: (Data.Element) -> Content
    let spacing: CGFloat
    let showEmptyState: Bool
    let emptyStateConfig: EmptyStateConfig?
    
    // MARK: - Initializers
    
    init(
        data: Data,
        spacing: CGFloat = Brand.Spacing.xl,
        showEmptyState: Bool = true,
        emptyStateConfig: EmptyStateConfig? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.spacing = spacing
        self.showEmptyState = showEmptyState
        self.emptyStateConfig = emptyStateConfig
    }
    
    // MARK: - Body
    
    var body: some View {
        if data.isEmpty && showEmptyState {
            let config = emptyStateConfig ?? EmptyStateConfig.defaultConfig
            EmptyStateView(
                icon: config.icon,
                title: config.title,
                message: config.message
            )
            .padding(.top, 24)
        } else {
            LazyVStack(spacing: spacing) {
                ForEach(data, id: \.id) { item in
                    content(item)
                }
            }
        }
    }
}

// MARK: - EmptyStateConfig

struct EmptyStateConfig {
    let icon: String
    let title: String
    let message: String
    
    static let defaultConfig = EmptyStateConfig(
        icon: "square.grid.2x2",
        title: "No items available",
        message: "Please check back later."
    )
    
    static let educationConfig = EmptyStateConfig(
        icon: "book",
        title: "No topics available",
        message: "Please check back later. You can still explore Pathways."
    )
    
    static let questionsConfig = EmptyStateConfig(
        icon: "questionmark.circle",
        title: "No questions yet",
        message: "Please check back later or explore Education topics."
    )
    
    static let pathwaysConfig = EmptyStateConfig(
        icon: "map",
        title: "No pathways available",
        message: "Please check back later or explore Education topics."
    )
}

// MARK: - Preview

#Preview {
    struct SampleItem: Identifiable {
        let id = UUID()
        let title: String
    }
    
    let sampleData = [
        SampleItem(title: "Item 1"),
        SampleItem(title: "Item 2"),
        SampleItem(title: "Item 3")
    ]
    
    return ScrollView {
        TileGrid(data: sampleData) { item in
            Text(item.title)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color("BrandPrimary").opacity(0.1))
                .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}