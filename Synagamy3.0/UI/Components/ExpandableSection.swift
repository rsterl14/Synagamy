//
//  ExpandableSection.swift
//  Synagamy3.0
//
//  Reusable expandable section component used for references, related topics,
//  and other collapsible content throughout the app. Provides consistent
//  animation and styling for all expandable sections.
//

import SwiftUI

/// A reusable expandable section with animated chevron and consistent styling
/// used for references, related topics, and other collapsible content.
struct ExpandableSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    /// Creates an expandable section with title only
    init(title: String, icon: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = nil
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content
    }
    
    /// Creates an expandable section with title and subtitle (e.g., "3 sources")
    init(title: String, subtitle: String, icon: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Expandable header button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Brand.ColorSystem.secondary.opacity(0.2), Brand.ColorSystem.secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: icon)
                                .font(.caption)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        )
                    
                    if let subtitle = subtitle {
                        // Title with subtitle layout (like references with count)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Brand.ColorSystem.primary)
                            
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                    } else {
                        // Simple title only layout
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Brand.ColorSystem.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.body)
                        .foregroundStyle(Brand.ColorSystem.secondary)
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.primary.opacity(0.02), Color.primary.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Brand.ColorToken.hairline.opacity(0.6), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                content()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity
                    ))
            }
        }
    }
}

#Preview {
    @State var showReferences = false
    @State var showRelated = false
    
    return ScrollView {
        VStack(spacing: 20) {
            // References style with count
            ExpandableSection(
                title: "References", 
                subtitle: "3 sources",
                icon: "doc.text.magnifyingglass",
                isExpanded: $showReferences
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(["Source 1", "Source 2", "Source 3"], id: \.self) { source in
                        Text(source)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }
                }
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
            
            // Simple expandable section
            ExpandableSection(
                title: "Related Topics",
                icon: "link.circle.fill",
                isExpanded: $showRelated
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(["Topic 1", "Topic 2"], id: \.self) { topic in
                        Text(topic)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }
                }
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
        .padding()
    }
}