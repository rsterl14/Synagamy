//
//  PersonalizedCycleManager.swift
//  Synagamy3.0
//
//  Manages saving, loading, and displaying personalized fertility cycles
//  with custom learning experiences organized by pathway steps.
//

import Foundation
import SwiftUI

// MARK: - Saved Cycle Data Models

struct QuestionAnswer: Codable {
    let questionId: String
    let questionText: String
    let selectedOptionId: String
    let selectedOptionText: String
}

struct SavedCycle: Identifiable, Codable {
    let id: String
    let name: String
    let pathway: PathwayPath
    let dateCreated: Date
    let lastAccessed: Date
    let questionsAndAnswers: [QuestionAnswer]
    let category: String
    
    var formattedDateCreated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateCreated)
    }
    
    var daysSinceCreated: Int {
        Calendar.current.dateComponents([.day], from: dateCreated, to: Date()).day ?? 0
    }
}

struct StepWithTopics: Identifiable {
    let id: String
    let step: PathwayStep
    let matchedTopics: [EducationTopic]
}

// MARK: - Cycle Manager

@MainActor
class PersonalizedCycleManager: ObservableObject {
    @Published var savedCycles: [SavedCycle] = []
    
    private let userDefaults = UserDefaults.standard
    private let savedCyclesKey = "SavedFertilityCycles"
    
    init() {
        loadSavedCycles()
    }
    
    // MARK: - Save/Load Operations
    
    func saveCycle(
        name: String,
        pathway: PathwayPath,
        questionsAndAnswers: [QuestionAnswer],
        category: String
    ) {
        let newCycle = SavedCycle(
            id: UUID().uuidString,
            name: name,
            pathway: pathway,
            dateCreated: Date(),
            lastAccessed: Date(),
            questionsAndAnswers: questionsAndAnswers,
            category: category
        )
        
        savedCycles.insert(newCycle, at: 0) // Add to beginning
        persistCycles()
    }
    
    func updateLastAccessed(for cycleId: String) {
        if let index = savedCycles.firstIndex(where: { $0.id == cycleId }) {
            let updatedCycle = savedCycles[index]
            savedCycles[index] = SavedCycle(
                id: updatedCycle.id,
                name: updatedCycle.name,
                pathway: updatedCycle.pathway,
                dateCreated: updatedCycle.dateCreated,
                lastAccessed: Date(),
                questionsAndAnswers: updatedCycle.questionsAndAnswers,
                category: updatedCycle.category
            )
            persistCycles()
        }
    }
    
    func deleteCycle(_ cycle: SavedCycle) {
        savedCycles.removeAll { $0.id == cycle.id }
        persistCycles()
    }
    
    func renameCycle(_ cycle: SavedCycle, newName: String) {
        if let index = savedCycles.firstIndex(where: { $0.id == cycle.id }) {
            let updatedCycle = savedCycles[index]
            savedCycles[index] = SavedCycle(
                id: updatedCycle.id,
                name: newName,
                pathway: updatedCycle.pathway,
                dateCreated: updatedCycle.dateCreated,
                lastAccessed: updatedCycle.lastAccessed,
                questionsAndAnswers: updatedCycle.questionsAndAnswers,
                category: updatedCycle.category
            )
            persistCycles()
        }
    }
    
    // MARK: - Learning Experience Helpers
    
    func getStepsWithTopics(for cycle: SavedCycle) -> [StepWithTopics] {
        let educationTopics = AppData.topics
        
        return cycle.pathway.steps.enumerated().map { index, step in
            let topicIndex = TopicMatcher.index(topics: educationTopics)
            let matchedTopics = TopicMatcher.match(stepRefs: step.topicRefs, index: topicIndex)
            
            return StepWithTopics(
                id: "\(cycle.id)_step_\(index)",
                step: step,
                matchedTopics: matchedTopics
            )
        }
    }
    
    // MARK: - Persistence
    
    private func persistCycles() {
        do {
            let encoded = try JSONEncoder().encode(savedCycles)
            userDefaults.set(encoded, forKey: savedCyclesKey)
        } catch {
            #if DEBUG
            print("Failed to save cycles: \(error)")
            #endif
        }
    }
    
    private func loadSavedCycles() {
        guard let data = userDefaults.data(forKey: savedCyclesKey) else { return }
        
        do {
            savedCycles = try JSONDecoder().decode([SavedCycle].self, from: data)
        } catch {
            #if DEBUG
            print("Failed to load saved cycles: \(error)")
            #endif
            savedCycles = []
        }
    }
}

