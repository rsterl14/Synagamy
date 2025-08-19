//
//  PathwayModels.swift
//  Synagamy3.0
//
//  Created by Reid Sterling on 2025-08-14.
//
// Data/Models/PathwayModels.swift
import Foundation

/// A category of pathways (e.g., Infertility Treatment, Fertility Preservation).
struct PathwayCategory: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let paths: [PathwayPath]
}

/// A specific pathway within a category (e.g., IUI with Partner Sperm).
struct PathwayPath: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let steps: [PathwayStep]
}

/// A single step within a pathway.
struct PathwayStep: Codable, Hashable {
    let step: String
    let overview: String?            // ← NEW: short description from JSON ("overview")
    let topicRefs: [String]          // JSON key "topic_refs" → convertFromSnakeCase handles this

    // Back-compat alias for existing call sites using `topic_refs`
    var topic_refs: [String] { topicRefs }
}

