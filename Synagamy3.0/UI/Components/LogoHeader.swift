//
//  LogoHeader.swift
//  Synagamy3.0
//
//  A compact, accessible header that shows a primary logo and an optional secondary logo.
//  It validates inputs, reports recoverable errors via an optional callback, and falls
//  back to SF Symbols when a raster/vector asset is missing.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct LogoHeader: View {

    // MARK: - Errors

    /// Non-fatal issues the view can encounter.
    enum LogoHeaderError: LocalizedError, Equatable {
        case invalidHeight(CGFloat)
        case missingAsset(name: String)

        var errorDescription: String? {
            switch self {
            case .invalidHeight(let h):
                return "LogoHeader received an invalid height (\(h)). Using a safe default."
            case .missingAsset(let name):
                return "LogoHeader could not find an image asset named “\(name)”. Falling back to a system symbol."
            }
        }
    }

    // MARK: - Public API

    /// The primary image asset name to display (required).
    let primaryImage: String

    /// Optional secondary image asset name to display beside the primary.
    let secondaryImage: String?

    /// Target height for the primary image (the secondary scales to 90% of this).
    /// If invalid (≤ 0), the view reports an error and uses a safe default.
    var height: CGFloat = 200

    /// Spacing between images.
    var spacing: CGFloat = 12

    /// Optional error reporter. Use this to surface non-fatal issues to your UI/logging layer.
    var onError: ((LogoHeaderError) -> Void)? = nil

    // MARK: - Body

    var body: some View {
        let safeHeight = validatedHeight(height)

        HStack(spacing: spacing) {
            makeImage(primaryImage, fallbackSymbol: "leaf.fill")
                .resizable()
                .scaledToFit()
                .frame(height: safeHeight)
                .accessibilityHidden(true)

            if let secondary = secondaryImage, !secondary.isEmpty {
                makeImage(secondary, fallbackSymbol: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(height: safeHeight * 0.9)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTitle))
    }

    // MARK: - Helpers

    /// Ensures we never render with a nonpositive height.
    private func validatedHeight(_ proposed: CGFloat) -> CGFloat {
        guard proposed > 0 else {
            report(.invalidHeight(proposed))
            return 160 // safe default
        }
        return proposed
    }

    /// Builds an `Image`, preferring an asset by name; otherwise falls back to a system symbol.
    /// Reports a `.missingAsset` error exactly when falling back.
    private func makeImage(_ name: String, fallbackSymbol: String) -> Image {
        #if canImport(UIKit)
        if UIImage(named: name) != nil {
            // Asset exists in the bundle.
            return Image(name).renderingMode(.original)
        } else {
            // Fall back and report nonfatal error.
            report(.missingAsset(name: name))
            return Image(systemName: fallbackSymbol)
                .renderingMode(.original)
                .symbolRenderingMode(.hierarchical)
        }
        #else
        // On non-UIKit platforms we can’t verify asset existence; just try the asset and
        // rely on the symbol fallback in your calling context if desired.
        return Image(name).renderingMode(.original)
        #endif
    }

    /// Human-friendly accessibility title derived from the secondary image when present.
    private var accessibilityTitle: String {
        if let secondary = secondaryImage, !secondary.isEmpty {
            return "Synagamy — \(readable(from: secondary))"
        } else {
            return "Synagamy"
        }
    }

    /// Converts an asset key like "EducationLogo" → "Education".
    private func readable(from assetKey: String) -> String {
        let trimmed = assetKey.replacingOccurrences(of: "Logo", with: "")
        let words = trimmed.reduce(into: "") { acc, ch in
            if ch.isUppercase && !acc.isEmpty { acc.append(" ") }
            acc.append(ch)
        }
        return words.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Single reporting point for all non-fatal issues.
    private func report(_ error: LogoHeaderError) {
        // Prefer the client’s handler if provided.
        if let onError {
            onError(error)
            return
        }
        // Otherwise log to console for visibility during development.
        #if DEBUG
        print("⚠️ LogoHeader:", error.localizedDescription)
        #endif
    }
}

#Preview("LogoHeader – With Secondary") {
    LogoHeader(
        primaryImage: "SynagamyLogoTwo",
        secondaryImage: "EducationLogo",
        height: 160
    ) { err in
        // Example: route errors to your in-app logger or telemetry.
        print("LogoHeader error:", err.localizedDescription)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("LogoHeader – Primary Only") {
    LogoHeader(primaryImage: "SynagamyLogoTwo", secondaryImage: "SynagamyQuote", height: 140)
        .background(Color(.systemGroupedBackground))
}
