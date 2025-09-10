//
//  CycleInputSheet.swift
//  Synagamy3.0
//
//  Sheet for inputting menstrual cycle information.
//

import SwiftUI

struct CycleInputSheet: View {
    @ObservedObject var viewModel: TimedIntercourseViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var lastPeriodDate = Date()
    @State private var averageLength = 28
    @State private var periodLength = 5
    @State private var showingDatePicker = false
    
    private let cycleLengthOptions = Array(21...35)
    private let periodLengthOptions = Array(3...7)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    
                    // MARK: - Header
                    VStack(spacing: Brand.Spacing.md) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Brand.ColorSystem.primary)
                        
                        Text("Track Your Cycle")
                            .font(Brand.Typography.displayMedium)
                            .foregroundColor(Brand.ColorSystem.textPrimary)
                        
                        Text("Enter your cycle information to receive personalized timing analysis")
                            .font(Brand.Typography.bodyMedium)
                            .foregroundColor(Brand.ColorSystem.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Brand.Spacing.lg)
                    
                    // MARK: - Input Sections
                    VStack(spacing: Brand.Spacing.xl) {
                        
                        // Last Period Date
                        inputSection(
                            title: "Last Period Start Date",
                            description: "When did your last period begin?"
                        ) {
                            Button {
                                showingDatePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Brand.ColorSystem.primary)
                                    
                                    Text(lastPeriodDate, style: .date)
                                        .foregroundColor(Brand.ColorSystem.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Brand.ColorSystem.textTertiary)
                                }
                                .padding(Brand.Spacing.lg)
                                .background(Brand.ColorSystem.surfaceCard)
                                .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.lg)
                                        .stroke(Brand.ColorSystem.primary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Average Cycle Length
                        inputSection(
                            title: "Average Cycle Length",
                            description: "How many days from the start of one period to the start of the next?"
                        ) {
                            Picker("Cycle Length", selection: $averageLength) {
                                ForEach(cycleLengthOptions, id: \.self) { length in
                                    Text("\(length) days")
                                        .tag(length)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                        
                        // Period Length
                        inputSection(
                            title: "Period Length",
                            description: "How many days does your period typically last?"
                        ) {
                            Picker("Period Length", selection: $periodLength) {
                                ForEach(periodLengthOptions, id: \.self) { length in
                                    Text("\(length) days")
                                        .tag(length)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    
                    // MARK: - Information Card
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Brand.ColorSystem.info)
                            
                            Text("How We Calculate")
                                .font(Brand.Typography.labelLarge)
                                .foregroundColor(Brand.ColorSystem.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            Text("• Ovulation typically occurs 14 days before your next period")
                            Text("• The fertile window is 5 days before and 1 day after ovulation")
                            Text("• Sperm can survive up to 5 days in the reproductive tract")
                            Text("• An egg survives 12-24 hours after ovulation")
                        }
                        .font(Brand.Typography.bodySmall)
                        .foregroundColor(Brand.ColorSystem.textSecondary)
                    }
                    .padding(Brand.Spacing.lg)
                    .background(Brand.ColorSystem.info.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg))
                    
                    Spacer(minLength: Brand.Spacing.xl)
                }
                .padding(.horizontal, Brand.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Brand.ColorSystem.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .foregroundColor(Brand.ColorSystem.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $lastPeriodDate)
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func inputSection<Content: View>(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                Text(title)
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(Brand.ColorSystem.textPrimary)
                
                Text(description)
                    .font(Brand.Typography.bodySmall)
                    .foregroundColor(Brand.ColorSystem.textSecondary)
            }
            
            content()
        }
        .padding(Brand.Spacing.lg)
        .brandCardStyle()
    }
    
    private func setupInitialValues() {
        if let existingCycle = viewModel.currentCycle {
            lastPeriodDate = existingCycle.lastPeriodDate
            averageLength = existingCycle.averageLength
            periodLength = existingCycle.periodLength
        } else {
            // Default to a recent date for new users
            lastPeriodDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
    }
    
    private func saveAndDismiss() {
        viewModel.updateCycle(
            lastPeriodDate: lastPeriodDate,
            averageLength: averageLength,
            periodLength: periodLength
        )
        
        // Haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        
        dismiss()
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Last Period Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Brand.ColorSystem.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CycleInputSheet(viewModel: TimedIntercourseViewModel())
}
