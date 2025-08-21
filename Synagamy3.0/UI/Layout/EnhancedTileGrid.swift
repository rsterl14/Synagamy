//
//  EnhancedTileGrid.swift
//  Synagamy3.0
//
//  Enhanced tile grid with staggered animations, improved spacing,
//  and adaptive layout for different screen sizes.
//

import SwiftUI

struct EnhancedTileGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    // MARK: - Properties
    
    let data: Data
    let content: (Data.Element) -> Content
    let style: GridStyle
    let animationStyle: AnimationStyle
    let emptyStateConfig: EmptyStateConfig?
    
    @State private var visibleIndices: Set<Int> = []
    
    // MARK: - Initialization
    
    init(
        data: Data,
        style: GridStyle = .standard,
        animationStyle: AnimationStyle = .staggered,
        emptyStateConfig: EmptyStateConfig? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.style = style
        self.animationStyle = animationStyle
        self.emptyStateConfig = emptyStateConfig
    }
    
    // MARK: - Body
    
    var body: some View {
        if data.isEmpty {
            emptyStateView
        } else {
            gridContent
        }
    }
    
    // MARK: - Grid Content
    
    @ViewBuilder
    private var gridContent: some View {
        switch style.layout {
        case .single:
            singleColumnGrid
        case .adaptive:
            adaptiveGrid
        case .fixed(let columns):
            fixedColumnGrid(columns: columns)
        }
    }
    
    // MARK: - Single Column Grid
    
    @ViewBuilder
    private var singleColumnGrid: some View {
        LazyVStack(spacing: style.spacing) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .modifier(GridItemAnimationModifier(
                        index: index,
                        animationStyle: animationStyle,
                        isVisible: visibleIndices.contains(index)
                    ))
                    .onAppear {
                        animateAppearance(at: index)
                    }
            }
        }
    }
    
    // MARK: - Adaptive Grid
    
    @ViewBuilder
    private var adaptiveGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: style.minimumItemWidth), spacing: style.spacing)
            ],
            spacing: style.spacing
        ) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .modifier(GridItemAnimationModifier(
                        index: index,
                        animationStyle: animationStyle,
                        isVisible: visibleIndices.contains(index)
                    ))
                    .onAppear {
                        animateAppearance(at: index)
                    }
            }
        }
    }
    
    // MARK: - Fixed Column Grid
    
    @ViewBuilder
    private func fixedColumnGrid(columns: Int) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: style.spacing), count: columns),
            spacing: style.spacing
        ) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .modifier(GridItemAnimationModifier(
                        index: index,
                        animationStyle: animationStyle,
                        isVisible: visibleIndices.contains(index)
                    ))
                    .onAppear {
                        animateAppearance(at: index)
                    }
            }
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyStateView: some View {
        let config = emptyStateConfig ?? EmptyStateConfig.defaultConfig
        
        VStack(spacing: Brand.Layout.spacing6) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Brand.ColorSystem.primaryLight,
                                Brand.ColorSystem.secondaryLight
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: config.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Brand.ColorSystem.primary,
                                Brand.ColorSystem.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(
                color: Brand.ColorSystem.primary.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
            
            VStack(spacing: Brand.Layout.spacing3) {
                Text(config.title)
                    .font(Brand.Typography.headlineMedium)
                    .foregroundColor(Brand.ColorSystem.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(config.message)
                    .font(Brand.Typography.bodyMedium)
                    .foregroundColor(Brand.ColorSystem.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Brand.Layout.spacing8)
        .frame(maxWidth: .infinity)
        .brandCardStyle()
    }
    
    // MARK: - Animation Logic
    
    private func animateAppearance(at index: Int) {
        guard !visibleIndices.contains(index) else { return }
        
        let delay = animationStyle.delay(for: index)
        
        let _ = withAnimation(Brand.Motion.springGentle.delay(delay)) {
            visibleIndices.insert(index)
        }
    }
}

// MARK: - Grid Style

extension EnhancedTileGrid {
    enum GridStyle {
        case single(spacing: CGFloat = Brand.Layout.spacing5)
        case adaptive(spacing: CGFloat = Brand.Layout.spacing5, minimumWidth: CGFloat = 150)
        case fixed(columns: Int, spacing: CGFloat = Brand.Layout.spacing5)
        
        static var standard: GridStyle { .single() }
        static var compact: GridStyle { .adaptive(spacing: Brand.Layout.spacing4, minimumWidth: 120) }
        static var twoColumn: GridStyle { .fixed(columns: 2) }
        
        var spacing: CGFloat {
            switch self {
            case .single(let spacing), .adaptive(let spacing, _), .fixed(_, let spacing):
                return spacing
            }
        }
        
        var minimumItemWidth: CGFloat {
            switch self {
            case .adaptive(_, let minimumWidth):
                return minimumWidth
            default:
                return 150
            }
        }
        
        var layout: LayoutType {
            switch self {
            case .single:
                return .single
            case .adaptive:
                return .adaptive
            case .fixed(let columns, _):
                return .fixed(columns)
            }
        }
        
        enum LayoutType {
            case single
            case adaptive
            case fixed(Int)
        }
    }
}

// MARK: - Animation Style

enum AnimationStyleType {
    case none
    case fade
    case staggered
    case wave
    
    func delay(for index: Int) -> TimeInterval {
        switch self {
        case .none, .fade:
            return 0
        case .staggered:
            return Double(index) * 0.1
        case .wave:
            return Double(index % 3) * 0.15
        }
    }
}

extension EnhancedTileGrid {
    typealias AnimationStyle = AnimationStyleType
}

// MARK: - Grid Item Animation Modifier

private struct GridItemAnimationModifier: ViewModifier {
    let index: Int
    let animationStyle: AnimationStyleType
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0)
            .offset(y: isVisible ? 0 : 30)
            .rotation3DEffect(
                .degrees(isVisible ? 0 : -15),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
    }
}

// MARK: - Enhanced Empty State Config

extension EmptyStateConfig {
    static let educationEnhanced = EmptyStateConfig(
        icon: "graduationcap.circle",
        title: "No Topics Available",
        message: "Educational content is being prepared. Check back soon for comprehensive learning materials."
    )
    
    static let pathwaysEnhanced = EmptyStateConfig(
        icon: "map.circle",
        title: "No Pathways Found",
        message: "Treatment pathways are being updated. Explore other sections while we prepare your personalized options."
    )
    
    static let questionsEnhanced = EmptyStateConfig(
        icon: "questionmark.bubble",
        title: "No Questions Yet",
        message: "Common questions will appear here. Feel free to explore educational content in the meantime."
    )
}

// MARK: - Preview

private struct SampleItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

#Preview("Enhanced Grid Styles") {
    let sampleData = [
        SampleItem(title: "Education", subtitle: "Learn about fertility", icon: "book.fill"),
        SampleItem(title: "Pathways", subtitle: "Treatment options", icon: "map.fill"),
        SampleItem(title: "Resources", subtitle: "Helpful guides", icon: "doc.text.fill"),
        SampleItem(title: "Questions", subtitle: "Common concerns", icon: "questionmark.circle.fill"),
    ]
    
    NavigationView {
        ScrollView {
            VStack(spacing: Brand.Layout.spacing8) {
                // Single column with staggered animation
                VStack(alignment: .leading, spacing: Brand.Layout.spacing4) {
                    Text("Single Column")
                        .font(Brand.Typography.headlineMedium)
                        .foregroundColor(Brand.ColorSystem.textPrimary)
                    
                    EnhancedTileGrid(
                        data: sampleData,
                        style: .standard,
                        animationStyle: .staggered
                    ) { item in
                        BrandTile(
                            title: item.title,
                            subtitle: item.subtitle,
                            systemIcon: item.icon,
                            isCompact: false
                        )
                    }
                }
                
                Divider()
                
                // Adaptive grid
                VStack(alignment: .leading, spacing: Brand.Layout.spacing4) {
                    Text("Adaptive Grid")
                        .font(Brand.Typography.headlineMedium)
                        .foregroundColor(Brand.ColorSystem.textPrimary)
                    
                    EnhancedTileGrid(
                        data: sampleData,
                        style: .compact,
                        animationStyle: .wave
                    ) { item in
                        BrandTile(
                            title: item.title,
                            subtitle: item.subtitle,
                            systemIcon: item.icon,
                            isCompact: true
                        )
                    }
                }
                
                Divider()
                
                // Empty state
                VStack(alignment: .leading, spacing: Brand.Layout.spacing4) {
                    Text("Empty State")
                        .font(Brand.Typography.headlineMedium)
                        .foregroundColor(Brand.ColorSystem.textPrimary)
                    
                    EnhancedTileGrid(
                        data: [] as [SampleItem],
                        emptyStateConfig: .educationEnhanced
                    ) { item in
                        EmptyView()
                    }
                }
            }
            .padding(Brand.Layout.pageMargins)
        }
        .background(Brand.ColorSystem.surfaceBase)
        .navigationTitle("Enhanced Grids")
    }
}