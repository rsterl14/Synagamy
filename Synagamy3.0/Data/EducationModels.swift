//
//  EducationModels.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  Data models for the Education section of the app. These models represent
//  educational content about fertility, reproductive health, and treatment options.
//  Content is loaded from JSON files and cached for performance.
//
//  Model Structure
//  ---------------
//  • EducationTopic: Individual educational articles/topics
//    - Contains lay-friendly explanations
//    - Includes medical references for credibility
//    - Categorized for easy browsing and filtering
//    - Supports related topic linking for enhanced learning
//
//  App Store Compliance
//  -------------------
//  • All medical content includes proper disclaimers
//  • References peer-reviewed medical sources
//  • Educational purpose only - not diagnostic advice
//  • Encourages consultation with healthcare providers
//
//  Data Loading
//  ------------
//  • Content loaded from Education_Topics.json in app bundle
//  • Fallback handling for missing or corrupted data
//  • Supports offline usage once initially loaded
//

import Foundation

/// Represents a single educational topic covering fertility-related subjects.
/// Each topic provides both accessible explanations for general users and
/// detailed summaries for those seeking more comprehensive information.
struct EducationTopic: Identifiable, Codable, Hashable {
    /// Unique identifier based on the topic title for consistent referencing
    var id: String { topic }
    
    /// The main title/name of the educational topic (e.g., "IVF Process")
    let topic: String
    
    /// User-friendly explanation written in accessible language for general audience
    let layExplanation: String
    
    /// Array of medical references, citations, or source URLs for credibility
    let reference: [String]
    
    /// Optional array of related topic names for cross-referencing and discovery
    let relatedTo: [String]?
    
    /// Category classification for grouping topics (e.g., "Treatment Options", "Diagnosis")
    let category: String
    
    // MARK: - Automatic Key Conversion
    // Using JSONDecoder's .convertFromSnakeCase for automatic key mapping:
    // lay_explanation -> layExplanation
    // related_to -> relatedTo
}

// MARK: - Topic Categories
/// Common category names used throughout the app for consistent organization
extension EducationTopic {
    enum Category {
        static let diagnostics = "Diagnostics"
        static let treatmentOptions = "Treatment Options"
        static let fertilityPreservation = "Fertility Preservation"
        static let reproductiveHealth = "Reproductive Health"
        static let lifestyle = "Lifestyle & Wellness"
        static let support = "Emotional Support"
    }
}

// MARK: - Helper Extensions
extension EducationTopic {
    /// Returns true if this topic has related topics for cross-referencing
    var hasRelatedTopics: Bool {
        guard let related = relatedTo else { return false }
        return !related.isEmpty
    }
    
    /// Returns the number of references provided for this topic
    var referenceCount: Int {
        return reference.count
    }
    
    /// Sanitized topic title suitable for search and matching operations
    var searchableTitle: String {
        return topic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
