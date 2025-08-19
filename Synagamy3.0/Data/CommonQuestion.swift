//
//  CommonQuestion.swift
//  Synagamy2.0
//
//  Created by Reid Sterling on 2025-08-13.
//
// Data/Models/CommonQuestion.swift
import Foundation

/// Represents a common question with short and detailed answers.
struct CommonQuestion: Identifiable, Codable, Hashable {
    var id: String { question }

    let question: String
    let shortAnswer: String
    let detailedAnswer: String
    let tags: [String]
    let relatedTopics: [String]
    let reference: [String]
}

