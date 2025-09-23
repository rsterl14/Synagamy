//  UnifiedFloatingHeader.swift
//  Synagamy3.0

import SwiftUI

struct UnifiedFloatingHeader: View {
    // MARK: - Properties
    
    let primaryImage: String
    let secondaryImage: String?
    var height: CGFloat = 140
    var spacing: CGFloat = 12
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Primary logo (larger) - positioned slightly up
            makeImage(primaryImage)
                .resizable()
                .scaledToFit()
                .frame(height: height * 1.2)
                .offset(y: -15)
                .accessibilityLabel("Synagamy")
            
            // Secondary logo (smaller) - positioned below and overlapping
            if let secondary = secondaryImage, !secondary.isEmpty {
                makeImage(secondary)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height * 0.8)
                    .offset(y: 30)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .background(
            Color(.systemBackground)
                .opacity(1.0)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator).opacity(0.3))
                .frame(maxHeight: .infinity, alignment: .bottom)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
    }
    
    // MARK: - Helpers
    
    private func makeImage(_ name: String) -> Image {
        if UIImage(named: name) != nil {
            return Image(name).renderingMode(.original)
        } else {
            return Image(systemName: "photo")
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    private var accessibilityTitle: String {
        if let secondary = secondaryImage, !secondary.isEmpty {
            let sectionName = secondary
                .replacingOccurrences(of: "Logo", with: "")
                .reduce(into: "") { acc, ch in
                    if ch.isUppercase && !acc.isEmpty { acc.append(" ") }
                    acc.append(ch)
                }
            return "Synagamy — \(sectionName)"
        }
        return "Synagamy"
    }
}

// MARK: - Preview

#Preview("Unified Header - Education") {
    VStack {
        UnifiedFloatingHeader(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo"
        )
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Unified Header - Primary Only") {
    VStack {
        UnifiedFloatingHeader(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: nil
        )
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
