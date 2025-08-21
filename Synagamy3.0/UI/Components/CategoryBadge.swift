//
//  CategoryBadge.swift
//  Synagamy3.0
//
//  Reusable category badge component used throughout the app for consistent
//  category labeling with icons. Replaces duplicate badge implementations
//  in TopicDetailContent, CommonQuestionsView, ResourceDetailSheet, etc.
//

import SwiftUI

/// A reusable category badge with icon and text that maintains consistent styling
/// across all slide-ups and detail views in the app.
struct CategoryBadge: View {
    let text: String
    let icon: String
    let color: Color
    
    /// Creates a category badge with the app's primary color
    init(text: String, icon: String) {
        self.text = text
        self.icon = icon
        self.color = Brand.ColorSystem.primary
    }
    
    /// Creates a category badge with a custom color
    init(text: String, icon: String, color: Color) {
        self.text = text
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption2)
            
            Text(text.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.5)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        CategoryBadge(text: "Education", icon: "folder.fill")
        CategoryBadge(text: "Common Question", icon: "questionmark.circle.fill")
        CategoryBadge(text: "Resource", icon: "link.circle.fill")
        CategoryBadge(text: "Custom", icon: "star.fill", color: .orange)
    }
    .padding()
}