//
//  PathwayModels.swift
//  Synagamy3.0
//
//  Created by Reid Sterling on 2025-08-14.
//
// Data/Models/PathwayModels.swift
import Foundation

/// Root structure for pathway decision tree
struct PathwayData: Codable {
    let categories: [PathwayCategory]
    let paths: [PathwayPath]?  // All pathway definitions stored separately
}

/// Main category (Infertility Treatment or Fertility Preservation)
struct PathwayCategory: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let questions: [PathwayQuestion]?  // For questionnaire flow
    let paths: [PathwayPath]?          // Direct paths if no questions
}

/// Question node in the decision tree
struct PathwayQuestion: Identifiable, Codable, Hashable {
    let id: String
    let question: String
    let description: String?
    let options: [PathwayOption]
    
    enum CodingKeys: String, CodingKey {
        case id, question, description, options
    }
}

/// Option for a question
struct PathwayOption: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String?
    let nextQuestion: String?      // ID of next question (maps to next_question)
    let pathIds: [String]?         // IDs of resulting paths (maps to path_ids)
}

/// A specific pathway with steps
struct PathwayPath: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let suitableFor: String?    // Who this path is for (maps to suitable_for)
    let steps: [PathwayStep]
}

/// A single step within a pathway
struct PathwayStep: Codable, Hashable {
    let step: String
    let overview: String?
    let topicRefs: [String]  // Maps to topic_refs automatically
    
    // Back-compat alias
    var topic_refs: [String] { topicRefs }
}

/// User's pathway selection state
struct PathwaySelection {
    var category: PathwayCategory?
    var answers: [String: String] = [:]  // questionId: optionId
    var selectedPaths: [PathwayPath] = []
}

