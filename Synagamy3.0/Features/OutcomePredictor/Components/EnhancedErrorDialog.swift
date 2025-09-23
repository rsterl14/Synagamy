//
//  EnhancedErrorDialog.swift
//  Synagamy3.0
//
//  Enhanced error handling with recovery suggestions and accessibility
//

import SwiftUI

struct EnhancedErrorDialog: View {
    let title: String
    let message: String
    let recoverySuggestions: [RecoverySuggestion]
    let onDismiss: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    struct RecoverySuggestion {
        let icon: String
        let title: String
        let description: String
        let action: (() -> Void)?
        
        init(icon: String, title: String, description: String, action: (() -> Void)? = nil) {
            self.icon = icon
            self.title = title
            self.description = description
            self.action = action
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon and Title
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            
            // Error Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Recovery Suggestions
            if !recoverySuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to fix this:")
                        .font(.headline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    ForEach(Array(recoverySuggestions.enumerated()), id: \.offset) { index, suggestion in
                        RecoverySuggestionRow(
                            suggestion: suggestion,
                            index: index + 1
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Dismiss Button
            Button(action: {
                onDismiss()
                // VoiceOverSupport.announceValue("Error dialog dismissed", withLabel: "Action")
            }) {
                Text("Got it")
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal)
            .accessibilityLabel("Dismiss error dialog")
            .accessibilityHint("Closes this error message")
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .onAppear {
            // VoiceOverSupport.announceValue("Error: \(title). \(message)", withLabel: "Error Alert")
        }
    }
}

struct RecoverySuggestionRow: View {
    let suggestion: EnhancedErrorDialog.RecoverySuggestion
    let index: Int
    
    var body: some View {
        Button(action: {
            suggestion.action?()
            // VoiceOverSupport.announceCompletion(of: suggestion.title)
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Step number
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    Text("\(index)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.blue)
                }
                
                // Icon
                Image(systemName: suggestion.icon)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if suggestion.action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(suggestion.action == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(suggestion.title): \(suggestion.description)")
        .accessibilityHint(suggestion.action != nil ? "Double tap to perform this action" : "Information only")
    }
}

// MARK: - Common Error Recovery Suggestions

extension EnhancedErrorDialog.RecoverySuggestion {
    static func checkInput(field: String, action: @escaping () -> Void) -> EnhancedErrorDialog.RecoverySuggestion {
        EnhancedErrorDialog.RecoverySuggestion(
            icon: "textformat.123",
            title: "Check \(field) input",
            description: "Make sure the value is a valid number in the correct range",
            action: action
        )
    }
    
    static func verifyUnits(field: String, action: @escaping () -> Void) -> EnhancedErrorDialog.RecoverySuggestion {
        EnhancedErrorDialog.RecoverySuggestion(
            icon: "ruler",
            title: "Verify \(field) units",
            description: "Ensure you've selected the correct measurement units",
            action: action
        )
    }
    
    static func consultProvider() -> EnhancedErrorDialog.RecoverySuggestion {
        EnhancedErrorDialog.RecoverySuggestion(
            icon: "stethoscope",
            title: "Consult healthcare provider",
            description: "If values seem correct, discuss with your fertility specialist"
        )
    }
    
    static func checkTestResults() -> EnhancedErrorDialog.RecoverySuggestion {
        EnhancedErrorDialog.RecoverySuggestion(
            icon: "doc.text.magnifyingglass",
            title: "Review test results",
            description: "Double-check your lab results for accuracy"
        )
    }
}

// MARK: - View Modifier for Enhanced Error Handling

struct EnhancedErrorHandling: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let recoverySuggestions: [EnhancedErrorDialog.RecoverySuggestion]
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Custom overlay for error dialog
                Group {
                    if isPresented {
                        ZStack {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    isPresented = false
                                }
                            
                            EnhancedErrorDialog(
                                title: title,
                                message: message,
                                recoverySuggestions: recoverySuggestions
                            ) {
                                isPresented = false
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
                    }
                }
            )
    }
}

extension View {
    func enhancedErrorDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        recoverySuggestions: [EnhancedErrorDialog.RecoverySuggestion] = []
    ) -> some View {
        modifier(EnhancedErrorHandling(
            isPresented: isPresented,
            title: title,
            message: message,
            recoverySuggestions: recoverySuggestions
        ))
    }
}


#Preview("Enhanced Error Dialog") {
    VStack {
        EnhancedErrorDialog(
            title: "Invalid AMH Level",
            message: "The AMH value you entered is outside the expected range. Please check your lab results and try again.",
            recoverySuggestions: [
                .checkInput(field: "AMH") { },
                .verifyUnits(field: "AMH") { },
                .checkTestResults(),
                .consultProvider()
            ]
        ) {
            // Dismiss action
        }
    }
    .background(Color.gray.opacity(0.3))
}