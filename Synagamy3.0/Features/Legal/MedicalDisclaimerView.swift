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
                        LazyVStack(spacing: 20) {
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
                                .padding(.vertical, 8)
                            
                            // Country-specific information
                            countrySpecificSection
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Acknowledgment
                            acknowledgmentSection
                            
                            // Bottom spacing
                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
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
                    .font(.caption)
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text(DisclaimerContent.title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Please read this important information carefully before using Synagamy")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isFirstTime {
                Text("You must accept this disclaimer to continue using the app")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Country Specific Section
    
    private var countrySpecificSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("Regional Information")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(DisclaimerContent.countrySpecificNote)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Acknowledgment Section
    
    private var acknowledgmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("Acknowledgment Required")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(DisclaimerContent.acknowledgmentText)
                .font(.footnote)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Toggle("I have read and understood all sections above", isOn: $acceptanceConfirmed)
                .font(.subheadline.weight(.medium))
                .toggleStyle(CheckboxToggleStyle())
                .accessibilityHint("Confirm you have read and understood the disclaimer")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.green.opacity(0.05))
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Accept Button
    
    private var acceptButton: some View {
        VStack(spacing: 12) {
            if !hasScrolledToBottom {
                Text("Please scroll to the bottom to continue")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: acceptDisclaimer) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accept & Continue")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canAccept ? .green : .gray)
                )
            }
            .disabled(!canAccept)
            .animation(.easeInOut(duration: 0.2), value: canAccept)
            .accessibilityHint(canAccept ? "Accept the disclaimer and continue" : "Complete reading and confirm understanding first")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(section.priority.color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: section.icon)
                        .font(.headline)
                        .foregroundColor(section.priority.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(index). \(section.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    if section.priority == .critical {
                        Text("CRITICAL")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.red)
                            )
                    }
                }
                
                Spacer()
            }
            
            Text(section.content)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                    .foregroundColor(configuration.isOn ? .green : .secondary)
                    .font(.title3)
                
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
                        .font(.title2.weight(.bold))
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
                .padding(20)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(flag)
                    .font(.title)
                Text(country)
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            
            Text(info)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Professional Resources:")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                
                ForEach(resources, id: \.self) { resource in
                    Text("• \(resource)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
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