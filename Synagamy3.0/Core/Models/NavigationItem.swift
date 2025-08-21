//
//  NavigationItem.swift
//  Synagamy3.0
//
//  Reusable navigation item models used throughout the app.
//

import Foundation

/// Generic navigation item that can be used across different features
protocol NavigationItem: Identifiable, Hashable {
    var title: String { get }
    var subtitle: String? { get }
    var systemIcon: String? { get }
    var assetIcon: String? { get }
    var accessibilityLabel: String { get }
}

/// Default implementation for NavigationItem
extension NavigationItem {
    var accessibilityLabel: String {
        let subtitleText = subtitle?.isEmpty == false ? ". \(subtitle!)" : ""
        return "\(title)\(subtitleText). Tap to open."
    }
}

/// Standard navigation item implementation
struct StandardNavigationItem: NavigationItem {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemIcon: String?
    let assetIcon: String?
    
    init(title: String, subtitle: String? = nil, systemIcon: String? = nil, assetIcon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.assetIcon = assetIcon
    }
}

/// Navigation item with associated route
struct RoutableNavigationItem<Route: Hashable>: NavigationItem {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemIcon: String?
    let assetIcon: String?
    let route: Route
    
    init(title: String, subtitle: String? = nil, systemIcon: String? = nil, assetIcon: String? = nil, route: Route) {
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.assetIcon = assetIcon
        self.route = route
    }
}

/// Navigation item with associated action
struct ActionableNavigationItem: NavigationItem {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemIcon: String?
    let assetIcon: String?
    let action: () -> Void
    
    init(title: String, subtitle: String? = nil, systemIcon: String? = nil, assetIcon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.assetIcon = assetIcon
        self.action = action
    }
    
    // Hashable conformance
    static func == (lhs: ActionableNavigationItem, rhs: ActionableNavigationItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}