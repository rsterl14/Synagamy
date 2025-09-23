//
//  NetworkStatusManager.swift
//  Synagamy3.0
//
//  Enhanced network connectivity monitoring and user feedback system
//

import SwiftUI
import Network
import SystemConfiguration

@MainActor
final class NetworkStatusManager: ObservableObject {
    static let shared = NetworkStatusManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var networkStatus: NetworkStatus = .unknown
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isOnline = false
    @Published private(set) var lastConnectedDate: Date?
    @Published private(set) var failureReason: String?
    
    // MARK: - Private Properties
    
    private var pathMonitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "networkmonitor", qos: .utility)
    
    // MARK: - Types
    
    enum NetworkStatus: Equatable {
        case unknown
        case connected
        case disconnected
        case limited           // Connected but with limited internet access
        case error(String)
        
        var displayName: String {
            switch self {
            case .unknown: return "Checking connection..."
            case .connected: return "Online"
            case .disconnected: return "No internet connection"
            case .limited: return "Limited connection"
            case .error(let message): return "Connection error: \(message)"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .connected: return "wifi"
            case .disconnected: return "wifi.slash" 
            case .limited: return "wifi.exclamationmark"
            case .error: return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .unknown: return .secondary
            case .connected: return .green
            case .disconnected: return .red
            case .limited: return .orange
            case .error: return .red
            }
        }
    }
    
    enum ConnectionType: Equatable {
        case unknown
        case wifi
        case cellular
        case ethernet
        case other
        
        var displayName: String {
            switch self {
            case .unknown: return "Unknown"
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .wifi: return "wifi"
            case .cellular: return "cellularbars"
            case .ethernet: return "cable.connector"
            case .other: return "network"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        startNetworkMonitoring()
    }
    
    deinit {
        pathMonitor?.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateNetworkStatus(from: path)
            }
        }
        
        pathMonitor?.start(queue: queue)
    }
    
    private func updateNetworkStatus(from path: NWPath) {
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.status == .satisfied {
            connectionType = .other
        } else {
            connectionType = .unknown
        }
        
        // Update network status based on path status
        switch path.status {
        case .satisfied:
            if path.isExpensive {
                networkStatus = .connected
                failureReason = "Using cellular data"
            } else {
                networkStatus = .connected
                failureReason = nil
            }
            isOnline = true
            lastConnectedDate = Date()
            
            // Verify actual internet connectivity
            Task {
                await verifyInternetConnectivity()
            }
            
        case .unsatisfied:
            networkStatus = .disconnected
            isOnline = false
            failureReason = getDisconnectionReason(from: path)
            
        case .requiresConnection:
            networkStatus = .limited
            isOnline = false
            failureReason = "Connection requires user action"
            
        @unknown default:
            networkStatus = .unknown
            isOnline = false
            failureReason = "Unknown network status"
        }
        
        #if DEBUG
        print("🌐 NetworkStatus updated: \(networkStatus.displayName) via \(connectionType.displayName)")
        if let reason = failureReason {
            print("📝 Reason: \(reason)")
        }
        #endif
    }
    
    private func getDisconnectionReason(from path: NWPath) -> String {
        if !path.usesInterfaceType(.wifi) && !path.usesInterfaceType(.cellular) && !path.usesInterfaceType(.wiredEthernet) {
            return "No network interfaces available"
        } else if path.usesInterfaceType(.wifi) {
            return "Wi-Fi is not connected"
        } else if path.usesInterfaceType(.cellular) {
            return "Cellular data is not available"
        } else {
            return "Network is not reachable"
        }
    }
    
    // MARK: - Internet Connectivity Verification
    
    private func verifyInternetConnectivity() async {
        // Test actual internet connectivity by making a lightweight request
        guard let url = URL(string: "https://www.apple.com/library/test/success.html") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                // Internet is working
                if networkStatus == .limited {
                    networkStatus = .connected
                }
            } else {
                // Connected to network but no internet
                networkStatus = .limited
                failureReason = "Connected to network but no internet access"
            }
        } catch {
            // Network connection exists but internet is not reachable
            networkStatus = .limited
            failureReason = "Cannot reach the internet: \(error.localizedDescription)"
            
            #if DEBUG
            print("🚫 Internet verification failed: \(error)")
            #endif
        }
    }
    
    // MARK: - Public Methods
    
    /// Manually check network connectivity
    func checkConnectivity() async {
        await verifyInternetConnectivity()
    }
    
    /// Get user-friendly error message for failed operations
    func getErrorMessage(for operation: String) -> String {
        switch networkStatus {
        case .disconnected:
            return "Cannot \(operation) - no internet connection. Please check your network settings and try again."
            
        case .limited:
            let reason = failureReason ?? "limited internet access"
            return "Cannot \(operation) - \(reason). Please check your internet connection."
            
        case .error(let message):
            return "Cannot \(operation) - \(message). Please try again later."
            
        case .connected, .unknown:
            return "Cannot \(operation) right now. Please check your connection and try again."
        }
    }
    
    /// Get recovery suggestions for the current network state
    func getRecoverySuggestions() -> [String] {
        switch networkStatus {
        case .disconnected:
            var suggestions = ["Check if Wi-Fi or cellular data is enabled"]
            if connectionType == .wifi {
                suggestions.append("Try switching to cellular data")
                suggestions.append("Move closer to your Wi-Fi router")
                suggestions.append("Restart your Wi-Fi router")
            } else if connectionType == .cellular {
                suggestions.append("Try connecting to Wi-Fi")
                suggestions.append("Check if you have cellular data remaining")
                suggestions.append("Move to an area with better cellular coverage")
            }
            suggestions.append("Restart your device's network settings")
            return suggestions
            
        case .limited:
            return [
                "Try opening a web browser to check internet access",
                "Disconnect and reconnect to your network",
                "Check if you need to sign in to a Wi-Fi network",
                "Contact your internet service provider if the problem persists"
            ]
            
        case .error:
            return [
                "Wait a moment and try again",
                "Check your network settings",
                "Restart the app",
                "Contact support if the problem continues"
            ]
            
        case .connected, .unknown:
            return [
                "Wait a moment and try again",
                "Pull down to refresh the content"
            ]
        }
    }
}

// MARK: - Network Status Extensions

extension NetworkStatusManager.NetworkStatus {
    var canPerformNetworkOperations: Bool {
        switch self {
        case .connected:
            return true
        case .unknown, .disconnected, .limited, .error:
            return false
        }
    }
    
    var shouldShowNetworkError: Bool {
        switch self {
        case .disconnected, .limited, .error:
            return true
        case .unknown, .connected:
            return false
        }
    }
}