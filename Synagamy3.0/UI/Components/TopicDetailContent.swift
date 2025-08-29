//
//  TopicDetailContent.swift
//  Synagamy3.0
//
//  Renders a single EducationTopic in a readable, sectioned layout.
//

import SwiftUI

struct TopicDetailContent: View {
    let topic: EducationTopic
    @Binding var selectedTopic: EducationTopic?
    
    @State private var showReferences = false
    @State private var expandedRelatedTopics: Set<String> = []
    
    init(topic: EducationTopic, selectedTopic: Binding<EducationTopic?> = .constant(nil)) {
        self.topic = topic
        self._selectedTopic = selectedTopic
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // TITLE / CATEGORY Header
            VStack(alignment: .leading, spacing: 12) {
                // Category badge
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.caption2)
                    
                    Text(topic.category.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                }
                .foregroundColor(Brand.ColorSystem.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Brand.ColorSystem.primary.opacity(0.12))
                        .overlay(
                            Capsule()
                                .strokeBorder(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Main title with gradient
                Text(topic.topic)
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Brand.ColorSystem.primary, Brand.ColorSystem.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 4)
            
            // Divider
            Rectangle()
                .fill(LinearGradient(
                    colors: [Brand.ColorSystem.primary.opacity(0.3), Brand.ColorSystem.primary.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.bottom, 4)

            // LAY EXPLANATION with enhanced design
            if !topic.layExplanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.body)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Simple Explanation")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Brand.ColorSystem.primary)
                    }
                    
                    Text(topic.layExplanation)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Brand.ColorToken.hairline, Brand.ColorToken.hairline.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                }
            }

            // EXPERT SUMMARY with enhanced design
            if !topic.expertSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.body)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Brand.ColorSystem.primary, Brand.ColorSystem.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Detailed Explanation")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Brand.ColorSystem.primary)
                    }
                    
                    Text(topic.expertSummary)
                        .font(.callout)
                        .foregroundColor(.primary.opacity(0.9))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
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

            // RELATED TO (optional) with enhanced design
            if let related = topic.relatedTo, !related.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "link.circle.fill")
                            .font(.body)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Brand.ColorSystem.primary, Brand.ColorSystem.primary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Related Topics")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Brand.ColorSystem.primary)
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(related, id: \.self) { item in
                            VStack(alignment: .leading, spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        if expandedRelatedTopics.contains(item) {
                                            expandedRelatedTopics.remove(item)
                                        } else {
                                            expandedRelatedTopics.insert(item)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Brand.ColorSystem.primary.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Image(systemName: "arrow.turn.down.right")
                                                    .font(.caption)
                                                    .foregroundColor(Brand.ColorSystem.primary)
                                            )
                                        
                                        Text(item)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: expandedRelatedTopics.contains(item) ? "chevron.up.circle.fill" : "chevron.down.circle")
                                            .font(.body)
                                            .foregroundStyle(Brand.ColorSystem.primary)
                                            .animation(.spring(response: 0.3), value: expandedRelatedTopics.contains(item))
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.primary.opacity(0.03), Color.primary.opacity(0.06)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(Brand.ColorToken.hairline.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // Expanded content with enhanced styling
                                if expandedRelatedTopics.contains(item) {
                                    if let relatedTopic = AppData.topics.first(where: { $0.topic == item }) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(relatedTopic.layExplanation)
                                                .font(.callout)
                                                .foregroundColor(.primary.opacity(0.8))
                                                .lineSpacing(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Color.primary.opacity(0.02))
                                                )
                                            
                                            Button {
                                                selectedTopic = relatedTopic
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Text("View Topic Details")
                                                        .font(.subheadline.weight(.medium))
                                                    Image(systemName: "arrow.right.circle.fill")
                                                        .font(.subheadline)
                                                }
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Brand.ColorSystem.primary)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.top, 8)
                                        .padding(.horizontal, 12)
                                        .padding(.bottom, 8)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // REFERENCES (collapsible) with enhanced design
            if !topic.reference.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showReferences.toggle()
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
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.caption)
                                    .foregroundColor(Brand.ColorSystem.secondary)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("References")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Brand.ColorSystem.primary)
                            
                            Text("\(topic.reference.count) source\(topic.reference.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(Brand.ColorSystem.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: showReferences ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.body)
                            .foregroundStyle(Brand.ColorSystem.secondary)
                            .animation(.spring(response: 0.3), value: showReferences)
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
                
                if showReferences {
                    BrandCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(topic.reference, id: \.self) { ref in
                                let trimmed = ref.trimmingCharacters(in: .whitespacesAndNewlines)
                                if let url = URL(string: trimmed), !trimmed.isEmpty {
                                    Link(trimmed, destination: url)
                                        .font(.footnote)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } else if !trimmed.isEmpty {
                                    Text(trimmed)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
}
