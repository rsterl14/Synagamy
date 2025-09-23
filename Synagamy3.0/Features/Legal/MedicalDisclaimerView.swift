//
//  MedicalDisclaimerView.swift
//  Synagamy3.0
//
//  Comprehensive medical disclaimer acceptance view.
//

import SwiftUI

struct MedicalDisclaimerView: View {
    @StateObject private var disclaimerManager = DisclaimerManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var hasScrolledToBottom = false
    @State private var acceptanceConfirmed = false
    @State private var showingCountryInfo = false
    
    let isFirstTime: Bool
    
    init(isFirstTime: Bool = false) {
        self.isFirstTime = isFirstTime
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        .red.opacity(0.05),
                        .orange.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: Brand.Spacing.lg) {
                            // Disclaimer sections
                            ForEach(Array(DisclaimerContent.sections.enumerated()), id: \.offset) { index, section in
                                DisclaimerSectionView(section: section, index: index + 1)
                                    .onAppear {
                                        if index == DisclaimerContent.sections.count - 1 {
                                            hasScrolledToBottom = true
                                        }
                                    }
                            }
                            
                            Divider()
                                .padding(.vertical, Brand.Spacing.sm)
                            
                            // Country-specific information
                            countrySpecificSection
                            
                            Divider()
                                .padding(.vertical, Brand.Spacing.sm)
                            
                            // Acknowledgment
                            acknowledgmentSection
                            
                            // Bottom spacing
                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, Brand.Spacing.lg)
                        .padding(.vertical, Brand.Spacing.lg)
                    }
                }
                
                // Floating accept button
                VStack {
                    Spacer()
                    acceptButton
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isFirstTime {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Country Info") {
                        showingCountryInfo = true
                    }
                    .font(Brand.Typography.bodySmall)
                }
            }
        }
        .sheet(isPresented: $showingCountryInfo) {
            CountrySpecificInfoView()
        }
        .onAppear {
            AccessibilityAnnouncement.announceScreenChanged()
        }
    }
    
    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Brand.Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Brand.Typography.headlineLarge)
                    .foregroundColor(Brand.Color.error)
                
                Text(DisclaimerContent.title)
                    .font(Brand.Typography.displayMedium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Please read this important information carefully before using Synagamy")
                .font(Brand.Typography.bodyMedium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isFirstTime {
                Text("You must accept this disclaimer to continue using the app")
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(Brand.Color.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, Brand.Spacing.lg)
        .padding(.vertical, Brand.Spacing.lg)
        .background(
            Rectangle()
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Country Specific Section
    
    private var countrySpecificSection: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            HStack {
                Image(systemName: "globe")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(Brand.Color.primary)
                
                Text("Regional Information")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(DisclaimerContent.countrySpecificNote)
                .font(Brand.Typography.bodySmall)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(Brand.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Acknowledgment Section
    
    private var acknowledgmentSection: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(Brand.Color.success)
                
                Text("Acknowledgment Required")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(DisclaimerContent.acknowledgmentText)
                .font(Brand.Typography.bodySmall)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Toggle("I have read and understood all sections above", isOn: $acceptanceConfirmed)
                .font(Brand.Typography.labelLarge)
                .toggleStyle(CheckboxToggleStyle())
                .accessibilityHint("Confirm you have read and understood the disclaimer")
        }
        .padding(Brand.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .fill(.green.opacity(0.05))
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Accept Button
    
    private var acceptButton: some View {
        VStack(spacing: Brand.Spacing.md) {
            if !hasScrolledToBottom {
                Text("Please scroll to the bottom to continue")
                    .font(Brand.Typography.bodySmall)
                    .foregroundColor(Brand.Color.warning)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: acceptDisclaimer) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accept & Continue")
                        .font(Brand.Typography.headlineMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Brand.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                        .fill(canAccept ? .green : .gray)
                )
            }
            .disabled(!canAccept)
            .animation(.easeInOut(duration: 0.2), value: canAccept)
            .accessibilityHint(canAccept ? "Accept the disclaimer and continue" : "Complete reading and confirm understanding first")
        }
        .padding(.horizontal, Brand.Spacing.lg)
        .padding(.bottom, Brand.Spacing.xxl)
        .background(
            LinearGradient(
                colors: [.clear, .white.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        )
    }
    
    // MARK: - Computed Properties
    
    private var canAccept: Bool {
        hasScrolledToBottom && acceptanceConfirmed
    }
    
    // MARK: - Actions
    
    private func acceptDisclaimer() {
        disclaimerManager.acceptDisclaimer()
        AccessibilityAnnouncement.announce("Medical disclaimer accepted. You can now use the app.")
        
        if isFirstTime {
            // Post notification for onboarding flow
            NotificationCenter.default.post(name: .disclaimerAccepted, object: nil)
        } else {
            // Regular dismiss for standalone view
            dismiss()
        }
    }
}

// MARK: - Supporting Views

private struct DisclaimerSectionView: View {
    let section: DisclaimerSection
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(section.priority.color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: section.icon)
                        .font(Brand.Typography.headlineMedium)
                        .foregroundColor(section.priority.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(index). \(section.title)")
                        .font(Brand.Typography.labelLarge)
                        .foregroundColor(.primary)
                    
                    if section.priority == .critical {
                        Text("CRITICAL")
                            .font(Brand.Typography.labelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, Brand.Spacing.xs)
                            .padding(.vertical, Brand.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.red)
                            )
                    }
                }
                
                Spacer()
            }
            
            Text(section.content)
                .font(Brand.Typography.bodySmall)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(Brand.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .fill(.regularMaterial)
                .stroke(section.priority.color.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.title). \(section.content)")
    }
}

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? Brand.Color.success : .secondary)
                    .font(Brand.Typography.headlineMedium)
                
                configuration.label
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CountrySpecificInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Regional Healthcare Information")
                        .font(Brand.Typography.displayMedium)
                        .padding(.bottom, 8)
                    
                    CountryInfoSection(
                        country: "Canada",
                        flag: "🇨🇦",
                        info: "Healthcare professionals are regulated by provincial medical colleges. For fertility care, consult with physicians certified by the Royal College of Physicians and Surgeons of Canada in Reproductive Endocrinology and Infertility.",
                        resources: [
                            "College of Physicians and Surgeons (Provincial)",
                            "Canadian Fertility and Andrology Society (CFAS)",
                            "Society of Obstetricians and Gynaecologists of Canada (SOGC)"
                        ]
                    )
                    
                    CountryInfoSection(
                        country: "United States",
                        flag: "🇺🇸",
                        info: "Healthcare professionals are licensed by state medical boards. For fertility care, look for physicians board-certified in Reproductive Endocrinology and Infertility by the American Board of Obstetrics and Gynecology.",
                        resources: [
                            "American Society for Reproductive Medicine (ASRM)",
                            "Society for Assisted Reproductive Technology (SART)",
                            "RESOLVE: National Infertility Association"
                        ]
                    )
                    
                    Spacer()
                }
                .padding(Brand.Spacing.lg)
            }
            .navigationTitle("Country Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct CountryInfoSection: View {
    let country: String
    let flag: String
    let info: String
    let resources: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            HStack {
                Text(flag)
                    .font(Brand.Typography.displayMedium)
                Text(country)
                    .font(Brand.Typography.headlineMedium)
                Spacer()
            }
            
            Text(info)
                .font(Brand.Typography.bodySmall)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Professional Resources:")
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(.primary)
                
                ForEach(resources, id: \.self) { resource in
                    Text("• \(resource)")
                        .font(Brand.Typography.bodySmall)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Brand.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Brand.Radius.md, style: .continuous)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let disclaimerAccepted = Notification.Name("disclaimerAccepted")
}

#Preview {
    MedicalDisclaimerView(isFirstTime: true)
}