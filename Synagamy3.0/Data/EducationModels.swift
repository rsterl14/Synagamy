//
//  EducationModels.swift
//  Synagamy2.0
//
//  Created by Reid Sterling on 2025-08-13.
//
// Data/Models/EducationModels.swift
import Foundation

/// Represents a single educational topic in the app.
struct EducationTopic: Identifiable, Codable, Hashable {
    var id: String { topic }  // Stable and unique based on topic title.

    let topic: String
    let layExplanation: String
    let expertSummary: String
    let reference: [String]
    let relatedTo: [String]?
    let category: String
}
