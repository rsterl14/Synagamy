//
//  TopicMatcher.swift
//  Synagamy3.0
//
//  Core/TopicMatcher.swift
//
//  Purpose
//  -------
//  Robustly match the free-text "topic_refs" in pathway steps to actual EducationTopic
//  items. This version:
//
//   • Keeps the original API (index(topics:), match(stepRefs:index:)) so no call sites break.
//   • Adds stronger normalization: lowercasing, punctuation stripping, diacritic folding,
//     and dash/whitespace unification.
//   • Builds a richer index that includes:
//       - exact topic titles
//       - lightweight aliases derived from the topic title (e.g., “pgt-a” -> “pgta”)
//       - optional custom aliases you can pass in (future-proofing)
//   • Deduplicates by EducationTopic.id and preserves the order of `stepRefs` when possible.
//   • Is defensive: ignores empty strings and safely handles collisions.
//
//  References to current model shapes:
//   • EducationTopic.id == topic (unique) :contentReference[oaicite:4]{index=4}
//   • PathwayStep.topicRefs / topic_refs (JSON) :contentReference[oaicite:5]{index=5}
//

import Foundation

/// Normalizes and matches topic references from pathway steps to EducationTopic objects.
enum TopicMatcher {

    // MARK: - Public API (backwards-compatible)

    /// Build an index of normalized keys → EducationTopic.
    /// - Parameter topics: All available education topics.
    /// - Returns: A dictionary that can be used with `match(stepRefs:index:)`.
    ///
    /// Compatibility: Signature preserved from the original implementation. :contentReference[oaicite:6]{index=6}
    static func index(topics: [EducationTopic]) -> [String: EducationTopic] {
        buildIndex(topics: topics, customAliases: [:])
    }

    /// Match a list of step reference strings (from PathwayStep.topic_refs) to topics.
    /// - Parameters:
    ///   - stepRefs: Free-text refs coming from JSON (e.g., ["PGT-A", "Embryo Grading"])
    ///   - index: The dictionary produced by `index(topics:)`.
    /// - Returns: Ordered, de-duplicated EducationTopic array.
    ///
    /// Compatibility: Signature preserved from the original implementation. :contentReference[oaicite:7]{index=7}
    static func match(stepRefs: [String], index: [String: EducationTopic]) -> [EducationTopic] {
        var seen = Set<String>()          // de-dupe by EducationTopic.id
        var out: [EducationTopic] = []

        for raw in stepRefs {
            let key = normalize(raw)
            guard !key.isEmpty else { continue }

            if let t = index[key], seen.insert(t.id).inserted {
                out.append(t)
            }
        }
        return out
    }

    // MARK: - Extended API (optional, for future use)

    /// Build an index with optional *custom* aliases (e.g., mapping "IVF-ICSI" → "Intracytoplasmic Sperm Injection (ICSI)").
    /// Keys and alias values are free-text; both are normalized internally.
    ///
    /// Example:
    /// ```
    /// let aliases = ["ivf-icsi": "Intracytoplasmic Sperm Injection (ICSI)"]
    /// let idx = TopicMatcher.buildIndex(topics: AppData.topics, customAliases: aliases)
    /// ```
    static func buildIndex(
        topics: [EducationTopic],
        customAliases: [String: String]
    ) -> [String: EducationTopic] {

        var dict: [String: EducationTopic] = [:]

        // 1) Index exact titles + lightweight derived aliases
        for t in topics {
            let titleKey = normalize(t.topic)
            guard !titleKey.isEmpty else { continue }

            // Exact title
            dict[titleKey] = t

            // Lightweight aliases: remove common adornments, unify acronyms, etc.
            for alias in derivedAliases(for: t.topic) {
                let key = normalize(alias)
                guard !key.isEmpty else { continue }
                // Do not overwrite an existing mapping from a different topic
                if dict[key] == nil {
                    dict[key] = t
                }
            }
        }

        // 2) Apply custom aliases (authoritative; overwrite only if they point to the same topic)
        for (rawKey, rawTargetTitle) in customAliases {
            let key = normalize(rawKey)
            let targetKey = normalize(rawTargetTitle)
            guard !key.isEmpty, !targetKey.isEmpty, let target = dict[targetKey] else { continue }
            // Only set if unset or already mapped to same topic
            if dict[key] == nil || dict[key]?.id == target.id {
                dict[key] = target
            }
        }

        return dict
    }

    // MARK: - Normalization

    /// Normalize a string for matching:
    ///  - lowercased
    ///  - Unicode‐folded (removes diacritics)
    ///  - replace long/em dashes with hyphen
    ///  - remove all non-alphanumerics
    ///  - collapse whitespace
    ///
    /// This is stricter than the original (which split on non-alphanumerics and joined) :contentReference[oaicite:8]{index=8}
    static func normalize(_ s: String) -> String {
        guard !s.isEmpty else { return "" }

        // Lowercase
        var out = s.lowercased()

        // Unify common dashes
        out = out
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "–", with: "-")

        // Strip diacritics (e.g., “é” → “e”)
        out = out.folding(options: .diacriticInsensitive, locale: .current)

        // Keep only [a-z0-9]; drop everything else
        let allowed = CharacterSet.alphanumerics
        let parts = out.unicodeScalars.split { !allowed.contains($0) }
        return parts.map(String.init).joined()
    }

    // MARK: - Alias heuristics

    /// Generate lightweight aliases from a topic title.
    /// These are intentionally conservative (App Store–friendly, no PII, no network).
    private static func derivedAliases(for title: String) -> [String] {
        var aliases: Set<String> = []

        // 1) Remove common adornments like parentheses content to catch “ICSI”/“(ICSI)”.
        //    e.g., "Intracytoplasmic Sperm Injection (ICSI)" → "Intracytoplasmic Sperm Injection", "ICSI"
        let parenExtracts = extractAcronyms(in: title)
        aliases.formUnion(parenExtracts)

        // 2) Acronym compaction: "PGT-A" → "PGTA"; "IVF-ICSI" → ["IVFICSI", "ICSI"]
        let compact = title.replacingOccurrences(of: "-", with: "")
        if compact != title { aliases.insert(compact) }

        // 3) Shorten “Preimplantation Genetic Testing for Aneuploidy (PGT-A)”
        //    to include the bare acronym.
        if let acronym = parenExtracts.first, acronym.count <= 8 {
            aliases.insert(acronym)
        }

        return Array(aliases)
    }

    /// Extract short all-caps tokens inside parentheses as likely acronyms.
    private static func extractAcronyms(in title: String) -> [String] {
        guard let start = title.lastIndex(of: "("),
              let end = title.lastIndex(of: ")"),
              start < end else { return [] }

        let inside = title[title.index(after: start)..<end]
        // Split on separators just in case
        return inside
            .split { !$0.isLetter && !$0.isNumber && $0 != "-" }
            .map(String.init)
            .filter { $0.count >= 2 && $0.count <= 12 }
    }
}
