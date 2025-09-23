//
//  DisclaimerManager.swift
//  Synagamy3.0
//
//  Manages medical disclaimer acceptance and display.
//

import SwiftUI

class DisclaimerManager: ObservableObject {
    @AppStorage("hasAcceptedMedicalDisclaimer") private var hasAcceptedMedicalDisclaimer = false
    @AppStorage("disclaimerVersion") private var disclaimerVersion = 0
    @AppStorage("disclaimerAcceptanceDate") private var disclaimerAcceptanceDateString = ""
    
    private let currentDisclaimerVersion = 2
    
    @Published var shouldShowDisclaimer = false
    
    var disclaimerAcceptanceDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: disclaimerAcceptanceDateString)
    }
    
    init() {
        checkDisclaimerStatus()
    }
    
    func checkDisclaimerStatus() {
        shouldShowDisclaimer = !hasAcceptedMedicalDisclaimer || disclaimerVersion < currentDisclaimerVersion
    }
    
    func acceptDisclaimer() {
        hasAcceptedMedicalDisclaimer = true
        disclaimerVersion = currentDisclaimerVersion
        
        let formatter = ISO8601DateFormatter()
        disclaimerAcceptanceDateString = formatter.string(from: Date())
        
        shouldShowDisclaimer = false
    }
    
    func requireDisclaimerReacceptance() {
        hasAcceptedMedicalDisclaimer = false
        checkDisclaimerStatus()
    }
    
    var hasAccepted: Bool {
        hasAcceptedMedicalDisclaimer && disclaimerVersion >= currentDisclaimerVersion
    }
}

// MARK: - Disclaimer Content

struct DisclaimerContent {
    static let title = "Important Medical Disclaimer"
    
    static let sections: [DisclaimerSection] = [
        DisclaimerSection(
            title: "Educational Purpose Only - NOT A MEDICAL DEVICE",
            content: "This application is designed exclusively for educational and informational purposes. The prediction algorithms, fertility tracking tools, and educational materials are NOT intended for medical decision making, diagnosis, or treatment. This software is NOT a medical device and has not been evaluated by FDA or Health Canada for safety, effectiveness, or regulatory compliance.",
            icon: "book.fill",
            priority: .critical
        ),
        
        DisclaimerSection(
            title: "Consult Healthcare Professionals",
            content: "Always consult with qualified healthcare professionals, including reproductive endocrinologists, fertility specialists, or your primary care physician, for personalized medical guidance regarding fertility, reproductive health, and treatment decisions.",
            icon: "stethoscope",
            priority: .critical
        ),
        
        DisclaimerSection(
            title: "Population-Based Predictions with High Uncertainty",
            content: "All predictions and calculations are based on population averages and statistical models with significant uncertainty. Individual outcomes may vary dramatically based on numerous medical, genetic, and biological factors not captured in this application. Prediction ranges show 80% confidence intervals - 20% of individuals will fall outside these ranges. These estimates should NEVER influence medical treatment decisions.",
            icon: "chart.bar.fill",
            priority: .critical
        ),
        
        DisclaimerSection(
            title: "FDA/Health Canada Regulatory Notice",
            content: "This application is NOT a medical device under FDA or Health Canada regulations. It has NOT been evaluated for safety, effectiveness, or accuracy by any regulatory authority. The software does not diagnose, treat, cure, or prevent any medical condition. Predictions are for educational exploration only and must not be used for medical decision making.",
            icon: "exclamationmark.triangle.fill",
            priority: .critical
        ),
        
        DisclaimerSection(
            title: "Emergency Situations",
            content: "In case of medical emergencies or urgent fertility concerns, immediately contact your healthcare provider or emergency services. Do not rely on this application for urgent medical situations.",
            icon: "phone.fill",
            priority: .critical
        ),
        
        DisclaimerSection(
            title: "Data Accuracy",
            content: "While we strive for accuracy, the information provided may not always be current or complete. Medical knowledge evolves rapidly, and treatment guidelines may change. Always verify information with current medical literature and your healthcare provider.",
            icon: "checkmark.shield.fill",
            priority: .medium
        ),
        
        DisclaimerSection(
            title: "Individual Variation",
            content: "Fertility is highly individual and influenced by numerous medical, genetic, environmental, and lifestyle factors. No prediction tool can account for all variables that may affect your specific situation.",
            icon: "person.fill",
            priority: .high
        ),
        
        DisclaimerSection(
            title: "Medical Data Storage & Privacy",
            content: "This application may store sensitive medical data including age, hormone levels (AMH, Estrogen), BMI, fertility diagnosis information, and IVF prediction results. All medical data is encrypted using industry-standard iOS Keychain security and stored locally on your device only. No medical data is transmitted to external servers.",
            icon: "lock.shield.fill",
            priority: .critical
        ),

        DisclaimerSection(
            title: "Your Data Rights",
            content: "You have complete control over your medical data. You may: (1) Grant or revoke consent for medical data storage at any time, (2) View all stored medical data in Settings > Data Management, (3) Export your data for review, (4) Permanently delete all medical data. Revoking consent will immediately delete all stored medical data.",
            icon: "person.badge.shield.checkmark.fill",
            priority: .critical
        ),

        DisclaimerSection(
            title: "Data Consent Required",
            content: "Before any sensitive medical data is stored, you will be asked to provide explicit informed consent. This consent can be revoked at any time. Without consent, predictions cannot be saved but the app remains fully functional for educational purposes.",
            icon: "checkmark.shield.fill",
            priority: .high
        ),

        DisclaimerSection(
            title: "HIPAA-Level Data Protection",
            content: "While this app is not a covered entity under HIPAA, we implement HIPAA-level data protection practices including encryption at rest, access controls, and user rights to access and delete personal health information. Your medical data privacy is our priority.",
            icon: "heart.text.square.fill",
            priority: .high
        ),

        DisclaimerSection(
            title: "Limitation of Liability",
            content: "The developers of this application disclaim any responsibility for decisions made based on the information provided. Users assume full responsibility for any decisions made using this educational tool.",
            icon: "shield.slash.fill",
            priority: .medium
        )
    ]
    
    static let acknowledgmentText = """
    By accepting this disclaimer, I acknowledge that:

    • I understand this app is for educational purposes only
    • I will not use it as a substitute for professional medical advice
    • I will consult with healthcare professionals for medical decisions
    • I understand predictions are based on population averages
    • I understand sensitive medical data is stored encrypted on my device only
    • I will provide separate consent before any medical data is stored
    • I can view, export, and delete my medical data at any time
    • I accept full responsibility for decisions made using this information
    • I have read and understood all disclaimer and privacy sections above
    """
    
    static let countrySpecificNote = """
    For Canadian users: This application provides educational information but does not replace consultation with healthcare professionals regulated by provincial medical colleges.
    
    For US users: This application is not intended to replace consultation with healthcare professionals licensed in your state.
    """
}

struct DisclaimerSection {
    let title: String
    let content: String
    let icon: String
    let priority: Priority
    
    enum Priority {
        case critical, high, medium
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange  
            case .medium: return .blue
            }
        }
    }
}