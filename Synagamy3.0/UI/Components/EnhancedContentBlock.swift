//
//  EnhancedContentBlock.swift
//  Synagamy3.0
//
//  Reusable content block component with ultra-thin material background
//  and consistent styling. Replaces repeated content block patterns
//  throughout TopicDetailContent, CommonQuestionsView, and other views.
//

import SwiftUI

/// A reusable content block with optional title/icon header and ultra-thin material styling
/// that maintains consistent visual design across all content sections in the app.
struct EnhancedContentBlock<Content: View>: View {
    let title: String?
    let icon: String?
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    /// Creates a content block with title and icon header
    init(title: String, icon: String, spacing: CGFloat = 10, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.spacing = spacing
        self.content = content
    }
    
    /// Creates a content block without header (content only)
    init(spacing: CGFloat = 10, @ViewBuilder content: @escaping () -> Content) {
        self.title = nil
        self.icon = nil
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Optional header with icon and title
            if let title = title, let icon = icon {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(Brand.ColorSystem.primary)
                    
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Brand.ColorSystem.primary)
                }
            }
            
            // Content with enhanced styling
            content()
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Brand.ColorToken.hairline, lineWidth: 1)
                        )
                )
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // With header
            EnhancedContentBlock(title: "About This Topic", icon: "lightbulb.fill") {
                Text("This is some content inside an enhanced content block with a header and icon.")
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
            
            // Without header
            EnhancedContentBlock {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content without header")
                        .font(.headline)
                    Text("This content block doesn't have a header, just the enhanced styling.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            
            // Complex content
            EnhancedContentBlock(title: "Related Information", icon: "link.circle.fill") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(["Item 1", "Item 2", "Item 3"], id: \.self) { item in
                        HStack {
                            Circle()
                                .fill(Brand.ColorSystem.primary)
                                .frame(width: 4, height: 4)
                            Text(item)
                                .font(.callout)
                        }
                    }
                }
            }
        }
        .padding()
    }
}