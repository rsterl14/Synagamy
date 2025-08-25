//
//  CycleModels.swift
//  Synagamy3.0
//
//  Data models for menstrual cycle tracking and fertility prediction.
//

import SwiftUI
import Foundation

// MARK: - Menstrual Cycle Model

struct MenstrualCycle: Identifiable, Codable {
    let id: UUID
    let lastPeriodDate: Date
    let averageLength: Int
    let periodLength: Int
    let lutealPhaseLength: Int
    
    var currentDay: Int {
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriodDate, to: Date()).day ?? 0
        return daysSinceLastPeriod + 1
    }
    
    var nextPeriodDate: Date {
        Calendar.current.date(byAdding: .day, value: averageLength, to: lastPeriodDate) ?? Date()
    }
    
    var ovulationDate: Date {
        Calendar.current.date(byAdding: .day, value: averageLength - lutealPhaseLength, to: lastPeriodDate) ?? Date()
    }
    
    var fertileWindowStart: Date {
        Calendar.current.date(byAdding: .day, value: -5, to: ovulationDate) ?? Date()
    }
    
    var fertileWindowEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: ovulationDate) ?? Date()
    }
    
    init(lastPeriodDate: Date, averageLength: Int = 28, periodLength: Int = 5, lutealPhaseLength: Int = 14) {
        self.id = UUID()
        self.lastPeriodDate = lastPeriodDate
        self.averageLength = max(21, min(35, averageLength)) // Clamp to realistic range
        self.periodLength = max(3, min(7, periodLength))
        self.lutealPhaseLength = max(10, min(16, lutealPhaseLength))
    }
}

// MARK: - Fertility Status

struct FertilityStatus {
    let phase: CyclePhase
    let title: String
    let description: String
    let color: Color
    let fertilityLevel: FertilityLevel
    
    enum CyclePhase {
        case menstruation
        case follicular
        case fertile
        case ovulation
        case luteal
    }
    
    enum FertilityLevel: Int, CaseIterable {
        case none = 0
        case low = 1
        case medium = 2
        case high = 3
        case peak = 4
        
        var description: String {
            switch self {
            case .none: return "Very Low"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .peak: return "Peak"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .peak: return .red
            }
        }
    }
}

// MARK: - Fertility Window

struct FertilityWindow {
    let cycle: MenstrualCycle
    let calendarDays: [DayInfo]
    
    struct DayInfo {
        let day: Int
        let date: Date
        let phase: FertilityStatus.CyclePhase
        let fertilityLevel: FertilityStatus.FertilityLevel
        let isCurrentDay: Bool
        let isInFertileWindow: Bool
        
        var fertilityColor: Color {
            if phase == .menstruation {
                return .red
            } else if isInFertileWindow {
                return fertilityLevel == .peak ? .orange : .green
            } else {
                return .gray.opacity(0.3)
            }
        }
    }
    
    init(cycle: MenstrualCycle) {
        self.cycle = cycle
        
        let calendar = Calendar.current
        let today = Date()
        let startDate = cycle.lastPeriodDate
        
        var days: [DayInfo] = []
        
        for dayOffset in 0..<cycle.averageLength {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            let dayNumber = dayOffset + 1
            let isCurrentDay = calendar.isDate(date, inSameDayAs: today)
            let phase = CyclePhaseCalculator.phase(for: dayNumber, in: cycle)
            let fertilityLevel = FertilityCalculator.fertilityLevel(for: dayNumber, in: cycle)
            let isInFertileWindow = date >= cycle.fertileWindowStart && date <= cycle.fertileWindowEnd
            
            days.append(DayInfo(
                day: dayNumber,
                date: date,
                phase: phase,
                fertilityLevel: fertilityLevel,
                isCurrentDay: isCurrentDay,
                isInFertileWindow: isInFertileWindow
            ))
        }
        
        self.calendarDays = days
    }
}

// MARK: - Recommendation Model

struct IntercourseTiming: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let priority: Priority
    let daysFromNow: Int?
    
    enum Priority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - Cycle Phase Calculator

struct CyclePhaseCalculator {
    static func phase(for day: Int, in cycle: MenstrualCycle) -> FertilityStatus.CyclePhase {
        let ovulationDay = cycle.averageLength - cycle.lutealPhaseLength
        let fertileStart = ovulationDay - 5
        let fertileEnd = ovulationDay + 1
        
        if day <= cycle.periodLength {
            return .menstruation
        } else if day < fertileStart {
            return .follicular
        } else if day < ovulationDay {
            return .fertile
        } else if day <= fertileEnd {
            return .ovulation
        } else {
            return .luteal
        }
    }
}

// MARK: - Fertility Calculator

struct FertilityCalculator {
    
    /// Calculate fertility level for a given day in the cycle
    static func fertilityLevel(for day: Int, in cycle: MenstrualCycle) -> FertilityStatus.FertilityLevel {
        let ovulationDay = cycle.averageLength - cycle.lutealPhaseLength
        let distanceFromOvulation = abs(day - ovulationDay)
        
        // During menstruation
        if day <= cycle.periodLength {
            return .none
        }
        
        // Peak fertility: ovulation day ± 1
        if distanceFromOvulation <= 1 && day >= ovulationDay - 1 && day <= ovulationDay + 1 {
            return .peak
        }
        
        // High fertility: 2-3 days before ovulation
        if day >= ovulationDay - 3 && day < ovulationDay - 1 {
            return .high
        }
        
        // Medium fertility: 4-5 days before ovulation
        if day >= ovulationDay - 5 && day < ovulationDay - 3 {
            return .medium
        }
        
        // Low fertility: early follicular phase
        if day > cycle.periodLength && day < ovulationDay - 5 {
            return .low
        }
        
        // Very low fertility: luteal phase
        return .none
    }
    
    /// Calculate optimal intercourse timing recommendations
    static func recommendations(for cycle: MenstrualCycle) -> [IntercourseTiming] {
        let currentDay = cycle.currentDay
        let ovulationDay = cycle.averageLength - cycle.lutealPhaseLength
        let daysUntilOvulation = ovulationDay - currentDay
        
        var recommendations: [IntercourseTiming] = []
        
        // Current phase recommendations
        let currentPhase = CyclePhaseCalculator.phase(for: currentDay, in: cycle)
        
        switch currentPhase {
        case .menstruation:
            recommendations.append(IntercourseTiming(
                title: "Wait for Fertile Window",
                description: "Your fertile window will begin in approximately \(max(0, ovulationDay - 5 - currentDay)) days",
                icon: "calendar.badge.clock",
                priority: .low,
                daysFromNow: max(0, ovulationDay - 5 - currentDay)
            ))
            
        case .follicular:
            if daysUntilOvulation <= 7 {
                recommendations.append(IntercourseTiming(
                    title: "Prepare for Fertile Window",
                    description: "Start tracking cervical mucus and consider every other day intercourse",
                    icon: "eye.circle",
                    priority: .medium,
                    daysFromNow: nil
                ))
            }
            
        case .fertile:
            recommendations.append(IntercourseTiming(
                title: "Fertile Window Active",
                description: "High conception probability. Recommend daily or every other day intercourse",
                icon: "heart.circle.fill",
                priority: .high,
                daysFromNow: 0
            ))
            
        case .ovulation:
            recommendations.append(IntercourseTiming(
                title: "Peak Fertility",
                description: "Highest conception probability. Intercourse recommended today and tomorrow",
                icon: "target",
                priority: .critical,
                daysFromNow: 0
            ))
            
        case .luteal:
            recommendations.append(IntercourseTiming(
                title: "Post-Ovulation",
                description: "Conception window has passed. Next fertile window in \(cycle.averageLength - currentDay + (ovulationDay - 5)) days",
                icon: "clock.arrow.circlepath",
                priority: .low,
                daysFromNow: cycle.averageLength - currentDay + (ovulationDay - 5)
            ))
        }
        
        // Upcoming important days
        if daysUntilOvulation > 0 && daysUntilOvulation <= 7 {
            recommendations.append(IntercourseTiming(
                title: "Ovulation Approaching",
                description: "Ovulation expected in \(daysUntilOvulation) day\(daysUntilOvulation == 1 ? "" : "s")",
                icon: "calendar.badge.exclamationmark",
                priority: daysUntilOvulation <= 3 ? .high : .medium,
                daysFromNow: daysUntilOvulation
            ))
        }
        
        // General timing advice
        recommendations.append(IntercourseTiming(
            title: "Optimal Frequency",
            description: "Every 2-3 days throughout the cycle maintains sperm quality and maximizes chances",
            icon: "repeat.circle",
            priority: .low,
            daysFromNow: nil
        ))
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    /// Get current fertility status description
    static func fertilityStatus(for cycle: MenstrualCycle) -> FertilityStatus {
        let currentDay = cycle.currentDay
        let phase = CyclePhaseCalculator.phase(for: currentDay, in: cycle)
        let fertilityLevel = fertilityLevel(for: currentDay, in: cycle)
        
        let title: String
        let description: String
        let color: Color
        
        switch phase {
        case .menstruation:
            title = "Menstruation"
            description = "Fertility very low"
            color = .red
            
        case .follicular:
            title = "Follicular Phase"
            description = "Fertility increasing"
            color = .blue
            
        case .fertile:
            title = "Fertile Window"
            description = "High conception probability"
            color = .green
            
        case .ovulation:
            title = "Ovulation"
            description = "Peak fertility"
            color = .orange
            
        case .luteal:
            title = "Luteal Phase"
            description = "Fertility decreasing"
            color = .purple
        }
        
        return FertilityStatus(
            phase: phase,
            title: title,
            description: description,
            color: color,
            fertilityLevel: fertilityLevel
        )
    }
}