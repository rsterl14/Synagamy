//
//  TimedIntercourseInfoSheet.swift
//  Synagamy3.0
//
//  Educational information sheet about timed intercourse.
//

import SwiftUI

struct TimedIntercourseInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Spacing.xl) {
                    
                    // MARK: - Header
                    VStack(spacing: Brand.Spacing.md) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Brand.ColorSystem.primary)
                        
                        Text("Timed Intercourse")
                            .font(Brand.Typography.displayMedium)
                            .foregroundColor(Brand.ColorSystem.textPrimary)
                        
                        Text("Understanding fertility timing for conception")
                            .font(Brand.Typography.bodyMedium)
                            .foregroundColor(Brand.ColorSystem.textSecondary)
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
                                .foregroundColor(Brand.ColorSystem.success)
                            
                            Text("Best Practices")
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.ColorSystem.textPrimary)
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
                                .foregroundColor(Brand.ColorSystem.warning)
                            
                            Text("When to Consult a Doctor")
                                .font(Brand.Typography.headlineMedium)
                                .foregroundColor(Brand.ColorSystem.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                            Text("• After 6 months of trying (if over 35)")
                            Text("• After 12 months of trying (if under 35)")
                            Text("• Irregular or absent periods")
                            Text("• Known fertility issues")
                            Text("• Previous pregnancy complications")
                        }
                        .font(Brand.Typography.bodyMedium)
                        .foregroundColor(Brand.ColorSystem.textSecondary)
                    }
                    .padding(Brand.Spacing.lg)
                    .background(Brand.ColorSystem.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.lg))
                    
                    // MARK: - Disclaimer
                    VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Brand.ColorSystem.info)
                            
                            Text("Medical Disclaimer")
                                .font(Brand.Typography.labelLarge)
                                .foregroundColor(Brand.ColorSystem.textPrimary)
                        }
                        
                        Text("This information is for educational purposes only and should not replace professional medical advice. Individual fertility varies, and factors such as age, health conditions, and lifestyle can affect conception rates. Always consult with a healthcare provider for personalized guidance.")
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
            .navigationTitle("About Timed Intercourse")
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
    }
    
    private func infoSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Brand.ColorSystem.primary)
                
                Text(title)
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(Brand.ColorSystem.textPrimary)
            }
            
            Text(content)
                .font(Brand.Typography.bodyMedium)
                .foregroundColor(Brand.ColorSystem.textSecondary)
                .lineSpacing(4)
        }
        .padding(Brand.Spacing.lg)
        .brandCardStyle()
    }
    
    private func practiceItem(title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Brand.Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Brand.ColorSystem.success)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(Brand.ColorSystem.textPrimary)
                
                Text(description)
                    .font(Brand.Typography.bodySmall)
                    .foregroundColor(Brand.ColorSystem.textSecondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    TimedIntercourseInfoSheet()
}