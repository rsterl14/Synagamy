//
//  WebSafariView.swift
//  Synagamy3.0
//
//  Purpose
//  -------
//  A safe SwiftUI wrapper for `SFSafariViewController` to display external websites
//  within the app. Keeps users in-app while browsing resources, clinics, or research.
//
//  Improvements
//  ------------
//  • Graceful handling of invalid or empty URLs (shows fallback view instead of crashing).
//  • Clear accessibility label for VoiceOver.
//  • App Store–friendly (uses only SafariServices; no WKWebView hacks).
//

import SwiftUI
import SafariServices

struct WebSafariView: UIViewControllerRepresentable {
    /// The destination URL to open.
    let url: URL?
    
    /// Optional error handler for URL validation failures
    let onError: ((SynagamyError) -> Void)?
    
    init(url: URL?, onError: ((SynagamyError) -> Void)? = nil) {
        self.url = url
        self.onError = onError
    }

    func makeUIViewController(context: Context) -> UIViewController {
        // Validate the URL before trying to open Safari
        guard let url = url else {
            let error = SynagamyError.urlInvalid(url: "nil")
            handleError(error)
            return FallbackViewController(
                message: "Invalid or missing URL",
                error: error,
                onRetry: nil
            )
        }
        
        // Additional URL validation
        if url.scheme == nil || (url.scheme != "http" && url.scheme != "https") {
            let error = SynagamyError.urlInvalid(url: url.absoluteString)
            handleError(error)
            return FallbackViewController(
                message: "This link cannot be opened",
                error: error,
                onRetry: nil
            )
        }
        
        // Check if the URL host is reachable (basic validation)
        if url.host?.isEmpty == true {
            let error = SynagamyError.urlInvalid(url: url.absoluteString)
            handleError(error)
            return FallbackViewController(
                message: "Invalid website address",
                error: error,
                onRetry: nil
            )
        }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        
        return safariVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No runtime updates needed — Safari handles navigation internally.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func handleError(_ error: SynagamyError) {
        if let onError = onError {
            onError(error)
        } else {
            ErrorHandler.shared.handle(error)
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: WebSafariView
        
        init(_ parent: WebSafariView) {
            self.parent = parent
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if !didLoadSuccessfully {
                let error = SynagamyError.resourceNotFound(url: parent.url?.absoluteString ?? "unknown")
                parent.handleError(error)
            }
        }
        
        func safariViewController(_ controller: SFSafariViewController, didFailProvisionalLoadWith error: Error) {
            let synagamyError: SynagamyError
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    synagamyError = .networkUnavailable
                case .timedOut:
                    synagamyError = .requestTimeout(url: parent.url?.absoluteString ?? "unknown")
                case .resourceUnavailable, .fileDoesNotExist:
                    synagamyError = .resourceNotFound(url: parent.url?.absoluteString ?? "unknown")
                default:
                    synagamyError = .networkUnavailable
                }
            } else {
                synagamyError = .resourceNotFound(url: parent.url?.absoluteString ?? "unknown")
            }
            
            parent.handleError(synagamyError)
        }
    }
}

// MARK: - Fallback (shown when URL is nil or invalid)

private final class FallbackViewController: UIViewController {
    private let message: String
    private let error: SynagamyError?
    private let onRetry: (() -> Void)?

    init(message: String, error: SynagamyError? = nil, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.error = error
        self.onRetry = onRetry
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.message = "Invalid URL"
        self.error = nil
        self.onRetry = nil
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Error icon
        let iconView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        iconView.tintColor = .systemOrange
        iconView.contentMode = .scaleAspectFit
        
        // Main message
        let messageLabel = UILabel()
        messageLabel.text = error?.userFriendlyMessage ?? message
        messageLabel.textColor = .label
        messageLabel.font = .preferredFont(forTextStyle: .headline)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // Detailed message
        let detailLabel = UILabel()
        if let error = error {
            detailLabel.text = error.recoverySuggestion
        } else {
            detailLabel.text = "Please try again later or contact support if this continues."
        }
        detailLabel.textColor = .secondaryLabel
        detailLabel.font = .preferredFont(forTextStyle: .body)
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        
        // Add views to stack
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(detailLabel)
        
        // Add retry button if handler provided
        if onRetry != nil {
            let retryButton = UIButton(type: .system)
            retryButton.setTitle("Try Again", for: .normal)
            retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            retryButton.backgroundColor = .systemBlue
            retryButton.setTitleColor(.white, for: .normal)
            retryButton.layer.cornerRadius = 8
            // Use modern UIButton configuration instead of deprecated contentEdgeInsets
            var config = UIButton.Configuration.filled()
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            retryButton.configuration = config
            
            retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
            stackView.addArrangedSubview(retryButton)
        }
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
        
        // Accessibility
        view.accessibilityLabel = "Web content unavailable. \(error?.userFriendlyMessage ?? message)"
        if error?.recoverySuggestion != nil {
            view.accessibilityHint = error?.recoverySuggestion
        }
    }
    
    @objc private func retryTapped() {
        onRetry?()
    }
}

// MARK: - Previews

#Preview("Valid URL") {
    WebSafariView(url: URL(string: "https://www.apple.com"))
        .ignoresSafeArea()
}

#Preview("Invalid URL") {
    WebSafariView(url: nil) // shows fallback
        .ignoresSafeArea()
}
