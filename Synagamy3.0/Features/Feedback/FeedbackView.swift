//
//  FeedbackView.swift
//  Synagamy3.0
//
//  Professional feedback interface with clean design and optimized performance.
//  Includes in-app email composition using MessageUI framework.
//

import SwiftUI
import MessageUI

struct FeedbackView: View {
    @State private var message = ""
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var isSubmitting = false
    @State private var showingConfirmation = false
    @State private var showingMailComposer = false
    @State private var errorMessage: String?
    @FocusState private var isMessageFocused: Bool

    // MARK: - Feedback Categories
    enum FeedbackCategory: String, CaseIterable {
        case general = "General Feedback"
        case bug = "Report Issue"
        case suggestion = "Feature Request"
        case content = "Content Feedback"

        var icon: String {
            switch self {
            case .general: return "message"
            case .bug: return "exclamationmark.triangle"
            case .suggestion: return "lightbulb"
            case .content: return "book"
            }
        }

        var description: String {
            switch self {
            case .general: return "Share your thoughts"
            case .bug: return "Report a problem"
            case .suggestion: return "Suggest improvements"
            case .content: return "Educational content feedback"
            }
        }
    }

    var body: some View {
        StandardPageLayout(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: nil,
            showHomeButton: true,
            usePopToRoot: true,
            showBackButton: true
        ) {
            ScrollView {
                VStack(spacing: Brand.Spacing.xl) {
                    headerSection
                    categorySection
                    messageSection
                    submitSection
                }
                .padding(.horizontal, Brand.Spacing.lg)
                .padding(.vertical, Brand.Spacing.md)
            }
        }
        .alert("Feedback Sent", isPresented: $showingConfirmation) {
            Button("Done") {
                clearForm()
            }
        } message: {
            Text("Thank you for your feedback. We appreciate your input in helping us improve Synagamy.")
        }
        .alert("Email Error", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK") {
                errorMessage = nil
                isSubmitting = false
            }
            Button("Copy Email") {
                UIPasteboard.general.string = "synagamyfertility@gmail.com"
                errorMessage = nil
                isSubmitting = false
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView(
                recipients: ["synagamyfertility@gmail.com"],
                subject: "Synagamy Feedback: \(selectedCategory.rawValue)",
                messageBody: createEmailBody(),
                onResult: handleMailResult
            )
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Brand.Spacing.md) {
            Image(systemName: "envelope")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Brand.Color.primary)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Brand.Color.primaryLight)
                )

            Text("Send Feedback")
                .font(Brand.Typography.headlineLarge)
                .foregroundColor(Brand.Color.textPrimary)

            Text("Help us improve by sharing your thoughts, reporting issues, or suggesting new features.")
                .font(Brand.Typography.bodyMedium)
                .foregroundColor(Brand.Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }

    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text("Feedback Type")
                .font(Brand.Typography.labelLarge)
                .foregroundColor(Brand.Color.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Brand.Spacing.sm), count: 2), spacing: Brand.Spacing.sm) {
                ForEach(FeedbackCategory.allCases, id: \.self) { category in
                    categoryButton(category)
                }
            }
        }
    }

    private func categoryButton(_ category: FeedbackCategory) -> some View {
        Button {
            selectedCategory = category
            Brand.Haptic.light.impactOccurred()
        } label: {
            VStack(spacing: Brand.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedCategory == category ? .white : Brand.Color.primary)

                Text(category.rawValue)
                    .font(Brand.Typography.labelMedium)
                    .foregroundColor(selectedCategory == category ? .white : Brand.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(category.description)
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(selectedCategory == category ? .white.opacity(0.9) : Brand.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Brand.Spacing.lg)
            .padding(.horizontal, Brand.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                    .fill(selectedCategory == category ? Brand.Color.primary : Brand.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                            .stroke(selectedCategory == category ? Brand.Color.primary : Brand.Color.hairline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(Brand.Motion.springSnappy, value: selectedCategory)
    }

    // MARK: - Message Section
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.md) {
            Text("Your Message")
                .font(Brand.Typography.labelLarge)
                .foregroundColor(Brand.Color.textPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $message)
                    .font(Brand.Typography.bodyMedium)
                    .scrollContentBackground(.hidden)
                    .focused($isMessageFocused)
                    .frame(minHeight: 120)
                    .padding(Brand.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                            .fill(Brand.Color.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                                    .stroke(isMessageFocused ? Brand.Color.primary : Brand.Color.hairline, lineWidth: 1)
                            )
                    )

                if message.isEmpty {
                    Text("Describe your feedback here...")
                        .font(Brand.Typography.bodyMedium)
                        .foregroundColor(Brand.Color.textTertiary)
                        .padding(.horizontal, Brand.Spacing.lg)
                        .padding(.vertical, Brand.Spacing.lg)
                        .allowsHitTesting(false)
                }
            }

            HStack {
                Spacer()
                Text("\(message.count) characters")
                    .font(Brand.Typography.labelSmall)
                    .foregroundColor(Brand.Color.textSecondary)
            }
        }
    }

    // MARK: - Submit Section
    private var submitSection: some View {
        VStack(spacing: Brand.Spacing.lg) {
            Button(action: submitFeedback) {
                HStack(spacing: Brand.Spacing.sm) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .medium))
                    }

                    Text(isSubmitting ? "Sending..." : "Send Feedback")
                        .font(Brand.Typography.labelLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.lg, style: .continuous)
                        .fill(isSubmitEnabled ? Brand.Color.primary : Brand.Color.interactiveDisabled)
                )
            }
            .disabled(!isSubmitEnabled || isSubmitting)
            .buttonStyle(.plain)
            .animation(Brand.Motion.easeOut, value: isSubmitEnabled)

            Text("Your feedback will be sent directly to our team")
                .font(Brand.Typography.labelSmall)
                .foregroundColor(Brand.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Computed Properties
    private var isSubmitEnabled: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions
    private func submitFeedback() {
        guard isSubmitEnabled && !isSubmitting else { return }

        isMessageFocused = false
        Brand.Haptic.medium.impactOccurred()

        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            // Fallback to mailto URL
            isSubmitting = true
            sendEmailFallback()
        }
    }

    private func createEmailBody() -> String {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        Category: \(selectedCategory.rawValue)

        Message:
        \(trimmedMessage)

        —
        Sent from Synagamy for iOS
        """
    }

    private func handleMailResult(_ result: MFMailComposeResult) {
        switch result {
        case .sent:
            showingConfirmation = true
            clearForm()
        case .cancelled, .saved:
            // User cancelled or saved draft - no action needed
            break
        case .failed:
            errorMessage = "Failed to send email. Please try again or contact synagamyfertility@gmail.com directly."
        @unknown default:
            break
        }
    }

    private func sendEmailFallback() {
        let subject = "Synagamy Feedback: \(selectedCategory.rawValue)"
        let body = createEmailBody()
        let mailtoString = "mailto:synagamyfertility@gmail.com?subject=\(subject.urlEncoded)&body=\(body.urlEncoded)"

        guard let url = URL(string: mailtoString) else {
            isSubmitting = false
            errorMessage = "Unable to create email. Please contact synagamyfertility@gmail.com directly."
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                DispatchQueue.main.async {
                    isSubmitting = false
                    if success {
                        showingConfirmation = true
                        clearForm()
                    } else {
                        errorMessage = "Unable to open email app. Please contact synagamyfertility@gmail.com directly."
                    }
                }
            }
        } else {
            isSubmitting = false
            errorMessage = "No email app available. Please contact synagamyfertility@gmail.com directly."
        }
    }

    private func clearForm() {
        message = ""
        selectedCategory = .general
    }
}

// MARK: - Mail Compose Wrapper
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    let onResult: (MFMailComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onResult: (MFMailComposeResult) -> Void

        init(onResult: @escaping (MFMailComposeResult) -> Void) {
            self.onResult = onResult
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
            onResult(result)
        }
    }
}

// MARK: - String Extension
private extension String {
    var urlEncoded: String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}