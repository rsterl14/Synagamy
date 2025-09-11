//
//  DataSourceDebugView.swift
//  Synagamy3.0
//
//  Debug view for monitoring and controlling data sources
//

import SwiftUI

#if DEBUG
struct DataSourceDebugView: View {
    @ObservedObject private var appDataStore = AppDataStore.shared
    @ObservedObject private var remoteService = RemoteDataService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Data Source Status") {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(connectionStatusColor)
                        Text("Connection")
                        Spacer()
                        Text(connectionStatusText)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text("Last Update")
                        Spacer()
                        Text(lastUpdateText)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Use Remote Data", isOn: .init(
                        get: { appDataStore.useRemoteData },
                        set: { appDataStore.setUseRemoteData($0) }
                    ))
                }
                
                Section("Data Counts") {
                    DataCountRow(
                        title: "Education Topics",
                        count: appDataStore.topics.count,
                        icon: "book.fill"
                    )
                    
                    DataCountRow(
                        title: "Common Questions",
                        count: appDataStore.questions.count,
                        icon: "questionmark.circle.fill"
                    )
                    
                    DataCountRow(
                        title: "Pathway Categories",
                        count: appDataStore.pathwayData.categories.count,
                        icon: "map.fill"
                    )
                    
                    DataCountRow(
                        title: "Pathway Paths",
                        count: appDataStore.pathwayPaths.count,
                        icon: "arrow.triangle.branch"
                    )
                    
                    DataCountRow(
                        title: "Resources",
                        count: appDataStore.resources.count,
                        icon: "link.circle.fill"
                    )
                    
                    DataCountRow(
                        title: "Infertility Info",
                        count: appDataStore.infertilityInfo.count,
                        icon: "info.circle.fill"
                    )
                }
                
                Section("Actions") {
                    Button(action: {
                        Task {
                            await appDataStore.refreshFromRemote()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh from Remote")
                            Spacer()
                            if appDataStore.isLoadingRemoteData {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(appDataStore.isLoadingRemoteData || !appDataStore.useRemoteData)
                    
                    Button(action: {
                        DataCacheManager.shared.clearAll()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear Cache")
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await testEducationTopicsLoad()
                        }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                            Text("Test Education Topics Load")
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await testBasicURLFetch()
                        }
                    }) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.green)
                            Text("Test Basic URL Fetch")
                        }
                    }
                }
                
                Section("URLs") {
                    URLRow(title: "Education Topics", 
                           url: "https://raw.githubusercontent.com/rsterl14/fertility-data/main/data/Education_Topics.json")
                    URLRow(title: "Common Questions", 
                           url: "https://raw.githubusercontent.com/rsterl14/fertility-data/main/data/CommonQuestions.json")
                    URLRow(title: "Pathways", 
                           url: "https://raw.githubusercontent.com/rsterl14/fertility-data/main/data/Pathways.json")
                    URLRow(title: "Infertility Info", 
                           url: "https://raw.githubusercontent.com/rsterl14/fertility-data/main/data/infertility_info.json")
                    URLRow(title: "Resources", 
                           url: "https://raw.githubusercontent.com/rsterl14/fertility-data/main/data/resources.json")
                }
            }
            .navigationTitle("Data Source Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var connectionStatusColor: Color {
        switch remoteService.connectionStatus {
        case .connected:
            return .green
        case .offline:
            return .orange
        case .error:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private var connectionStatusText: String {
        switch remoteService.connectionStatus {
        case .connected:
            return "Connected"
        case .offline:
            return "Offline"
        case .error(let message):
            return "Error: \(message)"
        case .unknown:
            return "Unknown"
        }
    }
    
    private var lastUpdateText: String {
        guard let date = appDataStore.lastRemoteUpdate else {
            return "Never"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func testEducationTopicsLoad() async {
        print("🧪 DEBUG TEST: Starting comprehensive data load test...")
        
        // Test RemoteDataService directly
        let topics = await remoteService.loadEducationTopics()
        let resources = await remoteService.loadResources()
        let infertilityInfo = await remoteService.loadInfertilityInfo()
        print("🧪 DEBUG TEST: RemoteDataService returned:")
        print("   - Topics: \(topics.count)")
        print("   - Resources: \(resources.count)")
        print("   - Infertility Info: \(infertilityInfo.count)")
        
        // Test AppDataStore
        let appTopics = AppData.topics
        let appResources = AppData.resources
        let appInfertilityInfo = AppData.infertilityInfo
        print("🧪 DEBUG TEST: AppData has:")
        print("   - Topics: \(appTopics.count)")
        print("   - Resources: \(appResources.count)")
        print("   - Infertility Info: \(appInfertilityInfo.count)")
        
        // Test connection status
        print("🧪 DEBUG TEST: Connection status: \(remoteService.connectionStatus)")
        
        let allLoaded = !topics.isEmpty && !resources.isEmpty && !infertilityInfo.isEmpty
        if allLoaded {
            print("✅ DEBUG TEST: All data loaded successfully")
        } else {
            print("🚨 DEBUG TEST: Some data is missing:")
            if topics.isEmpty { print("   - Topics EMPTY") }
            if resources.isEmpty { print("   - Resources EMPTY") }
            if infertilityInfo.isEmpty { print("   - Infertility Info EMPTY") }
        }
    }
    
    private func testBasicURLFetch() async {
        print("🌐 BASIC TEST: Starting simple URL fetch test...")
        
        guard let url = URL(string: "https://raw.githubusercontent.com/rsterl14/fertility-data/main/data/Education_Topics.json") else {
            print("❌ BASIC TEST: Invalid URL")
            return
        }
        
        print("🌐 BASIC TEST: Testing URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 BASIC TEST: HTTP Status: \(httpResponse.statusCode)")
                print("🌐 BASIC TEST: Data Size: \(data.count) bytes")
                
                if httpResponse.statusCode == 200 {
                    // Try to parse as JSON
                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                        if let array = jsonObject as? [Any] {
                            print("✅ BASIC TEST: JSON is valid array with \(array.count) items")
                        } else {
                            print("⚠️ BASIC TEST: JSON is valid but not an array")
                        }
                    } catch {
                        print("❌ BASIC TEST: JSON parsing failed: \(error)")
                    }
                } else {
                    print("❌ BASIC TEST: HTTP error \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ BASIC TEST: Network request failed: \(error)")
        }
    }
}

struct DataCountRow: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

struct URLRow: View {
    let title: String
    let url: String
    
    var body: some View {
        HStack {
            Image(systemName: "link")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .onTapGesture {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    DataSourceDebugView()
}

#endif