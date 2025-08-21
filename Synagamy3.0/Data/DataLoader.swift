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
        case emptyData(resource: String)      // file exists but is empty
        case invalidFormat(resource: String)   // not valid JSON
    }

    /// Strict loader (throws). Useful for tests or explicit error flows.
    static func load<T: Decodable>(_ type: T.Type, named resource: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            #if DEBUG
            debugPrint("⚠️ DataLoader: missing resource \(resource).json in app bundle.")
            #endif
            let error = SynagamyError.dataMissing(resource: resource)
            Task { @MainActor in
                ErrorHandler.shared.handle(error)
            }
            throw LoadError.missingResource(resource)
        }

        do {
            let data = try Data(contentsOf: url)
            
            // Check for empty data
            guard !data.isEmpty else {
                #if DEBUG
                debugPrint("⚠️ DataLoader: \(resource).json is empty.")
                #endif
                let error = SynagamyError.dataCorrupted(resource: resource, details: "File is empty")
                Task { @MainActor in
                    ErrorHandler.shared.handle(error)
                }
                throw LoadError.emptyData(resource: resource)
            }
            
            // Validate JSON format before decoding
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                #if DEBUG
                debugPrint("⚠️ DataLoader: \(resource).json contains invalid JSON.")
                #endif
                let synagamyError = SynagamyError.dataCorrupted(resource: resource, details: "Invalid JSON format")
                Task { @MainActor in
                    ErrorHandler.shared.handle(synagamyError)
                }
                throw LoadError.invalidFormat(resource: resource)
            }
            
            #if DEBUG
            debugPrint("ℹ️ DataLoader: \(resource).json found (\(data.count) bytes).")
            #endif
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            #if DEBUG
            debugPrint("❌ DataLoader: decode failed for \(resource).json — \(error)")
            #endif
            
            // Create detailed error message for different decoding failures
            let details = decodeErrorDetails(error)
            let synagamyError = SynagamyError.dataValidationFailed(resource: resource, issues: [details])
            Task { @MainActor in
                ErrorHandler.shared.handle(synagamyError)
            }
            
            throw LoadError.decodeFailed(resource: resource, underlying: error)
            
        } catch let loadError as LoadError {
            // Re-throw our custom LoadError types
            throw loadError
            
        } catch {
            #if DEBUG
            debugPrint("❌ DataLoader: read failed for \(resource).json — \(error)")
            #endif
            
            let synagamyError = SynagamyError.dataLoadFailed(resource: resource, underlying: error)
            Task { @MainActor in
                ErrorHandler.shared.handle(synagamyError)
            }
            
            throw LoadError.readFailed(url, underlying: error)
        }
    }

    /// Non‑throwing convenience that returns Result.
    static func loadResult<T: Decodable>(_ type: T.Type, named resource: String) -> Result<T, Error> {
        do { 
            return .success(try load(type, named: resource)) 
        } catch { 
            return .failure(error) 
        }
    }

    /// Silent‑fallback array loader (keeps UI resilient).
    /// In DEBUG it logs *why* you got an empty array.
    static func loadArray<T: Decodable>(_ type: [T].Type, named resource: String) -> [T] {
        switch loadResult(type, named: resource) {
        case .success(let array):
            #if DEBUG
            debugPrint("✅ DataLoader: \(resource).json decoded \(array.count) item(s).")
            #endif
            
            // Validate array content
            if array.isEmpty {
                #if DEBUG
                debugPrint("⚠️ DataLoader: \(resource).json decoded successfully but contains no items.")
                #endif
                let error = SynagamyError.contentEmpty(section: resource)
                Task { @MainActor in
                    ErrorHandler.shared.handle(error)
                }
            }
            
            return array
            
        case .failure(let error):
            #if DEBUG
            debugPrint("⚠️ DataLoader: returning [] for \(resource).json due to error: \(error)")
            #endif
            
            // Log the error through our centralized system
            ErrorHandler.shared.handleError(error, context: resource)
            
            return []
        }
    }
    
    /// Safe loader with retry mechanism
    static func loadWithRetry<T: Decodable>(
        _ type: T.Type, 
        named resource: String, 
        maxRetries: Int = 3
    ) -> T? {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            switch loadResult(type, named: resource) {
            case .success(let result):
                #if DEBUG
                if attempt > 1 {
                    debugPrint("✅ DataLoader: \(resource).json loaded successfully on attempt \(attempt)")
                }
                #endif
                return result
                
            case .failure(let error):
                lastError = error
                #if DEBUG
                debugPrint("⚠️ DataLoader: attempt \(attempt)/\(maxRetries) failed for \(resource).json")
                #endif
                
                // Brief delay before retry (except on last attempt)
                if attempt < maxRetries {
                    Thread.sleep(forTimeInterval: 0.1 * Double(attempt))
                }
            }
        }
        
        // All retries failed
        if let error = lastError {
            ErrorHandler.shared.handleError(error, context: "\(resource) (after \(maxRetries) retries)")
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    /// Extracts meaningful error details from DecodingError
    private static func decodeErrorDetails(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            return "Type mismatch: expected \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            
        case .valueNotFound(let type, let context):
            return "Missing required value of type \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            
        case .keyNotFound(let key, let context):
            return "Missing required key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            
        case .dataCorrupted(let context):
            return "Data corrupted at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)"
            
        @unknown default:
            return "Unknown decoding error: \(error.localizedDescription)"
        }
    }
    
    /// Validates data content before processing
    static func validateContent<T: Collection>(_ content: T, resource: String) -> Bool {
        guard !content.isEmpty else {
            let error = SynagamyError.contentEmpty(section: resource)
            Task { @MainActor in
                ErrorHandler.shared.handle(error)
            }
            return false
        }
        return true
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
