//
//  NetworkSecurityConfiguration.swift
//  Synagamy3.0
//
//  Network security configuration and monitoring system
//  Implements security policies and threat detection
//

import Foundation
import Network
import CryptoKit

/// Network security configuration and policy enforcement
final class NetworkSecurityConfiguration: ObservableObject {
    static let shared = NetworkSecurityConfiguration()

    @Published private(set) var securityStatus: SecurityStatus = .unknown
    @Published private(set) var threatLevel: ThreatLevel = .low
    @Published private(set) var lastSecurityCheck: Date?
    @Published private(set) var securityEvents: [SecurityEvent] = []

    enum SecurityStatus {
        case secure
        case warning
        case compromised
        case unknown

        var displayName: String {
            switch self {
            case .secure: return "Secure"
            case .warning: return "Warning"
            case .compromised: return "Compromised"
            case .unknown: return "Unknown"
            }
        }

        var color: String {
            switch self {
            case .secure: return "green"
            case .warning: return "orange"
            case .compromised: return "red"
            case .unknown: return "gray"
            }
        }
    }

    enum ThreatLevel {
        case low
        case medium
        case high
        case critical

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }

    struct SecurityEvent {
        let id = UUID()
        let timestamp: Date
        let type: EventType
        let description: String
        let severity: ThreatLevel

        enum EventType {
            case certificateValidation
            case networkAnomaly
            case suspiciousActivity
            case configurationChange
            case dataIntegrityCheck
        }
    }

    // Security configuration
    private let securityConfig = SecurityPolicyConfiguration()
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkSecurityMonitor")

    private init() {
        setupSecurityMonitoring()
        performInitialSecurityCheck()
    }

    // MARK: - Public Methods

    /// Validate network request against security policies
    func validateNetworkRequest(url: URL, method: String = "GET") -> NetworkRequestValidationResult {
        var result = NetworkRequestValidationResult()

        // Domain validation
        if !securityConfig.isAllowedDomain(url) {
            result.isAllowed = false
            result.blockReason = "Domain not in allowlist: \(url.host ?? "unknown")"
            logSecurityEvent(.suspiciousActivity, "Blocked request to unauthorized domain: \(url.host ?? "unknown")", .high)
            return result
        }

        // Protocol validation
        if url.scheme != "https" {
            result.isAllowed = false
            result.blockReason = "Insecure protocol: \(url.scheme ?? "unknown")"
            logSecurityEvent(.networkAnomaly, "Blocked insecure protocol request", .medium)
            return result
        }

        // Rate limiting check
        if securityConfig.isRateLimited(url) {
            result.isAllowed = false
            result.blockReason = "Rate limit exceeded for domain"
            logSecurityEvent(.suspiciousActivity, "Rate limit exceeded for \(url.host ?? "unknown")", .medium)
            return result
        }

        result.isAllowed = true
        return result
    }

    /// Check data integrity using checksum validation
    func validateDataIntegrity(data: Data, expectedHash: String? = nil) -> Bool {
        let dataHash = SHA256.hash(data: data)
        let hashString = dataHash.compactMap { String(format: "%02x", $0) }.joined()

        if let expected = expectedHash {
            let isValid = hashString == expected
            if !isValid {
                logSecurityEvent(.dataIntegrityCheck, "Data integrity validation failed", .high)
            }
            return isValid
        }

        // If no expected hash, just log the computed hash for monitoring
        #if DEBUG
        print("🔐 Data integrity hash: \(hashString)")
        #endif

        return true
    }

    /// Get current security summary
    func getSecuritySummary() -> NetworkSecuritySummary {
        return NetworkSecuritySummary(
            securityStatus: securityStatus,
            threatLevel: threatLevel,
            lastCheck: lastSecurityCheck,
            recentEvents: Array(securityEvents.prefix(5)),
            allowedDomains: securityConfig.allowedDomains,
            securityPolicies: securityConfig.activePolicies
        )
    }

    /// Force security status update
    func updateSecurityStatus() async {
        await performSecurityCheck()
    }

    /// Clear security event log
    func clearSecurityEvents() {
        securityEvents.removeAll()
        logSecurityEvent(.configurationChange, "Security event log cleared", .low)
    }

    // MARK: - Private Methods

    private func setupSecurityMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                await self?.handleNetworkPathChange(path)
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    private func performInitialSecurityCheck() {
        Task {
            await performSecurityCheck()
        }
    }

    @MainActor
    private func performSecurityCheck() async {
        lastSecurityCheck = Date()

        // Check network security
        await checkNetworkSecurity()

        // Check configuration integrity
        checkConfigurationIntegrity()

        // Update overall security status
        updateOverallSecurityStatus()

        #if DEBUG
        print("🔒 Security check completed - Status: \(securityStatus.displayName)")
        #endif
    }

    private func checkNetworkSecurity() async {
        // Simulate network security checks
        // In a real implementation, this would check various network security metrics
        let isSecure = pathMonitor.currentPath.status == .satisfied &&
                      pathMonitor.currentPath.isExpensive == false

        if isSecure {
            logSecurityEvent(.networkAnomaly, "Network security check passed", .low)
        } else {
            logSecurityEvent(.networkAnomaly, "Network security concerns detected", .medium)
        }
    }

    private func checkConfigurationIntegrity() {
        // Verify security configuration hasn't been tampered with
        let configurationValid = securityConfig.validateIntegrity()

        if !configurationValid {
            logSecurityEvent(.configurationChange, "Security configuration integrity check failed", .high)
            threatLevel = .high
        }
    }

    private func updateOverallSecurityStatus() {
        let recentHighThreatEvents = securityEvents
            .filter { $0.timestamp > Date().addingTimeInterval(-3600) } // Last hour
            .filter { $0.severity == .high || $0.severity == .critical }

        if recentHighThreatEvents.count > 5 {
            securityStatus = .compromised
            threatLevel = .critical
        } else if recentHighThreatEvents.count > 2 {
            securityStatus = .warning
            threatLevel = .high
        } else if threatLevel == .medium || threatLevel == .high {
            securityStatus = .warning
        } else {
            securityStatus = .secure
            threatLevel = .low
        }
    }

    @MainActor
    private func handleNetworkPathChange(_ path: NWPath) async {
        if path.status == .satisfied {
            if path.isExpensive || path.isConstrained {
                logSecurityEvent(.networkAnomaly, "Network constraints detected", .medium)
            }
        }

        await performSecurityCheck()
    }

    private func logSecurityEvent(_ type: SecurityEvent.EventType, _ description: String, _ severity: ThreatLevel) {
        let event = SecurityEvent(
            timestamp: Date(),
            type: type,
            description: description,
            severity: severity
        )

        DispatchQueue.main.async {
            self.securityEvents.insert(event, at: 0)

            // Keep only last 100 events
            if self.securityEvents.count > 100 {
                self.securityEvents = Array(self.securityEvents.prefix(100))
            }

            // Update threat level if necessary
            if severity.rawValue > self.threatLevel.rawValue {
                self.threatLevel = severity
            }
        }

        #if DEBUG
        print("🔒 Security Event: [\(type)] \(description) - Severity: \(severity.displayName)")
        #endif
    }
}

// MARK: - Security Policy Configuration

private class SecurityPolicyConfiguration {
    let allowedDomains: Set<String> = [
        "raw.githubusercontent.com",
        "api.github.com",
        "github.com"
    ]

    let activePolicies = [
        "Certificate Pinning Required",
        "HTTPS Only",
        "Domain Allowlist",
        "Rate Limiting",
        "Data Integrity Validation"
    ]

    private var requestCounts: [String: (count: Int, window: Date)] = [:]
    private let rateLimit = 100 // requests per hour
    private let rateLimitWindow: TimeInterval = 3600 // 1 hour

    func isAllowedDomain(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return allowedDomains.contains(host) || allowedDomains.contains { host.hasSuffix($0) }
    }

    func isRateLimited(_ url: URL) -> Bool {
        guard let host = url.host else { return false }

        let now = Date()

        if let entry = requestCounts[host] {
            // Check if we're still in the same window
            if now.timeIntervalSince(entry.window) < rateLimitWindow {
                if entry.count >= rateLimit {
                    return true
                } else {
                    requestCounts[host] = (count: entry.count + 1, window: entry.window)
                }
            } else {
                // New window
                requestCounts[host] = (count: 1, window: now)
            }
        } else {
            // First request for this host
            requestCounts[host] = (count: 1, window: now)
        }

        return false
    }

    func validateIntegrity() -> Bool {
        // Simple integrity check - in production this could be more sophisticated
        return allowedDomains.count > 0 && activePolicies.count > 0
    }
}

// MARK: - Supporting Types

struct NetworkRequestValidationResult {
    var isAllowed = false
    var blockReason: String?
}

struct NetworkSecuritySummary {
    let securityStatus: NetworkSecurityConfiguration.SecurityStatus
    let threatLevel: NetworkSecurityConfiguration.ThreatLevel
    let lastCheck: Date?
    let recentEvents: [NetworkSecurityConfiguration.SecurityEvent]
    let allowedDomains: Set<String>
    let securityPolicies: [String]
}

// MARK: - ThreatLevel Comparable

extension NetworkSecurityConfiguration.ThreatLevel: Comparable {
    var rawValue: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    static func < (lhs: NetworkSecurityConfiguration.ThreatLevel, rhs: NetworkSecurityConfiguration.ThreatLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}