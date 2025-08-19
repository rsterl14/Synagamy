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

    func makeUIViewController(context: Context) -> UIViewController {
        // Validate the URL before trying to open Safari
        guard let url = url else {
            return FallbackViewController(message: "Invalid or missing URL")
        }
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No runtime updates needed — Safari handles navigation internally.
    }
}

// MARK: - Fallback (shown when URL is nil or invalid)

private final class FallbackViewController: UIViewController {
    private let message: String

    init(message: String) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.message = "Invalid URL"
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = message
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityLabel = "Web content unavailable. \(message)"

        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
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
