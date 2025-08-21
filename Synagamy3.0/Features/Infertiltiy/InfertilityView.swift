//
//  InfertilityView.swift
//  Synagamy3.0
//
//  Enhanced infertility information hub with patient-friendly content,
//  reference links, and connection to Education resources.
//

import SwiftUI

struct InfertilityView: View {
    // MARK: - Enhanced model with references and key points
    struct InfoItem: Identifiable, Decodable, Equatable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemIcon: String
        let description: String
        let keyPoints: [String]?
        let references: [Reference]?
        
        struct Reference: Decodable, Equatable {
            let title: String
            let url: String
        }
        
        enum CodingKeys: String, CodingKey {
            case title, subtitle, systemIcon, description, keyPoints, references
        }
    }

    // MARK: - Content loaded from JSON
    @State private var topics: [InfoItem] = []
    
    // MARK: - UI state
    @State private var selectedTopic: InfoItem? = nil
    @State private var errorMessage: String? = nil
    @State private var isLoading = true
    
    // MARK: - Categorized topics
    private var infertilityTopics: [InfoItem] {
        topics.filter { topic in
            topic.title.contains("Infertility") || 
            topic.title.contains("Causes")
        }
    }
    
    private var preservationTopics: [InfoItem] {
        topics.filter { topic in
            topic.title.contains("Fertility Preservation")
        }
    }
    
    private var supportTopics: [InfoItem] {
        topics.filter { topic in
            topic.title.contains("Support") || 
            topic.title.contains("Financial") || 
            topic.title.contains("Emotional")
        }
    }

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "StartingPointLogo",
            showHomeButton: true,
            usePopToRoot: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if isLoading {
                    ProgressView("Loading information...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                } else if topics.isEmpty {
                    EmptyStateView(
                        icon: "info.circle",
                        title: "No info available",
                        message: "Please check back later or explore Education topics."
                    )
                    .padding(.top, 8)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Brand.Spacing.xl) {
                            // Infertility Section
                            sectionHeader(title: "Infertility", icon: "person.2.slash")
                            
                            ForEach(infertilityTopics) { item in
                                Button {
                                    selectedTopic = item
                                } label: {
                                    BrandTile(
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        systemIcon: item.systemIcon,
                                        assetIcon: nil,
                                        isCompact: true
                                    )
                                }
                                .buttonStyle(BrandTileButtonStyle())
                                .accessibilityLabel(Text("\(item.title). \(item.subtitle). Tap to read more."))
                            }
                            
                            // Fertility Preservation Section
                            sectionHeader(title: "Fertility Preservation", icon: "snowflake")
                            
                            ForEach(preservationTopics) { item in
                                Button {
                                    selectedTopic = item
                                } label: {
                                    BrandTile(
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        systemIcon: item.systemIcon,
                                        assetIcon: nil,
                                        isCompact: true
                                    )
                                }
                                .buttonStyle(BrandTileButtonStyle())
                                .accessibilityLabel(Text("\(item.title). \(item.subtitle). Tap to read more."))
                            }
                            
                            // Support & Resources Section
                            sectionHeader(title: "Support & Resources", icon: "heart.circle")
                            
                            ForEach(supportTopics) { item in
                                Button {
                                    selectedTopic = item
                                } label: {
                                    BrandTile(
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        systemIcon: item.systemIcon,
                                        assetIcon: nil,
                                        isCompact: true
                                    )
                                }
                                .buttonStyle(BrandTileButtonStyle())
                                .accessibilityLabel(Text("\(item.title). \(item.subtitle). Tap to read more."))
                            }
                            
                            // Links to other sections
                            VStack(spacing: Brand.Spacing.md) {
                                // Link to Education section
                                NavigationLink(destination: EducationView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "book.fill")
                                            .font(.title3)
                                            .foregroundColor(Brand.ColorSystem.primary)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(Brand.ColorSystem.primary.opacity(0.1))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Explore More Topics")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text("Deep dive into fertility education")
                                                .font(.caption)
                                                .foregroundColor(Brand.ColorSystem.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(Brand.ColorSystem.secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Brand.ColorSystem.primary.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                // Link to Pathway section
                                NavigationLink(destination: PathwayView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "map.fill")
                                            .font(.title3)
                                            .foregroundColor(Brand.ColorSystem.primary)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(Brand.ColorSystem.primary.opacity(0.1))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Pathway Explorer")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text("Interactive fertility treatment paths")
                                                .font(.caption)
                                                .foregroundColor(Brand.ColorSystem.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(Brand.ColorSystem.secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Brand.ColorSystem.primary.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .padding(.top, Brand.Spacing.lg)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .task {
            loadInfertilityInfo()
        }
        
        // Error alert
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Please try again.")
        })

        // Enhanced detail sheet with references
        .sheet(item: $selectedTopic) { topic in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        // Category badge
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                            
                            Text(topic.subtitle.uppercased())
                                .font(.caption2.weight(.bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(Brand.ColorSystem.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Brand.ColorSystem.primary.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Title
                        Text(topic.title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Brand.ColorSystem.primary, Brand.ColorSystem.primary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 4)
                    
                    // Divider
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Brand.ColorSystem.primary.opacity(0.3), Brand.ColorSystem.primary.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 1)
                        .padding(.bottom, 4)
                    
                    // Overview section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.body)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Overview")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Brand.ColorSystem.primary)
                        }
                        
                        Text(topic.description)
                            .font(.callout)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [Brand.ColorToken.hairline, Brand.ColorToken.hairline.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    
                    // Key Points section (if available)
                    if let keyPoints = topic.keyPoints, !keyPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(Brand.ColorSystem.primary)
                                
                                Text("Key Points")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Brand.ColorSystem.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(keyPoints, id: \.self) { point in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(Brand.ColorSystem.primary)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)
                                        
                                        Text(point)
                                            .font(.callout)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Brand.ColorSystem.primary.opacity(0.03))
                            )
                        }
                    }
                    
                    // References section (if available)
                    if let references = topic.references, !references.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "link.circle.fill")
                                    .font(.body)
                                    .foregroundColor(Brand.ColorSystem.primary)
                                
                                Text("Learn More")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Brand.ColorSystem.primary)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(references, id: \.url) { reference in
                                    Link(destination: URL(string: reference.url) ?? URL(string: "https://www.google.com")!) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(reference.title)
                                                    .font(.footnote.weight(.medium))
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text(reference.url)
                                                    .font(.caption2)
                                                    .foregroundColor(Brand.ColorSystem.secondary)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.up.right.square")
                                                .font(.caption)
                                                .foregroundColor(Brand.ColorSystem.primary)
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .tint(Brand.ColorSystem.primary)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Load data from JSON
    private func loadInfertilityInfo() {
        Task { @MainActor in
            isLoading = true
            
            // Load from JSON file
            if let url = Bundle.main.url(forResource: "infertility_info", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([InfoItem].self, from: data) {
                topics = decoded
            } else {
                // Fallback to basic data if JSON fails
                topics = [
                    InfoItem(
                        title: "What is Infertility?",
                        subtitle: "Understanding your diagnosis",
                        systemIcon: "person.2.slash",
                        description: "If you've been trying to conceive for 12 months without success (or 6 months if you're over 35), you may be experiencing infertility.",
                        keyPoints: nil,
                        references: nil
                    )
                ]
                errorMessage = "Some content may be unavailable"
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Section header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(Brand.ColorSystem.primary)
            
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, Brand.Spacing.md)
    }
}