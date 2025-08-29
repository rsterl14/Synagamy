//
//  LazyDataLoader.swift
//  Synagamy3.0
//
//  Optimized data loading with caching and lazy initialization.
//

import SwiftUI
import Combine

// MARK: - Lazy Content Provider

@MainActor
class LazyContentProvider: ObservableObject {
    @Published private(set) var topics: [EducationTopic] = []
    @Published private(set) var pathways: [PathwayCategory] = []
    @Published private(set) var questions: [CommonQuestion] = []
    @Published private(set) var resources: [Resource] = []
    
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    
    private var topicsLoaded = false
    private var pathwaysLoaded = false
    private var questionsLoaded = false
    private var resourcesLoaded = false
    
    // MARK: - Lazy Loading Methods
    
    func loadTopics() async {
        guard !topicsLoaded else { return }
        
        isLoading = true
        loadingProgress = 0.1
        
        topics = await Task.detached {
            AppData.topics
        }.value
        
        topicsLoaded = true
        loadingProgress = 0.3
        checkLoadingComplete()
    }
    
    func loadPathways() async {
        guard !pathwaysLoaded else { return }
        
        if !isLoading {
            isLoading = true
            loadingProgress = 0.1
        }
        
        pathways = await Task.detached {
            AppData.pathwayCategories
        }.value
        
        pathwaysLoaded = true
        loadingProgress = 0.6
        checkLoadingComplete()
    }
    
    func loadQuestions() async {
        guard !questionsLoaded else { return }
        
        if !isLoading {
            isLoading = true
            loadingProgress = 0.1
        }
        
        questions = await Task.detached {
            AppData.questions
        }.value
        
        questionsLoaded = true
        loadingProgress = 0.8
        checkLoadingComplete()
    }
    
    func loadResources() async {
        guard !resourcesLoaded else { return }
        
        if !isLoading {
            isLoading = true
            loadingProgress = 0.1
        }
        
        resources = await Task.detached {
            // Load resources from a JSON file or return empty array
            DataLoader.loadArray([Resource].self, named: "Resources")
        }.value
        
        resourcesLoaded = true
        loadingProgress = 1.0
        checkLoadingComplete()
    }
    
    func preloadAll() async {
        isLoading = true
        loadingProgress = 0
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTopics() }
            group.addTask { await self.loadPathways() }
            group.addTask { await self.loadQuestions() }
            group.addTask { await self.loadResources() }
        }
    }
    
    private func checkLoadingComplete() {
        if topicsLoaded && pathwaysLoaded && questionsLoaded && resourcesLoaded {
            isLoading = false
        }
    }
}

// MARK: - Paginated Content Loader

@MainActor
class PaginatedContentLoader<T>: ObservableObject {
    @Published private(set) var items: [T] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMoreContent = true
    @Published var error: Error?
    
    private let pageSize: Int
    private let loader: (Int, Int) async throws -> [T]
    private var currentPage = 0
    
    init(pageSize: Int = 10, loader: @escaping (Int, Int) async throws -> [T]) {
        self.pageSize = pageSize
        self.loader = loader
    }
    
    func loadInitial() async {
        guard items.isEmpty && !isLoading else { return }
        
        isLoading = true
        error = nil
        currentPage = 0
        
        do {
            let newItems = try await loader(0, pageSize)
            items = newItems
            hasMoreContent = newItems.count == pageSize
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func loadMore() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        
        do {
            currentPage += 1
            let newItems = try await loader(currentPage, pageSize)
            items.append(contentsOf: newItems)
            hasMoreContent = newItems.count == pageSize
        } catch {
            self.error = error
            currentPage -= 1
        }
        
        isLoading = false
    }
    
    func refresh() async {
        items.removeAll()
        hasMoreContent = true
        currentPage = 0
        await loadInitial()
    }
}

// MARK: - Search Optimization

@MainActor
class OptimizedSearchManager: ObservableObject {
    @Published var searchResults: [EducationTopic] = []
    @Published var isSearching = false
    @Published var searchQuery = ""
    
    private var searchTask: Task<Void, Never>?
    private let searchDelay: TimeInterval = 0.3
    private var allTopics: [EducationTopic] = []
    
    init(topics: [EducationTopic] = []) {
        self.allTopics = topics
        setupSearchDelay()
    }
    
    func updateTopics(_ topics: [EducationTopic]) {
        allTopics = topics
    }
    
    private func setupSearchDelay() {
        $searchQuery
            .debounce(for: .seconds(searchDelay), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func performSearch(query: String) {
        // Cancel any existing search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let results = self.searchTopics(query: query.lowercased())
            
            if !Task.isCancelled {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
    
    private func searchTopics(query: String) -> [EducationTopic] {
        return allTopics.filter { topic in
            topic.topic.localizedCaseInsensitiveContains(query) ||
            topic.layExplanation.localizedCaseInsensitiveContains(query) ||
            topic.category.localizedCaseInsensitiveContains(query) ||
            (topic.relatedTo?.joined(separator: " ").localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}

// MARK: - Optimized List Components

struct OptimizedTopicList: View {
    let topics: [EducationTopic]
    let onTopicSelected: (EducationTopic) -> Void
    
    @State private var visibleRange: Range<Int> = 0..<10
    private let batchSize = 10
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(topics.indices.prefix(visibleRange.upperBound), id: \.self) { index in
                TopicRowView(topic: topics[index])
                    .onTapGesture {
                        onTopicSelected(topics[index])
                    }
                    .onAppear {
                        if index == visibleRange.upperBound - 3 {
                            loadMoreItems()
                        }
                    }
            }
            
            if visibleRange.upperBound < topics.count {
                ProgressView()
                    .frame(height: 50)
                    .onAppear {
                        loadMoreItems()
                    }
            }
        }
    }
    
    private func loadMoreItems() {
        let nextBatch = min(visibleRange.upperBound + batchSize, topics.count)
        visibleRange = visibleRange.lowerBound..<nextBatch
    }
}

private struct TopicRowView: View {
    let topic: EducationTopic
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.topic)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(topic.layExplanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(topic.category)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.blue.opacity(0.1))
                    )
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Memory-Efficient Image Loading

struct AsyncCachedImage: View {
    let url: URL?
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @StateObject private var imageCache = ImageCacheManager.shared
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                placeholder
                    .foregroundColor(.gray)
            } else {
                placeholder
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            isLoading = false
            return
        }
        
        if let cachedImage = imageCache.image(for: url.absoluteString) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = downloadedImage
                        self.isLoading = false
                        imageCache.setImage(downloadedImage, for: url.absoluteString)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}