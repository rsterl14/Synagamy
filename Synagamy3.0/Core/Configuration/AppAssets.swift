//
//  AppAssets.swift
//  Synagamy3.0
//
//  Centralized asset management to replace hardcoded asset names
//  throughout the codebase. Provides compile-time safety and
//  easier maintenance for image and color assets.
//

import SwiftUI

/// Centralized asset management for images, colors, and other resources
enum AppAssets {
    
    // MARK: - Logos and Branding
    enum Logo {
        static let primary = "SynagamyLogoTwo"
        static let education = "EducationLogo"
        static let resources = "ResourcesLogo"
        static let commonQuestions = "CommonQuestionsLogo"
        static let pathways = "PathwaysLogo"
        static let clinics = "ClinicsLogo"
        static let infertility = "InfertilityLogo"
    }
    
    // MARK: - Colors
    enum Color {
        static let brandPrimary = "BrandPrimary"
        static let brandSecondary = "BrandSecondary"
        static let brandAccent = "BrandAccent"
    }
    
    // MARK: - System Icons (commonly used)
    enum SystemIcon {
        static let close = "xmark"
        static let chevronDown = "chevron.down.circle"
        static let chevronUp = "chevron.up.circle.fill"
        static let chevronRight = "chevron.right"
        static let link = "link"
        static let magnifyingGlass = "magnifyingglass"
        static let house = "house"
        static let book = "book.fill"
        static let questionMark = "questionmark.circle.fill"
        static let folder = "folder.fill"
        static let lightbulb = "lightbulb.fill"
        static let doc = "doc.text.magnifyingglass"
        static let building = "building.2.fill"
        static let heart = "heart.text.square"
        static let arrow = "arrow.right.circle.fill"
        static let exclamation = "exclamationmark.triangle.fill"
    }
    
    // MARK: - Helper Extensions
}

// MARK: - SwiftUI Extensions for easier usage
extension Image {
    /// Creates an image from AppAssets.Logo
    static func logo(_ logo: String) -> Image {
        Image(logo)
    }
    
    /// Creates a system image from AppAssets.SystemIcon
    static func systemIcon(_ icon: String) -> Image {
        Image(systemName: icon)
    }
}

extension Color {
    /// Creates a color from AppAssets.Color
    static func brandColor(_ color: String) -> Color {
        Color(color)
    }
}
