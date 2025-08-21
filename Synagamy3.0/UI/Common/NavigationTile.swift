//
//  NavigationTile.swift
//  Synagamy3.0
//
//  A reusable navigation tile component that works with different
//  navigation item types and handles routing, actions, and accessibility.
//

import SwiftUI

/// Reusable navigation tile that works with any NavigationItem
struct NavigationTile<Item: NavigationItem>: View {
    let item: Item
    let isCompact: Bool
    
    init(item: Item, isCompact: Bool = false) {
        self.item = item
        self.isCompact = isCompact
    }
    
    var body: some View {
        BrandTile(
            title: item.title,
            subtitle: item.subtitle,
            systemIcon: item.systemIcon,
            assetIcon: item.assetIcon,
            isCompact: isCompact
        )
        .buttonStyle(BrandTileButtonStyle())
        .accessibilityLabel(Text(item.accessibilityLabel))
    }
}

/// Navigation tile that handles routing
struct RoutableNavigationTile<Route: Hashable>: View {
    let item: RoutableNavigationItem<Route>
    let isCompact: Bool
    
    init(item: RoutableNavigationItem<Route>, isCompact: Bool = false) {
        self.item = item
        self.isCompact = isCompact
    }
    
    var body: some View {
        NavigationLink(value: item.route) {
            NavigationTile(item: item, isCompact: isCompact)
        }
    }
}

/// Navigation tile that handles actions
struct ActionableNavigationTile: View {
    let item: ActionableNavigationItem
    let isCompact: Bool
    
    init(item: ActionableNavigationItem, isCompact: Bool = false) {
        self.item = item
        self.isCompact = isCompact
    }
    
    var body: some View {
        Button(action: item.action) {
            NavigationTile(item: item, isCompact: isCompact)
        }
    }
}

// MARK: - Preview

#Preview("Navigation Tile") {
    VStack(spacing: 20) {
        // Standard navigation tile
        NavigationTile(item: StandardNavigationItem(
            title: "Education",
            subtitle: "Learn about fertility",
            systemIcon: "book.fill"
        ))
        
        // Compact navigation tile
        NavigationTile(item: StandardNavigationItem(
            title: "Quick Access",
            subtitle: "Compact version",
            systemIcon: "star.fill"
        ), isCompact: true)
        
        // Actionable navigation tile
        ActionableNavigationTile(item: ActionableNavigationItem(
            title: "Tap Me",
            subtitle: "Performs an action",
            systemIcon: "hand.tap"
        ) {
            print("Action performed!")
        })
    }
    .padding()
}