//
//  AppConstants.swift
//  Synagamy3.0
//
//  Centralized constants and configuration values used throughout the app.
//

import Foundation
import SwiftUI

// MARK: - App Configuration

enum AppConstants {
    
    // MARK: - Layout
    
    enum Layout {
        static let standardHorizontalPadding: CGFloat = 16
        static let standardVerticalPadding: CGFloat = 12
        static let tileGridVerticalPadding: CGFloat = 14
        static let defaultHeaderHeight: CGFloat = 64
        
        // Tile dimensions
        static let tileMinHeight: CGFloat = 200
        static let tileIconSize: CGFloat = 80
        static let tileSymbolSize: CGFloat = 40
        static let tilePadding: CGFloat = 30
        
        // Spacing
        static let extraSmallSpacing: CGFloat = 4
        static let smallSpacing: CGFloat = 8
        static let mediumSpacing: CGFloat = 12
        static let largeSpacing: CGFloat = 16
        static let extraLargeSpacing: CGFloat = 20
        static let xxlSpacing: CGFloat = 24
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quickDuration: TimeInterval = 0.1
        static let standardDuration: TimeInterval = 0.25
        static let slowDuration: TimeInterval = 0.4
        
        static let standardDelay: TimeInterval = 0.05
        static let mediumDelay: TimeInterval = 0.1
        static let longDelay: TimeInterval = 0.2
        
        static let bounceScale: CGFloat = 1.05
        static let subtleScale: CGFloat = 0.98
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let minimumReadableSize: CGFloat = 12
        static let bodySize: CGFloat = 16
        static let headlineSize: CGFloat = 18
        static let titleSize: CGFloat = 22
        static let largeTitleSize: CGFloat = 28
    }
    
    // MARK: - Colors
    
    enum ColorNames {
        static let brandPrimary = "BrandPrimary"
        static let brandSecondary = "BrandSecondary"
        static let brandThird = "BrandThird"
        static let brandBackground = "BrandBackground"
        static let accentColor = "AccentColor"
    }
    
    // MARK: - Images
    
    enum ImageNames {
        static let primaryLogo = "SynagamyLogoTwo"
        static let educationLogo = "EducationLogo"
        static let pathwayLogo = "PathwayLogo"
        static let clinicLogo = "ClinicLogo"
        static let resourcesLogo = "ResourcesLogo"
        static let commonQuestionsLogo = "CommonQuestionsLogo"
        static let startingPointLogo = "StartingPointLogo"
    }
    
    // MARK: - System Icons
    
    enum SystemIcons {
        // Navigation
        static let home = "house.fill"
        static let back = "chevron.left"
        static let close = "xmark"
        
        // Features
        static let education = "book.fill"
        static let pathways = "map.fill"
        static let clinics = "building.2.fill"
        static let resources = "lightbulb.fill"
        static let questions = "questionmark.circle.fill"
        static let community = "person.2.wave.2.fill"
        static let infertility = "person.3.fill"
        static let outcome = "chart.line.uptrend.xyaxis"
        
        // States
        static let loading = "hourglass"
        static let error = "exclamationmark.triangle"
        static let empty = "square.grid.2x2"
        static let search = "magnifyingglass"
        
        // Actions
        static let tap = "hand.tap"
        static let share = "square.and.arrow.up"
        static let favorite = "heart"
        static let bookmark = "bookmark"
    }
    
    // MARK: - Accessibility
    
    enum Accessibility {
        static let defaultHint = "Double tap to activate"
        static let navigationHint = "Tap to open"
        static let closeHint = "Tap to close"
        static let searchHint = "Search for topics"
        
        // Labels
        static let homeButton = "Home"
        static let backButton = "Back"
        static let loadingIndicator = "Loading content"
        static let errorMessage = "Error occurred"
    }
    
    // MARK: - API and Data
    
    enum Data {
        static let maxCacheAge: TimeInterval = 3600 // 1 hour
        static let requestTimeout: TimeInterval = 30
        static let maxRetryAttempts = 3
        
        // File names
        static let educationTopicsFile = "Education_Topics.json"
        static let pathwaysFile = "Pathways.json"
        static let commonQuestionsFile = "CommonQuestions.json"
    }
    
    // MARK: - Performance
    
    enum Performance {
        static let debounceInterval: TimeInterval = 0.3
        static let maxConcurrentOperations = 3
        static let imageCompressionQuality: CGFloat = 0.8
        
        // Thresholds
        static let lowMemoryThreshold: Double = 0.8
        static let highPerformanceThreshold: Double = 0.2
    }
}

// MARK: - Computed Properties

extension AppConstants {
    /// Standard corner radius based on platform
    static var standardCornerRadius: CGFloat {
        #if os(iOS)
        return 12
        #else
        return 8
        #endif
    }
    
    /// Standard shadow radius
    static var standardShadowRadius: CGFloat {
        4
    }
    
    /// Standard blur radius for overlays
    static var standardBlurRadius: CGFloat {
        20
    }
}

// MARK: - Environment-specific Constants

#if DEBUG
extension AppConstants {
    enum Debug {
        static let enableLogging = true
        static let showPerformanceMetrics = true
        static let enableNetworkLogging = true
    }
}
#endif