//
//  TopicDetailContent.swift
//  Synagamy3.0
//
//  Renders a single EducationTopic in a readable, sectioned layout.
//  • Matches EducationTopic model exactly:
//      - topic: String
//      - layExplanation: String
//      - expertSummary: String
//      - reference: [String]          ← note: singular property name in model
//      - relatedTo: [String]? (optional)
//      - category: String
//  • No force-unwraps; invalid URLs are shown as copyable text.
//  • Accessible headings; friendly defaults if arrays are empty.
//

import SwiftUI

struct TopicDetailContent: View {
    let topic: EducationTopic

    private let sectionSpacing: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {

            // TITLE / CATEGORY
            BrandCard(title: topic.topic, systemIcon: "book.fill") {
                Text(topic.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // LAY EXPLANATION
            if !topic.layExplanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                BrandCard(title: "What it means", systemIcon: "text.book.closed.fill") {
                    Text(topic.layExplanation)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }

            // EXPERT SUMMARY
            if !topic.expertSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                BrandCard(title: "In more detail", systemIcon: "brain.head.profile") {
                    Text(topic.expertSummary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }

            // RELATED TO (optional)
            if let related = topic.relatedTo, !related.isEmpty {
                BrandCard(title: "Related topics", systemIcon: "link") {
                    // Simple, readable bullet list; could be upgraded to tappable chips later
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(related, id: \.self) { item in
                            Text("• \(item)")
                        }
                    }
                }
            }

            // REFERENCES (array is named `reference` in the model)
            if !topic.reference.isEmpty {
                BrandCard(title: "References", systemIcon: "link.badge.plus") {
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
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
}
