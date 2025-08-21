//
//  OptimizedList.swift
//  Synagamy3.0
//
//  High-performance list component with virtualization, preloading, and
//  intelligent rendering optimizations. Reduces memory usage and improves
//  scroll performance for large datasets.
//

import SwiftUI

/// High-performance list with virtualization and intelligent rendering
struct OptimizedList<Data: RandomAccessCollection, ID: Hashable, Content: View>: View 
where Data.Element: Identifiable, Data.Element.ID == ID {
    
    let data: Data
    let content: (Data.Element) -> Content
    
    // MARK: - Performance Configuration
    private let bufferSize: Int = 5 // Items to render outside visible area
    private let estimatedItemHeight: CGFloat = 100
    
    // MARK: - State
    @State private var visibleIndices: Range<Int> = 0..<0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentOffset: CGFloat = 0
    
    init(
        data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: Brand.Spacing.lg) {
                    ForEach(visibleItems, id: \.id) { item in
                        content(item)
                            .onAppear {
                                updateVisibleIndices(geometry: geometry)
                            }
                    }
                }
                .padding(.horizontal, Brand.Spacing.lg)
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: contentGeometry.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                contentOffset = offset
                updateVisibleIndices(geometry: geometry)
            }
            .onAppear {
                scrollViewHeight = geometry.size.height
                updateVisibleIndices(geometry: geometry)
            }
            .onChange(of: geometry.size.height) { _, newHeight in
                scrollViewHeight = newHeight
                updateVisibleIndices(geometry: geometry)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var visibleItems: [Data.Element] {
        let dataArray = Array(data)
        let startIndex = max(visibleIndices.lowerBound, 0)
        let endIndex = min(visibleIndices.upperBound, dataArray.count)
        guard startIndex < endIndex else { return [] }
        return Array(dataArray[startIndex..<endIndex])
    }
    
    // MARK: - Visibility Calculation
    private func updateVisibleIndices(geometry: GeometryProxy) {
        let viewportHeight = geometry.size.height
        let dataCount = Array(data).count
        let startIndex = max(0, Int(-contentOffset / estimatedItemHeight) - bufferSize)
        let endIndex = min(
            dataCount,
            Int((-contentOffset + viewportHeight) / estimatedItemHeight) + bufferSize
        )
        
        let newRange = startIndex..<endIndex
        
        // Only update if range changed significantly
        if abs(newRange.lowerBound - visibleIndices.lowerBound) > 2 ||
           abs(newRange.upperBound - visibleIndices.upperBound) > 2 {
            visibleIndices = newRange
        }
    }
}

// MARK: - Preference Key for Scroll Offset
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Optimized ForEach Alternative
struct OptimizedForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View
where Data.Element: Identifiable, Data.Element.ID == ID {
    
    let data: Data
    let content: (Data.Element) -> Content
    
    // MARK: - Performance State
    @State private var renderedItems: Set<ID> = []
    private let renderBatchSize = 10
    
    init(
        data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        LazyVStack(spacing: Brand.Spacing.lg) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                if shouldRender(item: item, index: index) {
                    content(item)
                        .onAppear {
                            markAsRendered(item.id)
                        }
                } else {
                    // Placeholder for unrendered items
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 80) // Estimated height
                        .onAppear {
                            scheduleRender(item.id)
                        }
                }
            }
        }
    }
    
    private func shouldRender(item: Data.Element, index: Int) -> Bool {
        // Render first batch immediately
        if index < renderBatchSize {
            return true
        }
        
        // Render items that have been marked for rendering
        return renderedItems.contains(item.id)
    }
    
    private func markAsRendered(_ id: ID) {
        renderedItems.insert(id)
    }
    
    private func scheduleRender(_ id: ID) {
        // Delay rendering to improve scroll performance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            renderedItems.insert(id)
        }
    }
}

// MARK: - Memory-Efficient Grid Alternative
struct OptimizedGrid<Data: RandomAccessCollection, ID: Hashable, Content: View>: View
where Data.Element: Identifiable, Data.Element.ID == ID {
    
    let data: Data
    let columns: Int
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    init(
        data: Data,
        columns: Int = 2,
        spacing: CGFloat = Brand.Spacing.lg,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: columns
            ),
            spacing: spacing
        ) {
            ForEach(Array(data), id: \.id) { item in
                content(item)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    struct SampleItem: Identifiable {
        let id = UUID()
        let title: String
    }
    
    let sampleData = (1...100).map { SampleItem(title: "Item \($0)") }
    
    return OptimizedList(data: sampleData) { item in
        Text(item.title)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}