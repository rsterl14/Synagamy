//
//  DataLoader.swift
//  Synagamy3.0
//
//  JSON loading utilities + in‑memory cache for app content.
//  - AppStore‑safe: no force‑unwraps, friendly fallbacks.
//  - Eager load (init) so views see data on first render.
//  - DEBUG diagnostics to spot bundling/decoding issues fast.
//

import Foundation

// MARK: - DataLoader

enum DataLoader {
    enum LoadError: Error {
        case missingResource(String)          // file not in bundle
        case readFailed(URL, underlying: Error)
        case decodeFailed(resource: String, underlying: Error)
    }

    /// Strict loader (throws). Useful for tests or explicit error flows.
    static func load<T: Decodable>(_ type: T.Type, named resource: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            #if DEBUG
            debugPrint("⚠️ DataLoader: missing resource \(resource).json in app bundle.")
            #endif
            throw LoadError.missingResource(resource)
        }

        do {
            let data = try Data(contentsOf: url)
            #if DEBUG
            debugPrint("ℹ️ DataLoader: \(resource).json found (\(data.count) bytes).")
            #endif
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            #if DEBUG
            debugPrint("❌ DataLoader: decode failed for \(resource).json — \(error)")
            #endif
            throw LoadError.decodeFailed(resource: resource, underlying: error)
        } catch {
            #if DEBUG
            debugPrint("❌ DataLoader: read failed for \(resource).json — \(error)")
            #endif
            throw LoadError.readFailed(url, underlying: error)
        }
    }

    /// Non‑throwing convenience that returns Result.
    static func loadResult<T: Decodable>(_ type: T.Type, named resource: String) -> Result<T, Error> {
        do { return .success(try load(type, named: resource)) }
        catch { return .failure(error) }
    }

    /// Silent‑fallback array loader (keeps UI resilient).
    /// In DEBUG it logs *why* you got an empty array.
    static func loadArray<T: Decodable>(_ type: [T].Type, named resource: String) -> [T] {
        switch loadResult(type, named: resource) {
        case .success(let array):
            #if DEBUG
            debugPrint("✅ DataLoader: \(resource).json decoded \(array.count) item(s).")
            #endif
            return array
        case .failure(let error):
            #if DEBUG
            debugPrint("⚠️ DataLoader: returning [] for \(resource).json due to error: \(error)")
            #endif
            return []
        }
    }
}

// MARK: - AppData (facade) & AppDataStore (cache)

/// Simple facade so views can read static arrays without holding references.
enum AppData {
    /// Topics backing Education + Topic detail.
    static var topics: [EducationTopic] { AppDataStore.shared.topics }
    /// Categories/paths/steps backing Pathways.
    static var pathways: [PathwayCategory] { AppDataStore.shared.pathways }
    /// FAQ items backing Common Questions.
    static var questions: [CommonQuestion] { AppDataStore.shared.questions }

    /// Manual reload hook if you ever support pull‑to‑refresh or remote updates.
    static func reload() { AppDataStore.shared.reloadAll() }
}

/// Singleton in‑memory cache. Not observable (by design) — we eager‑load in init
/// so views have data on first render and don’t need to observe changes.
final class AppDataStore {
    static let shared = AppDataStore()

    // Cached content
    private(set) var topics: [EducationTopic] = []
    private(set) var questions: [CommonQuestion] = []
    private(set) var pathways: [PathwayCategory] = []

    // Restrict construction — everyone uses `shared`.
    private init() {
        // ✅ CRITICAL: eager‑load once so Education/Pathways/Questions are populated
        // before any view accesses AppData.* during initial render.
        reloadAll()

        #if DEBUG
        debugPrint("🏁 AppDataStore init complete. topics=\(topics.count), pathways=\(pathways.count), questions=\(questions.count)")
        #endif
    }

    /// Loads all JSON with resilient fallbacks. Safe to call multiple times.
    func reloadAll() {
        // Load with silent fallback ([]) to keep UI responsive.
        let loadedTopics: [EducationTopic]     = DataLoader.loadArray([EducationTopic].self, named: "Education_Topics")
        let loadedQuestions: [CommonQuestion]  = DataLoader.loadArray([CommonQuestion].self, named: "CommonQuestions")
        let loadedPathways: [PathwayCategory]  = DataLoader.loadArray([PathwayCategory].self, named: "Pathways")

        // Assign to cache
        topics    = loadedTopics
        questions = loadedQuestions
        pathways  = loadedPathways

        // Optional sanity logging
        #if DEBUG
        if topics.isEmpty { debugPrint("🔍 AppDataStore: topics is EMPTY") }
        if pathways.isEmpty { debugPrint("🔍 AppDataStore: pathways is EMPTY") }
        if questions.isEmpty { debugPrint("🔍 AppDataStore: questions is EMPTY") }
        #endif

        // Non‑fatal content validation (duplicates, empty strings, etc.)
        validate()
    }

    /// Validate content assumptions and log (never crash in production).
    func validate() {
        #if DEBUG
        // Example: warn on duplicate topic IDs (topic names must be unique).
        let topicIDs = topics.map { $0.id }
        let dupTopicIDs = Dictionary(grouping: topicIDs, by: { $0 }).filter { $1.count > 1 }.keys
        if !dupTopicIDs.isEmpty {
            debugPrint("⚠️ AppDataStore.validate: duplicate topic IDs → \(dupTopicIDs.joined(separator: ", "))")
        }

        for c in pathways {
            if c.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                debugPrint("⚠️ AppDataStore.validate: empty category title for id=\(c.id)")
            }
            for p in c.paths {
                if p.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    debugPrint("⚠️ AppDataStore.validate: empty path title for id=\(p.id)")
                }
                if p.steps.isEmpty {
                    debugPrint("⚠️ AppDataStore.validate: path has 0 steps for id=\(p.id)")
                }
            }
        }
        #endif
    }
}
