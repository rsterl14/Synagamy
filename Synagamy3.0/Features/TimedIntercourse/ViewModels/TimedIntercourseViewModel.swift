//
//  TimedIntercourseViewModel.swift
//  Synagamy3.0
//
//  ViewModel for managing timed intercourse data and calculations.
//

import SwiftUI
import Foundation

@MainActor
class TimedIntercourseViewModel: ObservableObject {
    @Published var currentCycle: MenstrualCycle?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Computed properties
    var hasCurrentCycle: Bool {
        currentCycle != nil
    }
    
    var cyclePhaseDescription: String {
        guard let cycle = currentCycle else { return "" }
        let status = FertilityCalculator.fertilityStatus(for: cycle)
        return status.title
    }
    
    var currentFertilityStatus: FertilityStatus? {
        guard let cycle = currentCycle else { return nil }
        return FertilityCalculator.fertilityStatus(for: cycle)
    }
    
    var currentFertilityWindow: FertilityWindow? {
        guard let cycle = currentCycle else { return nil }
        return FertilityWindow(cycle: cycle)
    }
    
    var currentRecommendations: [IntercourseTiming] {
        guard let cycle = currentCycle else { return [] }
        return FertilityCalculator.recommendations(for: cycle)
    }
    
    init() {
        loadSavedCycle()
    }
    
    // MARK: - Public Methods
    
    func updateCycle(lastPeriodDate: Date, averageLength: Int, periodLength: Int) {
        let newCycle = MenstrualCycle(
            lastPeriodDate: lastPeriodDate,
            averageLength: averageLength,
            periodLength: periodLength
        )
        
        currentCycle = newCycle
        saveCycle()
    }
    
    func clearCycle() {
        currentCycle = nil
        UserDefaults.standard.removeObject(forKey: "SavedMenstrualCycle")
    }
    
    // MARK: - Private Methods
    
    private func loadSavedCycle() {
        guard let data = UserDefaults.standard.data(forKey: "SavedMenstrualCycle"),
              let cycle = try? JSONDecoder().decode(MenstrualCycle.self, from: data) else {
            return
        }
        
        // Check if saved cycle is still relevant (not older than 45 days)
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: cycle.lastPeriodDate, to: Date()).day ?? 0
        let dayCount = daysSinceLastPeriod
        
        if dayCount <= 45 {
            currentCycle = cycle
        } else {
            // Cycle is too old, clear it
            clearCycle()
        }
    }
    
    private func saveCycle() {
        guard let cycle = currentCycle,
              let data = try? JSONEncoder().encode(cycle) else {
            return
        }
        
        UserDefaults.standard.set(data, forKey: "SavedMenstrualCycle")
    }
    
    // MARK: - Helper Methods for UI
    
    func daysUntilNextPeriod() -> Int? {
        guard let cycle = currentCycle else { return nil }
        let nextPeriodDate = cycle.nextPeriodDate
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextPeriodDate).day ?? 0
        return max(0, daysUntil)
    }
    
    func daysUntilOvulation() -> Int? {
        guard let cycle = currentCycle else { return nil }
        let ovulationDate = cycle.ovulationDate
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: ovulationDate).day ?? 0
        return daysUntil
    }
    
    func isInFertileWindow() -> Bool {
        guard let cycle = currentCycle else { return false }
        let today = Date()
        return today >= cycle.fertileWindowStart && today <= cycle.fertileWindowEnd
    }
}