//
//  OptimizedModifiers.swift
//  Synagamy3.0
//
//  High-performance view modifiers that replace common styling patterns
//  with optimized implementations. Reduces view hierarchy complexity
//  and improves rendering performance.
//

import SwiftUI

// MARK: - Enhanced Content Block Modifier
struct EnhancedContentModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    init(cornerRadius: CGFloat = 16, padding: CGFloat = 16) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Brand.ColorToken.hairline, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Optimized Card Style
struct OptimizedCardModifier: ViewModifier {
    let shadowStyle: ShadowStyle
    let cornerRadius: CGFloat
    
    enum ShadowStyle {
        case none, subtle, card, floating
        
        var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .none: return (.clear, 0, 0, 0)
            case .subtle: return (Brand.ColorSystem.primary.opacity(0.05), 4, 0, 1)
            case .card: return (Brand.ColorSystem.primary.opacity(0.08), 14, 0, 8)
            case .floating: return (Brand.ColorSystem.primary.opacity(0.12), 20, 0, 12)
            }
        }
    }
    
    init(shadow: ShadowStyle = .card, cornerRadius: CGFloat = 16) {
        self.shadowStyle = shadow
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(
                color: shadowStyle.shadow.color,
                radius: shadowStyle.shadow.radius,
                x: shadowStyle.shadow.x,
                y: shadowStyle.shadow.y
            )
    }
}

// MARK: - Optimized Animation Modifier
struct OptimizedAnimationModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let animation: Animation
    
    init(value: Value, animation: Animation = Brand.Motion.userInteraction) {
        self.value = value
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .animation(animation, value: value)
    }
}

// MARK: - Memory-Efficient Background Modifier
struct MemoryEfficientBackgroundModifier<Background: View>: ViewModifier {
    let background: Background
    
    func body(content: Content) -> some View {
        content.overlay(
            background,
            alignment: .center
        )
    }
}

// MARK: - Optimized Sheet Presentation
struct OptimizedSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let sheetContent: (Item) -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $item) { item in
                self.sheetContent(item)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .tint(Brand.ColorSystem.primary)
            }
    }
}

// MARK: - High-Performance Button Style
struct OptimizedButtonStyle: ButtonStyle {
    let style: Style
    
    enum Style {
        case primary, secondary, ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Brand.ColorSystem.primary
            case .secondary: return Brand.ColorSystem.primary.opacity(0.1)
            case .ghost: return .clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary, .ghost: return Brand.ColorSystem.primary
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Brand.Motion.userInteraction, value: configuration.isPressed)
    }
}

// MARK: - Optimized Conditional Modifier
struct ConditionalModifier<TrueModifier: ViewModifier, FalseModifier: ViewModifier>: ViewModifier {
    let condition: Bool
    let trueModifier: TrueModifier
    let falseModifier: FalseModifier
    
    func body(content: Content) -> some View {
        Group {
            if condition {
                content.modifier(trueModifier)
            } else {
                content.modifier(falseModifier)
            }
        }
    }
}

// MARK: - Performance-Optimized Text Modifier
struct OptimizedTextModifier: ViewModifier {
    let style: TextStyle
    
    enum TextStyle {
        case title, headline, body, caption
        
        var font: Font {
            switch self {
            case .title: return .largeTitle.bold()
            case .headline: return .headline.weight(.semibold)
            case .body: return .callout
            case .caption: return .caption2
            }
        }
        
        var color: Color {
            switch self {
            case .title, .headline: return Brand.ColorSystem.primary
            case .body, .caption: return .primary
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(style.color)
    }
}

// MARK: - Efficient Geometry Reader Replacement
struct FrameReaderModifier: ViewModifier {
    let onChange: (CGSize) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            onChange(geometry.size)
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            onChange(newSize)
                        }
                }
            )
    }
}

// MARK: - SwiftUI Extensions
extension View {
    /// Applies enhanced content styling with optimized performance
    func enhancedContent(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        modifier(EnhancedContentModifier(cornerRadius: cornerRadius, padding: padding))
    }
    
    /// Applies optimized card styling
    func optimizedCard(
        shadow: OptimizedCardModifier.ShadowStyle = .card,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(OptimizedCardModifier(shadow: shadow, cornerRadius: cornerRadius))
    }
    
    /// Applies optimized animation
    func optimizedAnimation<Value: Equatable>(
        value: Value,
        animation: Animation = Brand.Motion.userInteraction
    ) -> some View {
        modifier(OptimizedAnimationModifier(value: value, animation: animation))
    }
    
    /// Memory-efficient alternative to .background()
    func efficientBackground<Background: View>(@ViewBuilder background: () -> Background) -> some View {
        modifier(MemoryEfficientBackgroundModifier(background: background()))
    }
    
    /// Optimized sheet presentation
    func optimizedSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(OptimizedSheetModifier(item: item, sheetContent: content))
    }
    
    /// Applies conditional modifiers efficiently
    func conditionalModifier<TrueModifier: ViewModifier, FalseModifier: ViewModifier>(
        condition: Bool,
        trueModifier: TrueModifier,
        falseModifier: FalseModifier
    ) -> some View {
        modifier(ConditionalModifier(
            condition: condition,
            trueModifier: trueModifier,
            falseModifier: falseModifier
        ))
    }
    
    /// Optimized text styling
    func optimizedText(style: OptimizedTextModifier.TextStyle) -> some View {
        modifier(OptimizedTextModifier(style: style))
    }
    
    /// Efficient frame size reading
    func onFrameChange(_ onChange: @escaping (CGSize) -> Void) -> some View {
        modifier(FrameReaderModifier(onChange: onChange))
    }
    
    /// Applies optimized button styling
    func optimizedButtonStyle(_ style: OptimizedButtonStyle.Style) -> some View {
        buttonStyle(OptimizedButtonStyle(style: style))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Enhanced Content")
            .enhancedContent()
        
        Text("Optimized Card")
            .padding()
            .optimizedCard()
        
        Button("Primary Button") {}
            .optimizedButtonStyle(.primary)
        
        Button("Secondary Button") {}
            .optimizedButtonStyle(.secondary)
        
        Text("Title Text")
            .optimizedText(style: .title)
        
        Text("Body Text")
            .optimizedText(style: .body)
    }
    .padding()
}