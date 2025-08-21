//
//  ResourceModels.swift
//  Synagamy3.0
//
//  Created by Reid Sterling on 2025-08-13.
//
import Foundation

/// Represents a single resource entry for the Resources section.
struct Resource: Identifiable, Equatable, Codable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let url: URL
    let systemImage: String
    
    // Custom coding keys to handle URL encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case title, subtitle, description, url, systemImage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        description = try container.decode(String.self, forKey: .description)
        systemImage = try container.decode(String.self, forKey: .systemImage)
        
        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Invalid URL string: \(urlString)")
        }
        self.url = url
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(description, forKey: .description)
        try container.encode(url.absoluteString, forKey: .url)
        try container.encode(systemImage, forKey: .systemImage)
    }
    
    // Manual initializer for programmatic creation
    init(title: String, subtitle: String, description: String, url: URL, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.url = url
        self.systemImage = systemImage
    }
}

// MARK: - Data Loading

extension Resource {
    static func loadFromJSON() -> [Resource] {
        guard let url = Bundle.main.url(forResource: "resources", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Could not find or load resources.json")
            return []
        }
        
        do {
            let resources = try JSONDecoder().decode([Resource].self, from: data)
            return resources
        } catch {
            print("Error decoding resources.json: \(error)")
            return []
        }
    }
}
