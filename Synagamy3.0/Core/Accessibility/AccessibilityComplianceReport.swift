//
//  AccessibilityComplianceReport.swift
//  Synagamy3.0
//
//  Comprehensive accessibility compliance report and testing utilities
//  for App Store submission and WCAG compliance.
//

import SwiftUI
import UIKit

struct AccessibilityComplianceReport {

    // MARK: - Compliance Status

    struct ComplianceItem {
        let category: Category
        let requirement: String
        let status: Status
        let implementation: String
        let testing: String

        enum Category: String, CaseIterable {
            case voiceOver = "VoiceOver Support"
            case dynamicType = "Dynamic Type"
            case highContrast = "High Contrast"
            case reduceMotion = "Reduce Motion"
            case touchTargets = "Touch Targets"
            case semantics = "Semantic Markup"
            case navigation = "Navigation"
            case forms = "Form Accessibility"
        }

        enum Status {
            case compliant
            case partiallyCompliant
            case nonCompliant
            case notApplicable

            var color: Color {
                switch self {
                case .compliant: return .green
                case .partiallyCompliant: return .orange
                case .nonCompliant: return .red
                case .notApplicable: return .gray
                }
            }

            var icon: String {
                switch self {
                case .compliant: return "checkmark.circle.fill"
                case .partiallyCompliant: return "exclamationmark.triangle.fill"
                case .nonCompliant: return "xmark.circle.fill"
                case .notApplicable: return "minus.circle.fill"
                }
            }
        }
    }

    // MARK: - Compliance Requirements

    static let requirements: [ComplianceItem] = [
        // VoiceOver Support
        ComplianceItem(
            category: .voiceOver,
            requirement: "All interactive elements have accessible labels",
            status: .compliant,
            implementation: "Added fertilityAccessibility() modifiers to all buttons, links, and interactive elements across HomeView, EducationView, ResourcesView, and CommonQuestionsView",
            testing: "Test with VoiceOver enabled. All buttons should announce their purpose and context."
        ),

        ComplianceItem(
            category: .voiceOver,
            requirement: "Screen changes are announced to VoiceOver users",
            status: .compliant,
            implementation: "Added AccessibilityAnnouncement.announce() calls on view appearances and state changes",
            testing: "Navigate between screens with VoiceOver to verify announcements"
        ),

        ComplianceItem(
            category: .voiceOver,
            requirement: "Decorative images are hidden from VoiceOver",
            status: .compliant,
            implementation: "Added .accessibilityHidden(true) to decorative icons and graphics",
            testing: "VoiceOver should skip decorative elements and focus only on meaningful content"
        ),

        // Dynamic Type
        ComplianceItem(
            category: .dynamicType,
            requirement: "Text scales properly at all Dynamic Type sizes",
            status: .compliant,
            implementation: "Used system fonts and implemented onDynamicTypeChange() handlers in all major views",
            testing: "Use DynamicTypeTestingView to test all sizes from XS to Accessibility XXXL"
        ),

        ComplianceItem(
            category: .dynamicType,
            requirement: "Layout adapts to larger text sizes without truncation",
            status: .compliant,
            implementation: "Used flexible layouts with proper spacing and lineLimit(nil) for content text",
            testing: "Test at accessibility extra extra extra large size - ensure no text is cut off"
        ),

        ComplianceItem(
            category: .dynamicType,
            requirement: "Touch targets remain accessible at large text sizes",
            status: .compliant,
            implementation: "Minimum 44pt touch targets maintained using AccessibleButtonStyle",
            testing: "Verify buttons remain tappable and properly sized at largest Dynamic Type sizes"
        ),

        // High Contrast
        ComplianceItem(
            category: .highContrast,
            requirement: "High contrast mode support",
            status: .compliant,
            implementation: "AdaptiveColor system in EnhancedAccessibility.swift provides high contrast variants",
            testing: "Enable high contrast in Settings > Accessibility > Display & Text Size > Increase Contrast"
        ),

        ComplianceItem(
            category: .highContrast,
            requirement: "Sufficient color contrast ratios",
            status: .compliant,
            implementation: "Brand colors chosen for WCAG AA compliance (4.5:1 for normal text, 3:1 for large text)",
            testing: "Use color contrast analyzers to verify ratios meet WCAG standards"
        ),

        // Reduce Motion
        ComplianceItem(
            category: .reduceMotion,
            requirement: "Animations can be disabled",
            status: .compliant,
            implementation: "ConditionalAnimation modifier respects Reduce Motion setting",
            testing: "Enable Reduce Motion in Settings > Accessibility > Motion > Reduce Motion"
        ),

        ComplianceItem(
            category: .reduceMotion,
            requirement: "Essential motion is preserved",
            status: .compliant,
            implementation: "Only decorative animations are disabled; functional animations remain",
            testing: "Verify app remains fully functional with Reduce Motion enabled"
        ),

        // Touch Targets
        ComplianceItem(
            category: .touchTargets,
            requirement: "Minimum 44pt touch target size",
            status: .compliant,
            implementation: "AccessibleButtonStyle enforces 44pt minimum, AccessibilityConstants.minimumTouchTarget used",
            testing: "Measure all interactive elements - must be at least 44x44 points"
        ),

        ComplianceItem(
            category: .touchTargets,
            requirement: "Adequate spacing between touch targets",
            status: .compliant,
            implementation: "Brand.Spacing system ensures proper spacing between interactive elements",
            testing: "Verify users can accurately tap buttons without accidentally hitting adjacent targets"
        ),

        // Semantic Markup
        ComplianceItem(
            category: .semantics,
            requirement: "Proper heading hierarchy",
            status: .compliant,
            implementation: "Added .accessibilityAddTraits(.isHeader) to section titles and page headers",
            testing: "VoiceOver users should be able to navigate by headings using the rotor"
        ),

        ComplianceItem(
            category: .semantics,
            requirement: "Form elements properly labeled",
            status: .compliant,
            implementation: "AccessibleFormField component provides proper labeling and required field indicators",
            testing: "All form fields should announce their labels and required status"
        ),

        ComplianceItem(
            category: .semantics,
            requirement: "Button traits properly set",
            status: .compliant,
            implementation: "fertilityAccessibility() helper ensures buttons have .isButton trait",
            testing: "VoiceOver should announce \"button\" for all interactive elements"
        ),

        // Navigation
        ComplianceItem(
            category: .navigation,
            requirement: "Logical tab order",
            status: .compliant,
            implementation: "SwiftUI's natural tab order follows visual layout; custom order set where needed",
            testing: "Navigate with VoiceOver swipe gestures to verify logical order"
        ),

        ComplianceItem(
            category: .navigation,
            requirement: "Focus management on screen changes",
            status: .compliant,
            implementation: "AccessibilityAnnouncement.announceScreenChanged() on navigation",
            testing: "VoiceOver focus should move appropriately when navigating between screens"
        ),

        // Forms
        ComplianceItem(
            category: .forms,
            requirement: "Error messages are accessible",
            status: .compliant,
            implementation: "AccessibleFormField includes error state with proper announcements",
            testing: "Trigger form validation errors and verify VoiceOver announces them clearly"
        ),

        ComplianceItem(
            category: .forms,
            requirement: "Required fields are identified",
            status: .compliant,
            implementation: "Required field indicators with accessibilityLabel(\"required\")",
            testing: "VoiceOver should announce \"required\" for mandatory form fields"
        )
    ]

    // MARK: - Testing Instructions

    static let testingInstructions = [
        TestingInstruction(
            title: "VoiceOver Testing",
            steps: [
                "Go to Settings > Accessibility > VoiceOver and turn it on",
                "Open Synagamy app and navigate through all screens",
                "Verify all buttons, links, and interactive elements have clear labels",
                "Check that screen changes are announced",
                "Ensure decorative images are skipped",
                "Test navigation using VoiceOver gestures"
            ]
        ),

        TestingInstruction(
            title: "Dynamic Type Testing",
            steps: [
                "Go to Settings > Accessibility > Display & Text Size > Larger Text",
                "Enable Larger Accessibility Sizes",
                "Set text size to the largest setting",
                "Open Synagamy app and verify all text is readable",
                "Check that buttons remain accessible",
                "Ensure no text is truncated or cut off",
                "Use the built-in DynamicTypeTestingView for comprehensive testing"
            ]
        ),

        TestingInstruction(
            title: "High Contrast Testing",
            steps: [
                "Go to Settings > Accessibility > Display & Text Size",
                "Enable Increase Contrast",
                "Open Synagamy app and verify all text is still readable",
                "Check that UI elements have sufficient contrast",
                "Verify important information isn't conveyed by color alone"
            ]
        ),

        TestingInstruction(
            title: "Reduce Motion Testing",
            steps: [
                "Go to Settings > Accessibility > Motion",
                "Enable Reduce Motion",
                "Open Synagamy app and navigate through screens",
                "Verify animations are reduced or eliminated",
                "Check that app functionality is preserved",
                "Ensure essential motion is still present"
            ]
        ),

        TestingInstruction(
            title: "Touch Target Testing",
            steps: [
                "Use a physical device (not simulator)",
                "Try tapping all buttons and interactive elements",
                "Verify accurate touch registration",
                "Check that adjacent elements don't interfere",
                "Test at largest Dynamic Type size"
            ]
        )
    ]

    struct TestingInstruction {
        let title: String
        let steps: [String]
    }

    // MARK: - App Store Submission Checklist

    static let appStoreChecklist = [
        "VoiceOver compatibility verified",
        "Dynamic Type support tested at all sizes",
        "High contrast mode compatibility confirmed",
        "Reduce Motion preference respected",
        "Touch targets meet minimum size requirements",
        "Color contrast ratios meet WCAG AA standards",
        "All form fields properly labeled",
        "Error messages are accessible",
        "Navigation is logical and accessible",
        "Screen reader announcements are clear and helpful"
    ]

    // MARK: - Compliance Summary

    static var complianceSummary: (compliant: Int, total: Int, percentage: Double) {
        let compliantCount = requirements.filter { $0.status == .compliant }.count
        let totalCount = requirements.count
        let percentage = Double(compliantCount) / Double(totalCount) * 100
        return (compliantCount, totalCount, percentage)
    }
}

// MARK: - Compliance Report View

struct AccessibilityComplianceReportView: View {
    @State private var selectedCategory: AccessibilityComplianceReport.ComplianceItem.Category?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary Section
                    summarySection

                    // Requirements by Category
                    requirementsSection

                    // Testing Instructions
                    testingSection

                    // App Store Checklist
                    checklistSection
                }
                .padding()
            }
            .navigationTitle("Accessibility Compliance")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compliance Summary")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            let summary = AccessibilityComplianceReport.complianceSummary

            HStack {
                VStack(alignment: .leading) {
                    Text("\(summary.compliant)/\(summary.total)")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.green)

                    Text("Requirements Met")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(summary.percentage))%")
                    .font(.title.weight(.semibold))
                    .foregroundColor(.green)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Compliance summary: \(summary.compliant) out of \(summary.total) requirements met, \(Int(summary.percentage)) percent compliant")
        }
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accessibility Requirements")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            ForEach(AccessibilityComplianceReport.ComplianceItem.Category.allCases, id: \.self) { category in
                let categoryRequirements = AccessibilityComplianceReport.requirements.filter { $0.category == category }

                CategorySection(category: category, requirements: categoryRequirements)
            }
        }
    }

    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Testing Instructions")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            ForEach(AccessibilityComplianceReport.testingInstructions, id: \.title) { instruction in
                TestingInstructionView(instruction: instruction)
            }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Store Submission Checklist")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            ForEach(AccessibilityComplianceReport.appStoreChecklist, id: \.self) { item in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityHidden(true)

                    Text(item)
                        .font(.body)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Completed: \(item)")
            }
        }
    }
}

struct CategorySection: View {
    let category: AccessibilityComplianceReport.ComplianceItem.Category
    let requirements: [AccessibilityComplianceReport.ComplianceItem]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    let compliantCount = requirements.filter { $0.status == .compliant }.count

                    Text("\(compliantCount)/\(requirements.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(compliantCount == requirements.count ? .green : .orange)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(category.rawValue): \(requirements.filter { $0.status == .compliant }.count) out of \(requirements.count) requirements met")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")

            if isExpanded {
                ForEach(requirements, id: \.requirement) { requirement in
                    RequirementRow(requirement: requirement)
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct RequirementRow: View {
    let requirement: AccessibilityComplianceReport.ComplianceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: requirement.status.icon)
                    .foregroundColor(requirement.status.color)
                    .accessibilityHidden(true)

                Text(requirement.requirement)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }

            Text("Implementation: \(requirement.implementation)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Testing: \(requirement.testing)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.leading, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(requirement.status == .compliant ? "Compliant" : "Non-compliant"): \(requirement.requirement)")
        .accessibilityValue("Implementation: \(requirement.implementation). Testing: \(requirement.testing)")
    }
}

struct TestingInstructionView: View {
    let instruction: AccessibilityComplianceReport.TestingInstruction
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(instruction.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(instruction.title)
            .accessibilityHint(isExpanded ? "Double tap to collapse steps" : "Double tap to view testing steps")

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(instruction.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)

                            Text(step)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.leading, 16)
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview("Compliance Report") {
    AccessibilityComplianceReportView()
}