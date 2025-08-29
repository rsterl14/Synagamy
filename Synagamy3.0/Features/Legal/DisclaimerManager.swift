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
    
    private let currentDisclaimerVersion = 1
    
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
            title: "Educational Purpose Only",
            content: "This application is designed exclusively for educational and informational purposes. The content provided, including fertility tracking tools, prediction models, and educational materials, should never be used as a substitute for professional medical advice, diagnosis, or treatment.",
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
            title: "Population-Based Predictions",
            content: "All predictions and calculations are based on population averages and statistical models. Individual outcomes may vary significantly based on numerous factors not captured in this application. These predictions should not influence medical treatment decisions.",
            icon: "chart.bar.fill",
            priority: .high
        ),
        
        DisclaimerSection(
            title: "Not a Medical Device",
            content: "This application is not a medical device and has not been evaluated by Health Canada, the FDA, or other regulatory bodies. It does not diagnose, treat, cure, or prevent any medical condition or disease.",
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
    • I accept full responsibility for decisions made using this information
    • I have read and understood all disclaimer sections above
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