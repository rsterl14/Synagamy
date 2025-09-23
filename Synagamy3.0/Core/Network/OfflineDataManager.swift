//
//  OfflineDataManager.swift
//  Synagamy3.0
//
//  Enhanced offline data fallback system with multiple fallback layers
//  Ensures app remains functional without network connectivity
//

import Foundation
import SwiftUI

/// Enhanced offline data manager with multiple fallback strategies
@MainActor
final class OfflineDataManager: ObservableObject {
    static let shared = OfflineDataManager()

    @Published private(set) var isOperatingOffline = false
    @Published private(set) var lastOfflineUpdate: Date?
    @Published private(set) var availableOfflineContent: OfflineContentStatus

    enum OfflineContentStatus {
        case fullContent       // All content available offline
        case partialContent    // Some content available offline
        case limitedContent    // Only essential content available
        case noContent         // No offline content available

        var description: String {
            switch self {
            case .fullContent:
                return "All educational content available offline"
            case .partialContent:
                return "Most educational content available offline"
            case .limitedContent:
                return "Basic educational content available offline"
            case .noContent:
                return "Offline content unavailable"
            }
        }

        var userMessage: String {
            switch self {
            case .fullContent:
                return "You can continue using all app features while offline"
            case .partialContent:
                return "Most features are available while offline"
            case .limitedContent:
                return "Basic educational features are available while offline"
            case .noContent:
                return "Limited functionality available while offline"
            }
        }
    }

    private let fileManager = FileManager.default
    private let offlineDataDirectory: URL

    private init() {
        // Set up offline data directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        offlineDataDirectory = documentsPath.appendingPathComponent("OfflineData")
        availableOfflineContent = .noContent

        createOfflineDataDirectory()
        assessOfflineContentAvailability()
    }

    // MARK: - Public Methods

    /// Store data for offline use
    func storeForOfflineUse<T: Codable>(_ data: T, forKey key: String, category: OfflineDataCategory) async {
        do {
            let encoded = try JSONEncoder().encode(data)
            let fileURL = offlineDataDirectory
                .appendingPathComponent(category.rawValue)
                .appendingPathComponent("\(key).json")

            // Create category directory if needed
            let categoryDir = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: categoryDir.path) {
                try fileManager.createDirectory(at: categoryDir, withIntermediateDirectories: true)
            }

            try encoded.write(to: fileURL)

            // Update metadata
            await updateOfflineMetadata(key: key, category: category, size: encoded.count)

            #if DEBUG
            print("💾 OfflineDataManager: Stored \(key) offline (\(encoded.count) bytes)")
            #endif

            // Reassess content availability
            assessOfflineContentAvailability()

        } catch {
            #if DEBUG
            print("❌ OfflineDataManager: Failed to store \(key) offline: \(error)")
            #endif
        }
    }

    /// Retrieve data from offline storage
    func retrieveFromOfflineStorage<T: Codable>(_ type: T.Type, forKey key: String, category: OfflineDataCategory) -> T? {
        let fileURL = offlineDataDirectory
            .appendingPathComponent(category.rawValue)
            .appendingPathComponent("\(key).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            #if DEBUG
            print("📁 OfflineDataManager: No offline data found for \(key)")
            #endif
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(type, from: data)

            #if DEBUG
            print("📁 OfflineDataManager: Retrieved \(key) from offline storage")
            #endif

            return decoded

        } catch {
            #if DEBUG
            print("❌ OfflineDataManager: Failed to retrieve \(key) from offline storage: \(error)")
            #endif
            return nil
        }
    }

    /// Check if specific content is available offline
    func isAvailableOffline(key: String, category: OfflineDataCategory) -> Bool {
        let fileURL = offlineDataDirectory
            .appendingPathComponent(category.rawValue)
            .appendingPathComponent("\(key).json")

        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Get offline content summary
    func getOfflineContentSummary() -> OfflineContentSummary {
        var summary = OfflineContentSummary()

        for category in OfflineDataCategory.allCases {
            let categoryURL = offlineDataDirectory.appendingPathComponent(category.rawValue)

            if fileManager.fileExists(atPath: categoryURL.path) {
                do {
                    let files = try fileManager.contentsOfDirectory(at: categoryURL, includingPropertiesForKeys: [.fileSizeKey])

                    summary.totalFiles += files.count

                    for file in files {
                        if let resourceValues = try? file.resourceValues(forKeys: [.fileSizeKey]),
                           let size = resourceValues.fileSize {
                            summary.totalSizeBytes += size
                        }
                    }

                    // Category-specific counts
                    switch category {
                    case .education:
                        summary.educationTopics = files.count
                    case .pathways:
                        summary.pathways = files.count
                    case .resources:
                        summary.resources = files.count
                    case .commonQuestions:
                        summary.commonQuestions = files.count
                    }

                } catch {
                    #if DEBUG
                    print("❌ Error reading offline content for \(category): \(error)")
                    #endif
                }
            }
        }

        return summary
    }

    /// Set offline mode status
    func setOfflineMode(_ isOffline: Bool) {
        isOperatingOffline = isOffline
        if isOffline {
            lastOfflineUpdate = Date()
        }

        #if DEBUG
        print("📴 OfflineDataManager: Offline mode \(isOffline ? "enabled" : "disabled")")
        #endif
    }

    /// Clear all offline data
    func clearOfflineData() async {
        do {
            if fileManager.fileExists(atPath: offlineDataDirectory.path) {
                try fileManager.removeItem(at: offlineDataDirectory)
                createOfflineDataDirectory()
            }

            availableOfflineContent = .noContent

            #if DEBUG
            print("🗑️ OfflineDataManager: Cleared all offline data")
            #endif

        } catch {
            #if DEBUG
            print("❌ OfflineDataManager: Failed to clear offline data: \(error)")
            #endif
        }
    }

    /// Get fallback data for essential functionality
    func getEssentialFallbackData() -> EssentialFallbackData {
        return EssentialFallbackData(
            basicEducationContent: getBundledEducationTopics(),
            emergencyContacts: getEmergencyContacts(),
            offlineInstructions: getOfflineInstructions()
        )
    }

    // MARK: - Private Methods

    private func createOfflineDataDirectory() {
        do {
            if !fileManager.fileExists(atPath: offlineDataDirectory.path) {
                try fileManager.createDirectory(at: offlineDataDirectory, withIntermediateDirectories: true)

                // Create category subdirectories
                for category in OfflineDataCategory.allCases {
                    let categoryURL = offlineDataDirectory.appendingPathComponent(category.rawValue)
                    try fileManager.createDirectory(at: categoryURL, withIntermediateDirectories: true)
                }
            }
        } catch {
            #if DEBUG
            print("❌ OfflineDataManager: Failed to create offline data directory: \(error)")
            #endif
        }
    }

    private func assessOfflineContentAvailability() {
        let summary = getOfflineContentSummary()

        if summary.totalFiles >= 50 { // Threshold for full content
            availableOfflineContent = .fullContent
        } else if summary.totalFiles >= 20 { // Threshold for partial content
            availableOfflineContent = .partialContent
        } else if summary.totalFiles >= 5 { // Threshold for limited content
            availableOfflineContent = .limitedContent
        } else {
            availableOfflineContent = .noContent
        }

        #if DEBUG
        print("📊 OfflineDataManager: Content assessment - \(availableOfflineContent.description)")
        #endif
    }

    private func updateOfflineMetadata(key: String, category: OfflineDataCategory, size: Int) async {
        // Store metadata for offline content management
        let _ = OfflineContentMetadata(
            key: key,
            category: category,
            size: size,
            storedAt: Date(),
            lastAccessed: Date()
        )

        // This could be stored in a metadata file or UserDefaults for persistence
        // For now, we'll keep it simple and just log
        #if DEBUG
        print("📝 OfflineDataManager: Updated metadata for \(key)")
        #endif
    }

    private func getBundledEducationTopics() -> [BasicEducationTopic] {
        // Return essential education topics bundled with the app
        return [
            BasicEducationTopic(
                id: "basic-ivf",
                title: "Understanding IVF",
                summary: "Basic information about In Vitro Fertilization",
                isOfflineOnly: true
            ),
            BasicEducationTopic(
                id: "basic-fertility",
                title: "Fertility Basics",
                summary: "Essential fertility information",
                isOfflineOnly: true
            )
        ]
    }

    private func getEmergencyContacts() -> [EmergencyContact] {
        return [
            EmergencyContact(
                type: "Emergency Medical",
                number: "911",
                description: "For medical emergencies"
            ),
            EmergencyContact(
                type: "Fertility Support",
                number: "1-800-RESOLVE",
                description: "RESOLVE National Infertility Association"
            )
        ]
    }

    private func getOfflineInstructions() -> [String] {
        return [
            "Educational content available offline may be limited",
            "Predictions cannot be saved without internet connection",
            "Connect to internet to access latest medical information",
            "Contact healthcare providers directly for medical advice"
        ]
    }
}

// MARK: - Supporting Types

enum OfflineDataCategory: String, CaseIterable {
    case education = "education"
    case pathways = "pathways"
    case resources = "resources"
    case commonQuestions = "common-questions"
}

struct OfflineContentSummary {
    var totalFiles = 0
    var totalSizeBytes = 0
    var educationTopics = 0
    var pathways = 0
    var resources = 0
    var commonQuestions = 0

    var totalSizeMB: Double {
        return Double(totalSizeBytes) / (1024 * 1024)
    }
}

struct OfflineContentMetadata {
    let key: String
    let category: OfflineDataCategory
    let size: Int
    let storedAt: Date
    let lastAccessed: Date
}

struct EssentialFallbackData {
    let basicEducationContent: [BasicEducationTopic]
    let emergencyContacts: [EmergencyContact]
    let offlineInstructions: [String]
}

struct BasicEducationTopic: Identifiable, Codable {
    let id: String
    let title: String
    let summary: String
    let isOfflineOnly: Bool
}

struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    let type: String
    let number: String
    let description: String
}

// MARK: - Offline Status View

struct OfflineStatusView: View {
    @StateObject private var offlineManager = OfflineDataManager.shared

    var body: some View {
        if offlineManager.isOperatingOffline {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                    Text("Offline Mode")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.orange)
                    Spacer()
                }

                Text(offlineManager.availableOfflineContent.userMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lastUpdate = offlineManager.lastOfflineUpdate {
                    Text("Last online: \(lastUpdate, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.orange.opacity(0.1))
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    OfflineStatusView()
        .padding()
}