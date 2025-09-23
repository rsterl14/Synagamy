//
//  EnhancedAccessibility.swift
//  Synagamy3.0
//
//  Comprehensive accessibility enhancements for the Synagamy app
//

import SwiftUI
import AVFoundation

// MARK: - Dynamic Type Support

@MainActor
final class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published private(set) var isLargeFontEnabled: Bool = false
    @Published private(set) var isHighContrastEnabled: Bool = false
    @Published private(set) var isReduceMotionEnabled: Bool = false
    @Published private(set) var isVoiceOverEnabled: Bool = false
    @Published private(set) var preferredContentSize: ContentSizeCategory = .medium
    
    private init() {
        updateAccessibilitySettings()
        
        // Listen for accessibility changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func accessibilitySettingsChanged() {
        updateAccessibilitySettings()
    }
    
    private func updateAccessibilitySettings() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled

        let uiContentSize = UIApplication.shared.preferredContentSizeCategory
        preferredContentSize = ContentSizeCategory(uiContentSize) ?? .medium
        isLargeFontEnabled = uiContentSize.isAccessibilityCategory

        // Log accessibility status for debugging
        #if DEBUG
        print("♿ AccessibilityManager: VoiceOver: \(isVoiceOverEnabled), Large Fonts: \(isLargeFontEnabled), Reduce Motion: \(isReduceMotionEnabled), High Contrast: \(isHighContrastEnabled)")
        #endif
    }

    // MARK: - View Registration & Monitoring

    @Published private(set) var registeredViews: Set<String> = []
    @Published private(set) var accessibilityIssues: [AccessibilityIssue] = []

    struct AccessibilityIssue {
        let view: String
        let issue: String
        let severity: Severity

        enum Severity {
            case warning, error, critical

            var color: Color {
                switch self {
                case .warning: return .orange
                case .error: return .red
                case .critical: return .purple
                }
            }
        }
    }

    func registerView(_ viewName: String) {
        registeredViews.insert(viewName)
        #if DEBUG
        print("♿ AccessibilityManager: Registered view \(viewName)")
        #endif
    }

    func reportIssue(_ issue: String, in view: String, severity: AccessibilityIssue.Severity = .warning) {
        let accessibilityIssue = AccessibilityIssue(view: view, issue: issue, severity: severity)
        accessibilityIssues.append(accessibilityIssue)

        #if DEBUG
        print("♿ AccessibilityManager: \(severity) in \(view): \(issue)")
        #endif
    }

    func validateView(_ viewName: String, hasAccessibilityLabels: Bool, hasDynamicTypeSupport: Bool, hasVoiceOverSupport: Bool) {
        registerView(viewName)

        if !hasAccessibilityLabels {
            reportIssue("Missing accessibility labels", in: viewName, severity: .error)
        }

        if !hasDynamicTypeSupport {
            reportIssue("Missing Dynamic Type support", in: viewName, severity: .warning)
        }

        if !hasVoiceOverSupport {
            reportIssue("Missing VoiceOver support", in: viewName, severity: .error)
        }
    }

    func clearIssues() {
        accessibilityIssues.removeAll()
    }

    func getComplianceScore() -> Double {
        guard !registeredViews.isEmpty else { return 0.0 }

        let errorCount = accessibilityIssues.filter { $0.severity == .error || $0.severity == .critical }.count
        let warningCount = accessibilityIssues.filter { $0.severity == .warning }.count

        let totalPossibleIssues = registeredViews.count * 3 // 3 checks per view
        let actualIssues = errorCount * 2 + warningCount // Errors count double

        return max(0.0, Double(totalPossibleIssues - actualIssues) / Double(totalPossibleIssues))
    }
}

// MARK: - Accessible Button Style

struct AccessibleButtonStyle: ButtonStyle {
    let color: Color
    let isProminent: Bool
    
    @Environment(\.isEnabled) private var isEnabled
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(color: Color = Color("BrandPrimary"), isProminent: Bool = true) {
        self.color = color
        self.isProminent = isProminent
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(isProminent ? .semibold : .medium))
            .foregroundColor(isProminent ? .white : color)
            .padding(.horizontal, accessibilityManager.isLargeFontEnabled ? 20 : 16)
            .padding(.vertical, accessibilityManager.isLargeFontEnabled ? 16 : 12)
            .frame(minHeight: 44) // Apple's minimum touch target
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isProminent ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: isProminent ? 0 : 2)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(
                accessibilityManager.isReduceMotionEnabled ? .none : .easeInOut(duration: 0.1),
                value: configuration.isPressed
            )
            .accessibilityAddTraits(isProminent ? .isButton : [.isButton])
            .accessibilityHint(isEnabled ? "" : "This button is currently disabled")
    }
}

// MARK: - Voice Over Support

struct VoiceOverSupport {
    static func announceValue<T>(_ value: T, withLabel label: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        let announcement = "\(label): \(value)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    static func announceScreenChange(to screen: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        let announcement = "Navigated to \(screen)"
        UIAccessibility.post(notification: .screenChanged, argument: announcement)
    }
    
    static func announceCompletion(of task: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        let announcement = "\(task) completed"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Accessible Form Fields

struct AccessibleFormField<Content: View>: View {
    let label: String
    let hint: String?
    let isRequired: Bool
    let errorMessage: String?
    @ViewBuilder let content: () -> Content
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        label: String,
        hint: String? = nil,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label with required indicator
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .accessibilityLabel("required")
                }
            }
            
            // Content with accessibility enhancements
            content()
                .accessibilityLabel(label)
                .accessibilityHint(hint ?? "")
                .accessibilityValue(errorMessage ?? "")
                .accessibilityAddTraits(isRequired ? .isHeader : [])
            
            // Error message
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .accessibilityHidden(true)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(errorMessage)")
            }
            
            // Hint text
            if let hint = hint, errorMessage == nil {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true) // Already included in field hint
            }
        }
        .padding(.bottom, accessibilityManager.isLargeFontEnabled ? 12 : 8)
    }
}

// MARK: - High Contrast Color Support

struct AdaptiveColor {
    static func primary(isHighContrast: Bool) -> Color {
        isHighContrast ? .black : .primary
    }
    
    static func secondary(isHighContrast: Bool) -> Color {
        isHighContrast ? .black.opacity(0.8) : .secondary
    }
    
    static func background(isHighContrast: Bool) -> Color {
        isHighContrast ? .white : Color(.systemBackground)
    }
    
    static func accent(isHighContrast: Bool) -> Color {
        isHighContrast ? .blue : Color("BrandPrimary")
    }
}

// MARK: - Reduce Motion Support

struct ConditionalAnimation<Value: Equatable>: ViewModifier {
    let animation: Animation
    let value: Value
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .animation(
                accessibilityManager.isReduceMotionEnabled ? .none : animation,
                value: value
            )
    }
}

extension View {
    func conditionalAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(ConditionalAnimation(animation: animation, value: value))
    }
}

// MARK: - Accessible Navigation

struct AccessibleNavigationButton: View {
    let title: String
    let destination: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            VoiceOverSupport.announceScreenChange(to: destination)
        }) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Navigate to \(destination)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessible Data Display

struct AccessibleDataRow: View {
    let label: String
    let value: String
    let unit: String?
    let explanation: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(label: String, value: String, unit: String? = nil, explanation: String? = nil) {
        self.label = label
        self.value = value
        self.unit = unit
        self.explanation = explanation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let explanation = explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding(.vertical, accessibilityManager.isLargeFontEnabled ? 12 : 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit ?? "")")
        .accessibilityHint(explanation ?? "")
    }
}

// MARK: - Accessible Alerts

struct AccessibleAlert: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let actions: [AlertAction]
    
    struct AlertAction {
        let title: String
        let style: AlertActionStyle
        let action: () -> Void
        
        enum AlertActionStyle {
            case `default`
            case destructive
            case cancel
        }
    }
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                ForEach(actions.indices, id: \.self) { index in
                    let alertAction = actions[index]
                    
                    Button(alertAction.title, role: buttonRole(for: alertAction.style)) {
                        alertAction.action()
                        
                        // Announce action for VoiceOver users
                        if UIAccessibility.isVoiceOverRunning {
                            let announcement = "\(alertAction.title) selected"
                            UIAccessibility.post(notification: .announcement, argument: announcement)
                        }
                    }
                }
            } message: {
                Text(message)
            }
    }
    
    private func buttonRole(for style: AlertAction.AlertActionStyle) -> ButtonRole? {
        switch style {
        case .destructive:
            return .destructive
        case .cancel:
            return .cancel
        case .default:
            return nil
        }
    }
}

extension View {
    func accessibleAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        actions: [AccessibleAlert.AlertAction]
    ) -> some View {
        modifier(AccessibleAlert(
            isPresented: isPresented,
            title: title,
            message: message,
            actions: actions
        ))
    }
}

#Preview("Accessible Components") {
    VStack(spacing: 20) {
        AccessibleFormField(
            label: "Age",
            hint: "Enter your age in years",
            isRequired: true,
            errorMessage: nil
        ) {
            TextField("Age", text: .constant("35"))
                .textFieldStyle(.roundedBorder)
        }
        
        AccessibleNavigationButton(
            title: "IVF Outcome Predictor",
            destination: "Outcome Predictor"
        ) {
            // Navigation action
        }
        
        AccessibleDataRow(
            label: "Expected Oocytes",
            value: "12",
            unit: "oocytes",
            explanation: "Based on your age and AMH level"
        )
    }
    .padding()
    .registerForAccessibilityAudit(viewName: "Preview")
}

// MARK: - View Modifier for Automatic Registration

struct AccessibilityRegistration: ViewModifier {
    let viewName: String
    let hasAccessibilityLabels: Bool
    let hasDynamicTypeSupport: Bool
    let hasVoiceOverSupport: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                AccessibilityManager.shared.validateView(
                    viewName,
                    hasAccessibilityLabels: hasAccessibilityLabels,
                    hasDynamicTypeSupport: hasDynamicTypeSupport,
                    hasVoiceOverSupport: hasVoiceOverSupport
                )
            }
    }
}

extension View {
    func registerForAccessibilityAudit(
        viewName: String,
        hasAccessibilityLabels: Bool = true,
        hasDynamicTypeSupport: Bool = true,
        hasVoiceOverSupport: Bool = true
    ) -> some View {
        modifier(AccessibilityRegistration(
            viewName: viewName,
            hasAccessibilityLabels: hasAccessibilityLabels,
            hasDynamicTypeSupport: hasDynamicTypeSupport,
            hasVoiceOverSupport: hasVoiceOverSupport
        ))
    }
}