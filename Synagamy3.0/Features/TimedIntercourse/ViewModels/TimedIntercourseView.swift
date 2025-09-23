//
//  TimedIntercourseView.swift
//  Synagamy3.0
//
//  Timed intercourse tracking and timing analysis system.
//  Helps users optimize timing for conception based on menstrual cycle data.
//

import SwiftUI

struct TimedIntercourseView: View {
    @StateObject private var viewModel = TimedIntercourseViewModel()
    @State private var showingCycleInput = false
    @State private var isEducationExpanded = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "CycleTrackingLogo",
            showHomeButton: true,
            usePopToRoot: true,
            showBackButton: true
        ) {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    
                    // MARK: - Header Section
                    headerSection
                    
                    // MARK: - Current Cycle Status
                    if viewModel.hasCurrentCycle {
                        currentCycleSection
                    } else {
                        cycleInputSection
                    }
                    
                    // MARK: - Fertility Window
                    if viewModel.hasCurrentCycle {
                        fertilityWindowSection
                    }
                    
                    // MARK: - Timing Analysis
                    if viewModel.hasCurrentCycle {
                        timingAnalysisSection
                    }
                    
                    // MARK: - Educational Content
                    educationalSection
                }
                .padding(.vertical, Brand.Spacing.lg)
            }
        }
        .sheet(isPresented: $showingCycleInput) {
            CycleInputSheetView(viewModel: viewModel, isPresented: $showingCycleInput)
        }
        .alert("Reset Cycle Information", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.clearCycle()
            }
        } message: {
            Text("This will clear your current cycle information. You'll need to enter your cycle details again to get timing analysis.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Brand.Spacing.md) {
            CategoryBadge(
                text: "Timed Intercourse",
                icon: "heart.circle.fill",
                color: Brand.Color.primary
            )
            
            Text("Natural Conception Optimization")
                .font(Brand.Typography.headlineMedium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Evidence-Based Timing for Maximum Conception Probability")
                .font(Brand.Typography.bodySmall)
                .foregroundColor(Brand.Color.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Cycle Input Section
    private var cycleInputSection: some View {
        EnhancedContentBlock(
            title: "Track Your Cycle",
            icon: "calendar.badge.plus"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Brand.Color.primary)
                
                Text("Get Started with Cycle Tracking")
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Enter your cycle information to receive personalized timing analysis for conception")
                    .font(Brand.Typography.bodyMedium)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { showingCycleInput = true }) {
                    HStack(spacing: Brand.Spacing.sm) {
                        Image(systemName: "calendar.badge.plus")
                            .font(Brand.Typography.headlineMedium)
                        Text("Enter Cycle Data")
                            .font(Brand.Typography.headlineMedium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(Brand.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                            .fill(Brand.Color.primary)
                    )
                }
            }
        }
    }
    
    // MARK: - Current Cycle Section
    private var currentCycleSection: some View {
        EnhancedContentBlock(
            title: "Current Cycle Status",
            icon: "calendar.circle"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                if let cycle = viewModel.currentCycle {
                    // Cycle Day Display
                    HStack {
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            Text("Day \(cycle.currentDay)")
                                .font(.title.weight(.bold))
                                .foregroundColor(Brand.Color.primary)
                            Text("of \(cycle.averageLength) day cycle")
                                .font(.subheadline)
                                .foregroundColor(Brand.Color.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(viewModel.cyclePhaseDescription)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: Brand.Spacing.md) {
                                Button("Reset") {
                                    showingResetConfirmation = true
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(.red)
                                
                                Button("Update Cycle") {
                                    showingCycleInput = true
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(Brand.Color.primary)
                            }
                        }
                    }
                    
                    // Cycle Timeline
                    if let window = viewModel.currentFertilityWindow {
                        cycleTimelineView(window: window)
                    }
                    
                    // Fertility Status
                    if let status = viewModel.currentFertilityStatus {
                        HStack(alignment: .center, spacing: Brand.Spacing.md) {
                            Circle()
                                .fill(status.color)
                                .frame(width: 16, height: 16)
                            
                            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                                Text(status.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                
                                Text(status.description)
                                    .font(.caption)
                                    .foregroundColor(Brand.Color.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                .fill(status.color.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Fertility Window Section
    private var fertilityWindowSection: some View {
        EnhancedContentBlock(
            title: "Fertility Calendar",
            icon: "calendar.circle.fill"
        ) {
            VStack(spacing: Brand.Spacing.lg) {
                if let fertilityWindow = viewModel.currentFertilityWindow {
                    // Calendar Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Brand.Spacing.sm) {
                        ForEach(fertilityWindow.calendarDays, id: \.day) { dayInfo in
                            VStack(spacing: Brand.Spacing.xs) {
                                Text("\(dayInfo.day)")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(dayInfo.isCurrentDay ? .white : .primary)
                                
                                Circle()
                                    .fill(dayInfo.fertilityColor)
                                    .frame(width: 8, height: 8)
                            }
                            .frame(width: 36, height: 44)
                            .background(
                                Circle()
                                    .fill(dayInfo.isCurrentDay ? Brand.Color.primary : Color.clear)
                                    .frame(width: 32, height: 32)
                            )
                        }
                    }
                    
                    // Legend
                    HStack(spacing: Brand.Spacing.lg) {
                        legendItem(color: Color.red, label: "Period")
                        legendItem(color: Color.green, label: "Fertile")
                        legendItem(color: Color.orange, label: "Ovulation")
                        legendItem(color: Color.gray.opacity(0.3), label: "Other")
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Brand.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(Brand.Color.secondary)
        }
    }
    
    // MARK: - Timing Analysis Section
    private var timingAnalysisSection: some View {
        EnhancedContentBlock(
            title: "Current Timing Analysis",
            icon: "lightbulb.circle"
        ) {
            VStack(spacing: Brand.Spacing.md) {
                ForEach(viewModel.currentTimingAnalysis, id: \.id) { timing in
                    HStack(alignment: .top, spacing: Brand.Spacing.md) {
                        // Priority indicator
                        ZStack {
                            Circle()
                                .fill(timing.priority.color.opacity(0.15))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: timing.icon)
                                .font(.caption.weight(.bold))
                                .foregroundColor(timing.priority.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(timing.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            Text(timing.description)
                                .font(.caption)
                                .foregroundColor(Brand.Color.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.sm)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                    .stroke(Brand.Color.hairline, lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Educational Section
    private var educationalSection: some View {
        ExpandableSection(
            title: "Understanding Timed Intercourse",
            subtitle: "Evidence-based guidance for conception",
            icon: "book.circle",
            isExpanded: $isEducationExpanded
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Key Concepts")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    EducationalStepView(
                        number: "1",
                        title: "Fertile Window",
                        description: "The 6-day period ending on ovulation day when conception is most likely to occur."
                    )
                    
                    EducationalStepView(
                        number: "2",
                        title: "Ovulation Timing",
                        description: "Typically occurs 12-16 days before the next menstrual period, regardless of cycle length."
                    )
                    
                    EducationalStepView(
                        number: "3",
                        title: "Sperm Survival",
                        description: "Sperm can survive in the reproductive tract for up to 5 days under optimal conditions."
                    )
                    
                    EducationalStepView(
                        number: "4",
                        title: "Optimal Frequency",
                        description: "Every 2-3 days throughout the cycle, daily during the fertile window for best results."
                    )
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Success Rates")
                        .font(Brand.Typography.labelSmall)
                        .foregroundColor(Brand.Color.primary)
                    
                    Text("• 15-25% chance per cycle for couples without fertility issues")
                    Text("• 80% of couples under 35 conceive within 6 months")
                    Text("• 90% of couples under 35 conceive within 12 months")
                }
                .font(.caption)
                .foregroundColor(Brand.Color.secondary)
            }
        }
    }
    
    // MARK: - Methodology Section (Hidden)
    /*
    private var methodologySection: some View {
        ExpandableSection(
            title: "How Our Algorithm Works",
            subtitle: "Medical evidence and calculation methods",
            icon: "brain.head.profile",
            isExpanded: $isMethodologyExpanded
        ) {
            VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                Text("Prediction Methodology")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                    EducationalStepView(
                        number: "1",
                        title: "Luteal Phase Calculation",
                        description: "Uses the standard 14-day luteal phase to predict ovulation timing from your cycle length."
                    )
                    
                    EducationalStepView(
                        number: "2",
                        title: "Fertile Window Mapping",
                        description: "Identifies the 6-day fertile window: 5 days before ovulation plus ovulation day."
                    )
                    
                    EducationalStepView(
                        number: "3",
                        title: "Phase Classification",
                        description: "Categorizes each cycle day into menstrual, follicular, fertile, ovulation, or luteal phases."
                    )
                    
                    EducationalStepView(
                        number: "4",
                        title: "Timing Analysis Engine",
                        description: "Generates personalized timing analysis based on current cycle phase and proximity to ovulation."
                    )
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Clinical Guidelines")
                        .font(Brand.Typography.labelSmall)
                        .foregroundColor(Brand.Color.primary)
                    
                    Text("• American College of Obstetricians and Gynecologists (ACOG)")
                    Text("• Society for Reproductive Endocrinology and Infertility (SREI)")
                    Text("• World Health Organization (WHO) fertility guidelines")
                    Text("• European Society of Human Reproduction and Embryology (ESHRE)")
                }
                .font(.caption)
                .foregroundColor(Brand.Color.secondary)
            }
        }
    }
    */
    
    // MARK: - Cycle Timeline View
    private func cycleTimelineView(window: FertilityWindow) -> some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text("Cycle Timeline")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            
            // Timeline bars
            VStack(alignment: .leading, spacing: 8) {
                // Period phase
                timelineBar(
                    title: "Period",
                    color: .red,
                    startDay: 1,
                    endDay: window.cycle.periodLength,
                    totalDays: window.cycle.averageLength,
                    currentDay: window.cycle.currentDay
                )
                
                // Fertile window
                let ovulationDay = window.cycle.averageLength - window.cycle.lutealPhaseLength
                let fertileStart = ovulationDay - 5
                let fertileEnd = ovulationDay + 1
                
                timelineBar(
                    title: "Fertile Window",
                    color: .green,
                    startDay: fertileStart,
                    endDay: fertileEnd,
                    totalDays: window.cycle.averageLength,
                    currentDay: window.cycle.currentDay
                )
                
                // Ovulation (peak fertility)
                timelineBar(
                    title: "Ovulation",
                    color: .orange,
                    startDay: ovulationDay,
                    endDay: ovulationDay + 1,
                    totalDays: window.cycle.averageLength,
                    currentDay: window.cycle.currentDay
                )
            }
            
            // Legend
            HStack(spacing: Brand.Spacing.lg) {
                legendItem(color: .red, text: "Period")
                legendItem(color: .green, text: "Fertile")
                legendItem(color: .orange, text: "Ovulation")
                Spacer()
                legendItem(color: Brand.Color.primary, text: "Today")
            }
            .font(.caption)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Timeline Bar Component
    private func timelineBar(title: String, color: Color, startDay: Int, endDay: Int, totalDays: Int, currentDay: Int) -> some View {
        HStack(spacing: Brand.Spacing.sm) {
            // Title
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            // Timeline bar
            GeometryReader { geometry in
                let barWidth = geometry.size.width
                let startPercent = Double(max(1, startDay) - 1) / Double(totalDays)
                let endPercent = Double(min(totalDays, endDay)) / Double(totalDays)
                let currentPercent = Double(currentDay - 1) / Double(totalDays)
                
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: Brand.Radius.sm)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Active phase bar
                    RoundedRectangle(cornerRadius: Brand.Radius.sm)
                        .fill(color.opacity(0.6))
                        .frame(
                            width: barWidth * (endPercent - startPercent),
                            height: 12
                        )
                        .offset(x: barWidth * startPercent)
                    
                    // Current day indicator
                    Circle()
                        .fill(Brand.Color.primary)
                        .frame(width: 16, height: 16)
                        .offset(x: barWidth * currentPercent - 8)
                        .opacity(currentDay >= 1 && currentDay <= totalDays ? 1 : 0)
                }
            }
            .frame(height: 16)
        }
    }
    
    // MARK: - Legend Item
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: Brand.Spacing.xs) {
            if text == "Today" {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.6))
                    .frame(width: 12, height: 8)
            }
            Text(text)
                .foregroundColor(Brand.Color.secondary)
        }
    }
}

// MARK: - Educational Step View Component
private struct EducationalStepView: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(Brand.Color.primary.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Brand.Color.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(Brand.Color.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Cycle Input Sheet

struct CycleInputSheetView: View {
    @ObservedObject var viewModel: TimedIntercourseViewModel
    @Binding var isPresented: Bool
    
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
                    VStack(spacing: 12) {
                        CategoryBadge(
                            text: "Cycle Tracking",
                            icon: "calendar.badge.plus",
                            color: Brand.Color.primary
                        )
                        
                        Text("Enter Your Cycle Information")
                            .font(Brand.Typography.headlineMedium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Personalized timing analysis based on your cycle data")
                            .font(Brand.Typography.bodySmall)
                            .foregroundColor(Brand.Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // MARK: - Input Form
                    EnhancedContentBlock(
                        title: "Cycle Parameters",
                        icon: "person.text.rectangle"
                    ) {
                        VStack(spacing: Brand.Spacing.lg) {
                            // Last Period Date
                            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                                Text("Last Period Start Date")
                                    .font(Brand.Typography.labelLarge)
                                    .foregroundColor(.primary)
                                
                                Button {
                                    showingDatePicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(Brand.Color.primary)
                                        
                                        Text(lastPeriodDate, style: .date)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Brand.Color.secondary)
                                    }
                                    .padding(Brand.Spacing.lg)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.sm))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Brand.Radius.sm)
                                            .stroke(Brand.Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Text("First day of your most recent menstrual period")
                                    .font(Brand.Typography.bodySmall)
                                    .foregroundColor(Brand.Color.secondary)
                            }
                            
                            // Average Cycle Length
                            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                                Text("Average Cycle Length (days)")
                                    .font(Brand.Typography.labelLarge)
                                    .foregroundColor(.primary)
                                
                                Picker("Cycle Length", selection: $averageLength) {
                                    ForEach(cycleLengthOptions, id: \.self) { length in
                                        Text("\(length) days")
                                            .tag(length)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 120)
                                
                                Text("Days from start of one period to start of next (typical: 28 days)")
                                    .font(Brand.Typography.bodySmall)
                                    .foregroundColor(Brand.Color.secondary)
                            }
                            
                            // Period Length
                            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                                Text("Period Length (days)")
                                    .font(Brand.Typography.labelLarge)
                                    .foregroundColor(.primary)
                                
                                Picker("Period Length", selection: $periodLength) {
                                    ForEach(periodLengthOptions, id: \.self) { length in
                                        Text("\(length) days")
                                            .tag(length)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .tint(Brand.Color.primary)
                                
                                Text("How many days your period typically lasts")
                                    .font(Brand.Typography.bodySmall)
                                    .foregroundColor(Brand.Color.secondary)
                            }
                        }
                    }
                    
                    // MARK: - Information Card
                    EnhancedContentBlock(
                        title: "How We Calculate",
                        icon: "brain.head.profile"
                    ) {
                        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                            Text("Algorithm Methodology")
                                .font(Brand.Typography.labelLarge)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                                Text("• Ovulation prediction uses standard 14-day luteal phase")
                                Text("• Fertile window: 5 days before + 1 day after ovulation")
                                Text("• Sperm survival: up to 5 days in optimal conditions")
                                Text("• Egg viability: 12-24 hours after ovulation")
                            }
                            .font(Brand.Typography.bodySmall)
                            .foregroundColor(Brand.Color.secondary)
                        }
                    }
                    
                    Spacer(minLength: Brand.Spacing.xl)
                }
                .padding(.horizontal, Brand.Spacing.lg)
                .padding(.vertical, Brand.Spacing.lg)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Brand.Color.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .foregroundColor(Brand.Color.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheetView(selectedDate: $lastPeriodDate)
        }
        .onAppear {
            setupInitialValues()

            // VoiceOver announcement
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Timed intercourse tracker loaded. Track your menstrual cycle to optimize conception timing."
                )
            }
        }
        .registerForAccessibilityAudit(
            viewName: "TimedIntercourseView",
            hasAccessibilityLabels: true,
            hasDynamicTypeSupport: true,
            hasVoiceOverSupport: true
        )
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
        
        isPresented = false
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheetView: View {
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
                    .foregroundColor(Brand.Color.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Timed Intercourse Info Sheet

struct TimedIntercourseInfoSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Spacing.xl) {
                    
                    // MARK: - Header
                    VStack(spacing: Brand.Spacing.md) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Brand.Color.primary)
                        
                        Text("Timed Intercourse")
                            .font(Brand.Typography.displayMedium)
                            .foregroundColor(Brand.Color.textPrimary)
                        
                        Text("Understanding fertility timing for conception")
                            .font(Brand.Typography.bodyMedium)
                            .foregroundColor(Brand.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Brand.Spacing.lg)
                    
                    // MARK: - What is Timed Intercourse
                    infoSection(
                        title: "What is Timed Intercourse?",
                        icon: "clock.circle",
                        content: "Timed intercourse involves timing sexual activity to coincide with a woman's most fertile days during her menstrual cycle. This natural approach maximizes the chances of conception by ensuring sperm are present when ovulation occurs."
                    )
                    
                    // MARK: - How It Works
                    infoSection(
                        title: "How It Works",
                        icon: "gearshape.circle",
                        content: "The timing is based on predicting ovulation, which typically occurs 12-16 days before the next menstrual period. The fertile window includes the 5 days before ovulation and the day of ovulation, as sperm can survive up to 5 days in the reproductive tract."
                    )
                    
                    // MARK: - Success Rates
                    infoSection(
                        title: "Success Rates",
                        icon: "chart.line.uptrend.xyaxis.circle",
                        content: "For couples with no fertility issues, timed intercourse has a 15-25% chance of success per cycle. Over 6 months, approximately 80% of couples under 35 will conceive using this method."
                    )
                    
                    // MARK: - Best Practices
                    VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Brand.Color.success)
                            
                            Text("Best Practices")
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.Color.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                            practiceItem(
                                title: "Track Your Cycle",
                                description: "Monitor cycle length and ovulation signs for 2-3 months"
                            )
                            
                            practiceItem(
                                title: "Optimal Frequency",
                                description: "Every 2-3 days throughout the cycle, daily during fertile window"
                            )
                            
                            practiceItem(
                                title: "Reduce Stress",
                                description: "Maintain a relaxed approach to avoid performance anxiety"
                            )
                            
                            practiceItem(
                                title: "Healthy Lifestyle",
                                description: "Regular exercise, balanced diet, and adequate sleep"
                            )
                            
                            practiceItem(
                                title: "Prenatal Vitamins",
                                description: "Start folic acid supplementation before conception"
                            )
                        }
                    }
                    .padding(Brand.Spacing.lg)
                    .brandCardStyle()
                    
                    // MARK: - When to Seek Help
                    VStack(alignment: .leading, spacing: Brand.Spacing.lg) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Brand.Color.warning)
                            
                            Text("When to Consult a Doctor")
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.Color.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            Text("• After 6 months of trying (if over 35)")
                            Text("• After 12 months of trying (if under 35)")
                            Text("• Irregular or absent periods")
                            Text("• Known fertility issues")
                            Text("• Previous pregnancy complications")
                        }
                        .font(Brand.Typography.bodyMedium)
                        .foregroundColor(Brand.Color.textSecondary)
                    }
                    .padding(Brand.Spacing.lg)
                    .background(Brand.Color.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg))
                    
                    // MARK: - Disclaimer
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Brand.Color.info)
                            
                            Text("Medical Disclaimer")
                                .font(Brand.Typography.labelLarge)
                                .foregroundColor(Brand.Color.textPrimary)
                        }
                        
                        Text("This information is for educational purposes only and should not replace professional medical advice. Individual fertility varies, and factors such as age, health conditions, and lifestyle can affect conception rates. Always consult with a healthcare provider for personalized guidance.")
                            .font(Brand.Typography.bodySmall)
                            .foregroundColor(Brand.Color.textSecondary)
                    }
                    .padding(Brand.Spacing.lg)
                    .background(Brand.Color.info.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg))
                    
                    Spacer(minLength: Brand.Spacing.xl)
                }
                .padding(.horizontal, Brand.Spacing.lg)
            }
            .navigationTitle("About Timed Intercourse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Brand.Color.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func infoSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Brand.Color.primary)
                
                Text(title)
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(Brand.Color.textPrimary)
            }
            
            Text(content)
                .font(Brand.Typography.bodyMedium)
                .foregroundColor(Brand.Color.textSecondary)
                .lineSpacing(4)
        }
        .padding(Brand.Spacing.lg)
        .brandCardStyle()
    }
    
    private func practiceItem(title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Brand.Color.success)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(Brand.Color.textPrimary)
                
                Text(description)
                    .font(Brand.Typography.bodySmall)
                    .foregroundColor(Brand.Color.textSecondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        TimedIntercourseView()
    }
}
