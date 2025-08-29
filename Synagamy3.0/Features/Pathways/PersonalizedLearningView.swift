//
//  PersonalizedLearningView.swift
//  Synagamy3.0
//
//  Displays saved fertility cycles with personalized learning experience.
//  Shows pathway steps with organized related topics for focused learning.
//

import SwiftUI

struct PersonalizedLearningView: View {
    @StateObject private var cycleManager = PersonalizedCycleManager()
    @State private var showingCycleDetail: SavedCycle?
    @State private var showingDeleteConfirmation: SavedCycle?
    @State private var editingCycle: SavedCycle?
    @State private var newCycleName: String = ""
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "PathwayLogo",
            showHomeButton: true,
            usePopToRoot: true,
            showBackButton: true
        ) {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    
                    // MARK: - Header Section
                    headerSection
                    
                    // MARK: - Saved Cycles
                    if cycleManager.savedCycles.isEmpty {
                        emptyStateSection
                    } else {
                        savedCyclesSection
                    }
                }
                .padding(.vertical, Brand.Spacing.lg)
            }
        }
        .sheet(item: $showingCycleDetail) { cycle in
            PersonalizedCycleDetailView(cycle: cycle, cycleManager: cycleManager)
        }
        .alert("Delete Cycle", isPresented: .constant(showingDeleteConfirmation != nil)) {
            Button("Delete", role: .destructive) {
                if let cycle = showingDeleteConfirmation {
                    cycleManager.deleteCycle(cycle)
                }
                showingDeleteConfirmation = nil
            }
            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = nil
            }
        } message: {
            if let cycle = showingDeleteConfirmation {
                Text("Are you sure you want to delete '\(cycle.name)'? This action cannot be undone.")
            }
        }
        .alert("Rename Cycle", isPresented: .constant(editingCycle != nil)) {
            TextField("New name", text: $newCycleName)
                .textInputAutocapitalization(.words)
            Button("Save") {
                if let cycle = editingCycle, !newCycleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    cycleManager.renameCycle(cycle, newName: newCycleName)
                }
                editingCycle = nil
                newCycleName = ""
            }
            Button("Cancel", role: .cancel) {
                editingCycle = nil
                newCycleName = ""
            }
        } message: {
            Text("Enter a new name for this cycle")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            CategoryBadge(
                text: "My Cycles",
                icon: "bookmark.fill",
                color: Brand.ColorSystem.primary
            )
            
            Text("Personalized Learning Experience")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Review your saved fertility pathways with organized educational content for each step")
                .font(.caption)
                .foregroundColor(Brand.ColorSystem.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Brand.Spacing.lg)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        EnhancedContentBlock(
            title: "No Saved Cycles",
            icon: "bookmark"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                EmptyStateView(
                    icon: "bookmark.slash",
                    title: "No saved cycles yet",
                    message: "Complete the pathway questionnaire and save a cycle to create your personalized learning experience."
                )
                
                NavigationLink {
                    PathwayView()
                } label: {
                    HStack(spacing: 8) {
                        Text("Discover Pathways")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.ColorSystem.primary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Saved Cycles Section
    private var savedCyclesSection: some View {
        EnhancedContentBlock(
            title: "Your Saved Cycles (\(cycleManager.savedCycles.count))",
            icon: "bookmark.fill"
        ) {
            VStack(spacing: Brand.Spacing.md) {
                ForEach(cycleManager.savedCycles) { cycle in
                    SavedCycleCard(
                        cycle: cycle,
                        onTap: {
                            cycleManager.updateLastAccessed(for: cycle.id)
                            showingCycleDetail = cycle
                        },
                        onEdit: {
                            newCycleName = cycle.name
                            editingCycle = cycle
                        },
                        onDelete: {
                            showingDeleteConfirmation = cycle
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Saved Cycle Card

private struct SavedCycleCard: View {
    let cycle: SavedCycle
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cycle.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(cycle.category)
                            .font(.caption)
                    }
                    .foregroundColor(Brand.ColorSystem.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(Brand.ColorSystem.secondary)
                }
            }
            
            // Pathway Info
            VStack(alignment: .leading, spacing: 6) {
                Text(cycle.pathway.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Brand.ColorSystem.primary)
                
                if let description = cycle.pathway.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Brand.ColorSystem.secondary)
                        .lineLimit(2)
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.caption2)
                    Text("\(cycle.pathway.steps.count) steps")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("\(cycle.daysSinceCreated) days ago")
                        .font(.caption)
                }
                
                Spacer()
                
                Button {
                    onTap()
                } label: {
                    HStack(spacing: 6) {
                        Text("Learn")
                            .font(.caption.weight(.medium))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Brand.ColorSystem.primary)
                    )
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(Brand.ColorSystem.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Brand.ColorToken.hairline, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    PersonalizedLearningView()
}