//
//  SecureNetworkManager.swift
//  Synagamy3.0
//
//  Secure network manager with certificate pinning for GitHub API
//  Prevents man-in-the-middle attacks and ensures data integrity
//

import Foundation
import Network
import CryptoKit

/// Secure network manager with certificate pinning for GitHub data fetching
final class SecureNetworkManager: NSObject, ObservableObject {
    static let shared = SecureNetworkManager()

    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var lastSecurityEvent: SecurityEvent?

    enum ConnectionStatus {
        case unknown
        case secure
        case insecure
        case blocked
        case offline

        var displayName: String {
            switch self {
            case .unknown: return "Unknown"
            case .secure: return "Secure Connection"
            case .insecure: return "Insecure Connection"
            case .blocked: return "Connection Blocked"
            case .offline: return "Offline"
            }
        }
    }

    enum SecurityEvent {
        case certificatePinningSuccess
        case certificatePinningFailure(String)
        case secureConnectionEstablished
        case insecureConnectionAttempted
        case networkError(String)

        var description: String {
            switch self {
            case .certificatePinningSuccess:
                return "Certificate pinning validation successful"
            case .certificatePinningFailure(let reason):
                return "Certificate pinning failed: \(reason)"
            case .secureConnectionEstablished:
                return "Secure HTTPS connection established"
            case .insecureConnectionAttempted:
                return "Insecure connection attempt blocked"
            case .networkError(let error):
                return "Network error: \(error)"
            }
        }
    }

    // GitHub certificate pins (SHA-256 hashes of public keys)
    private let githubCertificatePins: Set<String> = [
        // GitHub's current certificate pins (these should be updated periodically)
        "23Ef956A84A7BB3A6EBACAA6C6E5C5A8B7E0F6DBC71234567890ABCDEF123456", // Example pin 1
        "34F067AA94B7CC4A6F5BACBA6D7E6C6A9C8E1F7E0C81345678901BCDEF234567", // Example pin 2
        // Note: In production, these should be the actual GitHub certificate pins
        // obtained from their current certificates
    ]

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        // Enhanced security headers
        config.httpAdditionalHeaders = [
            "User-Agent": "Synagamy-iOS/1.0 (Educational-Tool)",
            "Accept": "application/json",
            "Cache-Control": "no-cache"
        ]

        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }()

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    private override init() {
        super.init()
        startNetworkMonitoring()
    }

    // MARK: - Public Methods

    /// Perform secure data fetch with certificate pinning
    func secureDataFetch(from url: URL) async throws -> Data {
        #if DEBUG
        print("🔒 SecureNetworkManager: Starting secure fetch from \(url.host ?? "unknown")")
        #endif

        guard url.scheme == "https" else {
            let error = SecurityError.insecureConnection
            await updateSecurityEvent(.insecureConnectionAttempted)
            throw error
        }

        guard isGitHubDomain(url) else {
            let error = SecurityError.untrustedDomain
            throw error
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Synagamy-iOS/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SecurityError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw SecurityError.httpError(httpResponse.statusCode)
            }

            await updateSecurityEvent(.secureConnectionEstablished)

            #if DEBUG
            print("🔒 SecureNetworkManager: Secure fetch completed (\(data.count) bytes)")
            #endif

            return data

        } catch {
            await updateSecurityEvent(.networkError(error.localizedDescription))
            throw SecurityError.networkFailure(error)
        }
    }

    /// Check if connection is secure and trusted
    func validateConnectionSecurity(for url: URL) -> Bool {
        return url.scheme == "https" && isGitHubDomain(url)
    }

    // MARK: - Private Methods

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.cellular) {
                        self?.connectionStatus = .unknown // Will be updated by certificate validation
                    }
                } else {
                    self?.connectionStatus = .offline
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    private func isGitHubDomain(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "raw.githubusercontent.com" ||
               host == "api.github.com" ||
               host.hasSuffix(".githubusercontent.com")
    }

    private func validateCertificatePinning(_ trust: SecTrust) -> Bool {
        guard let certificate = SecTrustGetCertificateAtIndex(trust, 0) else {
            return false
        }

        let publicKey = SecCertificateCopyKey(certificate)
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, nil) else {
            return false
        }

        let publicKeyHash = SHA256.hash(data: publicKeyData as Data)
        let publicKeyHashString = publicKeyHash.compactMap {
            String(format: "%02X", $0)
        }.joined()

        let isValid = githubCertificatePins.contains(publicKeyHashString)

        #if DEBUG
        print("🔒 Certificate validation: \(isValid ? "SUCCESS" : "FAILED")")
        print("🔒 Public key hash: \(publicKeyHashString)")
        #endif

        return isValid
    }

    @MainActor
    private func updateSecurityEvent(_ event: SecurityEvent) {
        lastSecurityEvent = event

        switch event {
        case .certificatePinningSuccess, .secureConnectionEstablished:
            connectionStatus = .secure
        case .certificatePinningFailure, .insecureConnectionAttempted:
            connectionStatus = .insecure
        case .networkError:
            connectionStatus = .offline
        }

        #if DEBUG
        print("🔒 Security Event: \(event.description)")
        #endif
    }
}

// MARK: - URLSessionDelegate

extension SecureNetworkManager: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            Task {
                await updateSecurityEvent(.certificatePinningFailure("Invalid authentication method"))
            }
            return
        }

        // Validate certificate pinning for GitHub domains only
        if isGitHubDomain(URL(string: challenge.protectionSpace.host) ?? URL(fileURLWithPath: "")) {
            if validateCertificatePinning(serverTrust) {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                Task {
                    await updateSecurityEvent(.certificatePinningSuccess)
                }
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                Task {
                    await updateSecurityEvent(.certificatePinningFailure("Certificate pin mismatch"))
                }
            }
        } else {
            // For non-GitHub domains, use default validation
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Security Errors

enum SecurityError: LocalizedError {
    case insecureConnection
    case untrustedDomain
    case certificatePinningFailure
    case invalidResponse
    case httpError(Int)
    case networkFailure(Error)

    var errorDescription: String? {
        switch self {
        case .insecureConnection:
            return "Insecure connection attempted - HTTPS required"
        case .untrustedDomain:
            return "Untrusted domain - only GitHub domains allowed"
        case .certificatePinningFailure:
            return "Certificate pinning validation failed"
        case .invalidResponse:
            return "Invalid network response received"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkFailure(let error):
            return "Network failure: \(error.localizedDescription)"
        }
    }
}

// MARK: - Network Status Helper

extension SecureNetworkManager {
    var networkStatus: NetworkStatus {
        switch connectionStatus {
        case .unknown, .offline:
            return NetworkStatus(canPerformNetworkOperations: false, displayName: connectionStatus.displayName)
        case .secure:
            return NetworkStatus(canPerformNetworkOperations: true, displayName: connectionStatus.displayName)
        case .insecure, .blocked:
            return NetworkStatus(canPerformNetworkOperations: false, displayName: connectionStatus.displayName)
        }
    }

    func getErrorMessage(for operation: String) -> String {
        switch connectionStatus {
        case .offline:
            return "No internet connection available to \(operation)"
        case .insecure:
            return "Connection not secure enough to \(operation)"
        case .blocked:
            return "Connection blocked for security reasons"
        default:
            return "Unable to \(operation) - please check your connection"
        }
    }
}

struct NetworkStatus {
    let canPerformNetworkOperations: Bool
    let displayName: String
}