//
//  Resource.swift
//  Synagamy2.0
//
//  Created by Reid Sterling on 2025-08-13.
//
// Features/Resources/Resource.swift
import Foundation

/// Represents a single resource entry for the Resources section.
struct Resource: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let url: URL
    let systemImage: String
}
