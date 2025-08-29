//
//  AccessibilityHelpers.swift
//  Synagamy3.0
//
//  Accessibility enhancement utilities and extensions.
//

import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Adds comprehensive accessibility labels and hints for fertility-related content
    func fertilityAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Adds accessibility support for input fields with validation
    func inputFieldAccessibility(
        label: String,
        value: String,
        validationMessage: String?,
        isRequired: Bool = false
    ) -> some View {
        let accessibilityLabel = isRequired ? "\(label), required" : label
        let accessibilityValue = value.isEmpty ? "empty" : value
        let accessibilityHint = validationMessage ?? "Enter \(label.lowercased())"
        
        return self
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility support for prediction results
    func predictionResultAccessibility(
        title: String,
        value: String,
        range: String? = nil,
        unit: String? = nil
    ) -> some View {
        let fullValue = [value, unit].compactMap { $0 }.joined(separator: " ")
        let accessibilityValue = range != nil ? "\(fullValue), range \(range!)" : fullValue
        
        return self
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(.isStaticText)
    }
    
    /// Adds accessibility support for fertility phase information
    func fertilityPhaseAccessibility(
        phase: String,
        description: String,
        fertilityLevel: String
    ) -> some View {
        let accessibilityLabel = "Current fertility phase: \(phase)"
        let accessibilityValue = "\(fertilityLevel) fertility level"
        let accessibilityHint = description
        
        return self
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Accessibility Announcement Helper

struct AccessibilityAnnouncement {
    static func announce(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    static func announceLayout() {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }
    
    static func announceScreenChanged() {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeReader: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    let handler: (DynamicTypeSize) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: dynamicTypeSize) { _, newSize in
                handler(newSize)
            }
            .onAppear {
                handler(dynamicTypeSize)
            }
    }
}

extension View {
    func onDynamicTypeChange(_ handler: @escaping (DynamicTypeSize) -> Void) -> some View {
        self.modifier(DynamicTypeReader(handler: handler))
    }
}

// MARK: - High Contrast Support

extension Color {
    static func adaptiveColor(
        light: Color,
        dark: Color,
        highContrastLight: Color? = nil,
        highContrastDark: Color? = nil
    ) -> Color {
        Color(UIColor { traits in
            let isHighContrast = traits.accessibilityContrast == .high
            
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor(isHighContrast ? (highContrastDark ?? dark) : dark)
            case .light, .unspecified:
                return UIColor(isHighContrast ? (highContrastLight ?? light) : light)
            @unknown default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Focus Management

class FocusManager: ObservableObject {
    @Published var focusedField: String? = nil
    
    func focus(on field: String) {
        focusedField = field
    }
    
    func clearFocus() {
        focusedField = nil
    }
}

// MARK: - Accessibility Constants

struct AccessibilityConstants {
    static let minimumTouchTarget: CGFloat = 44
    static let preferredTouchTarget: CGFloat = 48
    
    struct Labels {
        static let required = "required"
        static let optional = "optional"
        static let error = "error"
        static let warning = "warning"
        static let success = "success"
        static let loading = "loading"
        static let expandable = "expandable"
        static let collapsed = "collapsed"
        static let expanded = "expanded"
    }
    
    struct Hints {
        static let doubleTapToActivate = "Double tap to activate"
        static let doubleTapToExpand = "Double tap to expand"
        static let doubleTapToCollapse = "Double tap to collapse"
        static let swipeForMore = "Swipe up or down for more options"
        static let enterValue = "Enter a numeric value"
    }
}

// MARK: - Accessible Button Style

struct AccessibleButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let isDestructive: Bool
    
    init(
        backgroundColor: Color = Brand.ColorSystem.primary,
        foregroundColor: Color = .white,
        isDestructive: Bool = false
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minHeight: AccessibilityConstants.preferredTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isDestructive ? [] : [])
            .accessibilityHint(AccessibilityConstants.Hints.doubleTapToActivate)
    }
}