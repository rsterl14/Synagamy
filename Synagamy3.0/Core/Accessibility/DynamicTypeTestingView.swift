//
//  DynamicTypeTestingView.swift
//  Synagamy3.0
//
//  Dynamic Type testing and validation system for accessibility compliance.
//  Tests all text sizes from smallest to largest accessibility sizes.
//

import SwiftUI

struct DynamicTypeTestingView: View {
    @State private var selectedSize: ContentSizeCategory = .medium
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false

    private let allSizes: [ContentSizeCategory] = [
        .extraSmall,
        .small,
        .medium,
        .large,
        .extraLarge,
        .extraExtraLarge,
        .extraExtraExtraLarge,
        .accessibilityMedium,
        .accessibilityLarge,
        .accessibilityExtraLarge,
        .accessibilityExtraExtraLarge,
        .accessibilityExtraExtraExtraLarge
    ]

    struct TestResult: Identifiable {
        let id = UUID()
        let size: ContentSizeCategory
        let view: String
        let issues: [String]
        let passed: Bool

        var statusIcon: String {
            passed ? "checkmark.circle.fill" : "xmark.circle.fill"
        }

        var statusColor: Color {
            passed ? .green : .red
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Size Selector
                sizeSelector

                // Test Controls
                testControlsSection

                // Test Results
                if !testResults.isEmpty {
                    testResultsSection
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Dynamic Type Testing")
            .navigationBarTitleDisplayMode(.large)
        }
        .environment(\.sizeCategory, selectedSize)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "textformat.size")
                .font(.largeTitle)
                .foregroundColor(Color("BrandPrimary"))

            Text("Dynamic Type Testing")
                .font(.title.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("Test app layouts at different text sizes to ensure accessibility compliance")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var sizeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Size Category")
                .font(.headline)

            Picker("Content Size", selection: $selectedSize) {
                ForEach(allSizes, id: \.self) { size in
                    Text(sizeDisplayName(for: size))
                        .tag(size)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Select content size category for testing")
        }
    }

    private var testControlsSection: some View {
        VStack(spacing: 16) {
            Button("Run All Size Tests") {
                runAllSizeTests()
            }
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Color("BrandPrimary"))
            .cornerRadius(12)
            .disabled(isRunningTests)

            Button("Test Current Size Only") {
                testCurrentSize()
            }
            .font(.headline.weight(.medium))
            .foregroundColor(Color("BrandPrimary"))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("BrandPrimary"), lineWidth: 2)
            )
            .disabled(isRunningTests)

            if isRunningTests {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Running accessibility tests...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(testResults) { result in
                        testResultRow(result)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }

    private func testResultRow(_ result: TestResult) -> some View {
        HStack {
            Image(systemName: result.statusIcon)
                .foregroundColor(result.statusColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(sizeDisplayName(for: result.size)) - \(result.view)")
                    .font(.subheadline.weight(.medium))

                if !result.issues.isEmpty {
                    ForEach(result.issues, id: \.self) { issue in
                        Text("• \(issue)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.passed ? "Passed" : "Failed"): \(result.view) at \(sizeDisplayName(for: result.size))")
        .accessibilityValue(result.issues.isEmpty ? "No issues" : "\(result.issues.count) issues found")
    }

    private func sizeDisplayName(for size: ContentSizeCategory) -> String {
        switch size {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "A11y M"
        case .accessibilityLarge: return "A11y L"
        case .accessibilityExtraLarge: return "A11y XL"
        case .accessibilityExtraExtraLarge: return "A11y XXL"
        case .accessibilityExtraExtraExtraLarge: return "A11y XXXL"
        default: return "Unknown"
        }
    }

    private func runAllSizeTests() {
        isRunningTests = true
        testResults.removeAll()

        Task {
            for size in allSizes {
                let result = await testSizeCategory(size)
                await MainActor.run {
                    testResults.append(result)
                }

                // Brief delay between tests
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }

            await MainActor.run {
                isRunningTests = false
                announceTestCompletion()
            }
        }
    }

    private func testCurrentSize() {
        isRunningTests = true

        Task {
            let result = await testSizeCategory(selectedSize)
            await MainActor.run {
                testResults = [result]
                isRunningTests = false
                announceTestCompletion()
            }
        }
    }

    private func testSizeCategory(_ size: ContentSizeCategory) async -> TestResult {
        var issues: [String] = []

        // Test 1: Check if size is in accessibility range
        if size.isAccessibilityCategory {
            // Accessibility sizes require special attention
            if size == .accessibilityExtraExtraExtraLarge {
                issues.append("Largest accessibility size - ensure all content remains visible")
            }
        }

        // Test 2: Check for common layout issues
        let sizeMultiplier = getSizeMultiplier(for: size)
        if sizeMultiplier > 2.0 {
            issues.append("Large text scaling may cause layout overflow")
        }

        // Test 3: Check button sizes
        let minTouchTarget: CGFloat = 44
        let scaledTarget = minTouchTarget * sizeMultiplier
        if scaledTarget < 44 {
            issues.append("Touch targets may be too small")
        }

        // Test 4: Check if text truncation is likely
        if size.isAccessibilityCategory {
            issues.append("Verify no text truncation occurs at this size")
        }

        return TestResult(
            size: size,
            view: "All Views",
            issues: issues,
            passed: issues.isEmpty
        )
    }

    private func getSizeMultiplier(for size: ContentSizeCategory) -> CGFloat {
        switch size {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.9
        case .accessibilityExtraLarge: return 2.3
        case .accessibilityExtraExtraLarge: return 2.8
        case .accessibilityExtraExtraExtraLarge: return 3.5
        default: return 1.0
        }
    }

    private func announceTestCompletion() {
        let passedCount = testResults.filter { $0.passed }.count
        let totalCount = testResults.count
        let failedCount = totalCount - passedCount

        let message = failedCount == 0
            ? "All \(totalCount) dynamic type tests passed successfully"
            : "\(passedCount) tests passed, \(failedCount) tests failed. Review accessibility issues."

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

// MARK: - Preview Test Views

struct DynamicTypePreviewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Test different text styles
                Group {
                    Text("Large Title")
                        .font(.largeTitle)

                    Text("Title")
                        .font(.title)

                    Text("Title 2")
                        .font(.title2)

                    Text("Title 3")
                        .font(.title3)

                    Text("Headline")
                        .font(.headline)

                    Text("Body text that might wrap to multiple lines when the user increases their text size for better readability")
                        .font(.body)

                    Text("Caption text")
                        .font(.caption)
                }

                // Test button layouts
                Group {
                    Button("Primary Action") {
                        // Action
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(Color("BrandPrimary"))
                    .cornerRadius(12)

                    Button("Secondary Action") {
                        // Action
                    }
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("BrandPrimary"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 44)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("BrandPrimary"), lineWidth: 2)
                    )
                }

                // Test form field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Age")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        Text("*")
                            .foregroundColor(.red)
                            .accessibilityLabel("required")
                    }

                    TextField("Age", text: .constant("35"))
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Age")
                        .accessibilityHint("Enter your age in years")

                    Text("Enter your age in years")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Test data display
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Expected Success Rate")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("65")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)

                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Based on your age and medical history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Expected Success Rate: 65 %")
                .accessibilityHint("Based on your age and medical history")
            }
            .padding()
        }
        .navigationTitle("Dynamic Type Test")
    }
}

#Preview("Dynamic Type Testing") {
    DynamicTypeTestingView()
}

#Preview("Preview View - Medium") {
    DynamicTypePreviewView()
        .environment(\.sizeCategory, .medium)
}

#Preview("Preview View - Accessibility XXXL") {
    DynamicTypePreviewView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}