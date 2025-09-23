//
//  FloatingSearchButton.swift
//  Synagamy3.0
//
//  A floating search button similar to HomeButton that opens a custom search interface
//

import SwiftUI

struct FloatingSearchButton: View {
    @Binding var isSearching: Bool
    var size: CGFloat = 56
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Dismiss keyboard immediately if closing search
            if isSearching {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isSearching.toggle()
            }
            
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.prepare()
            impactGenerator.impactOccurred()
        }) {
            Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Brand.Color.primary,
                                    Brand.Color.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Brand.Color.primary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .rotationEffect(.degrees(isSearching ? 90 : 0))
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearching)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(isSearching ? "Close Search" : "Open Search")
        .accessibilityHint(isSearching ? "Closes the search interface" : "Opens search to find topics")
    }
}

// MARK: - Search Bar Component

struct EducationSearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Brand.Color.secondary)
            
            TextField("Search topics...", text: $searchText)
                .font(.body)
                .focused($isFocused)
                .submitLabel(.search)
                .textFieldStyle(.plain)
                .onSubmit {
                    isFocused = false
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Brand.Color.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Brand.Color.hairline, lineWidth: 1)
                )
        )
        .onAppear {
            isFocused = true
        }
    }
}