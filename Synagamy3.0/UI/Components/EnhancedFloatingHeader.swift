//
//  EnhancedFloatingHeader.swift
//  Synagamy3.0
//
//  Enhanced floating header with improved visual design, subtle animations,
//  and better integration with the overall design system.
//

import SwiftUI

struct EnhancedFloatingHeader: View {
    // MARK: - Properties
    
    let primaryImage: String
    let secondaryImage: String?
    let style: HeaderStyle
    
    @State private var isVisible = false
    @State private var scrollOffset: CGFloat = 0
    
    // MARK: - Initialization
    
    init(
        primaryImage: String,
        secondaryImage: String? = nil,
        style: HeaderStyle = .standard
    ) {
        self.primaryImage = primaryImage
        self.secondaryImage = secondaryImage
        self.style = style
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: style.spacing) {
            // Primary logo
            logoView(imageName: primaryImage, isPrimary: true)
            
            // Secondary logo if provided
            if let secondaryImage = secondaryImage {
                // Divider
                if style.showDivider {
                    dividerView
                }
                
                logoView(imageName: secondaryImage, isPrimary: false)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, style.verticalPadding)
        .background(headerBackground)
        .overlay(headerOverlay)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(Brand.Motion.springGentle.delay(0.2)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("App header")
    }
    
    // MARK: - Logo View
    
    @ViewBuilder
    private func logoView(imageName: String, isPrimary: Bool) -> some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: isPrimary ? style.primaryLogoHeight : style.secondaryLogoHeight)
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
            .shadow(
                color: Brand.ColorSystem.primary.opacity(0.15),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isPrimary ? 1.0 : 0.9)
    }
    
    // MARK: - Divider View
    
    @ViewBuilder
    private var dividerView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Brand.ColorSystem.primary.opacity(0.3),
                        Brand.ColorSystem.secondary.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1, height: style.dividerHeight)
            .opacity(0.5)
    }
    
    // MARK: - Background and Overlay
    
    @ViewBuilder
    private var headerBackground: some View {
        // Base material background
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(
                // Subtle gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Brand.ColorSystem.surfaceCard.opacity(0.8),
                        Brand.ColorSystem.surfaceElevated.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: Brand.Elevation.floating.shadow.color,
                radius: Brand.Elevation.floating.shadow.radius,
                x: Brand.Elevation.floating.shadow.x,
                y: Brand.Elevation.floating.shadow.y
            )
    }
    
    @ViewBuilder
    private var headerOverlay: some View {
        // Subtle border with gradient
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Brand.ColorSystem.primary.opacity(0.1),
                        Brand.ColorSystem.secondary.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - Header Style

extension EnhancedFloatingHeader {
    enum HeaderStyle {
        case compact
        case standard
        case prominent
        
        var primaryLogoHeight: CGFloat {
            switch self {
            case .compact: return 28
            case .standard: return 36
            case .prominent: return 44
            }
        }
        
        var secondaryLogoHeight: CGFloat {
            switch self {
            case .compact: return 24
            case .standard: return 32
            case .prominent: return 40
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return Brand.Layout.spacing4
            case .standard: return Brand.Layout.spacing5
            case .prominent: return Brand.Layout.spacing6
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .compact: return Brand.Layout.spacing3
            case .standard: return Brand.Layout.spacing4
            case .prominent: return Brand.Layout.spacing5
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .compact: return Brand.Layout.spacing3
            case .standard: return Brand.Layout.spacing4
            case .prominent: return Brand.Layout.spacing5
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact: return Brand.Radius.md
            case .standard: return Brand.Radius.lg
            case .prominent: return Brand.Radius.xl
            }
        }
        
        var dividerHeight: CGFloat {
            switch self {
            case .compact: return 20
            case .standard: return 24
            case .prominent: return 28
            }
        }
        
        var showDivider: Bool {
            switch self {
            case .compact: return false
            case .standard, .prominent: return true
            }
        }
    }
}

// MARK: - Enhanced Standard Page Layout

struct EnhancedStandardPageLayout<Content: View>: View {
    // MARK: - Properties
    
    let primaryImage: String
    let secondaryImage: String?
    let headerStyle: EnhancedFloatingHeader.HeaderStyle
    let showHomeButton: Bool
    let usePopToRoot: Bool
    let content: Content
    
    @State private var headerHeight: CGFloat = 64
    @State private var isContentVisible = false
    
    // MARK: - Initialization
    
    init(
        primaryImage: String,
        secondaryImage: String? = nil,
        headerStyle: EnhancedFloatingHeader.HeaderStyle = .standard,
        showHomeButton: Bool = true,
        usePopToRoot: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.primaryImage = primaryImage
        self.secondaryImage = secondaryImage
        self.headerStyle = headerStyle
        self.showHomeButton = showHomeButton
        self.usePopToRoot = usePopToRoot
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            VStack(spacing: 0) {
                ScrollView {
                    content
                        .padding(.horizontal, Brand.Layout.pageMargins)
                        .padding(.vertical, Brand.Layout.spacing4)
                        .opacity(isContentVisible ? 1.0 : 0)
                        .offset(y: isContentVisible ? 0 : 20)
                        .onAppear {
                            withAnimation(Brand.Motion.springGentle.delay(0.4)) {
                                isContentVisible = true
                            }
                        }
                }
                .scrollIndicators(.hidden)
            }
        }
        
        // MARK: - Navigation Configuration
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if showHomeButton {
                ToolbarItem(placement: .topBarTrailing) {
                    enhancedHomeButton
                }
            }
        }
        
        // MARK: - Floating Header
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: headerHeight)
        }
        .overlay(alignment: .top) {
            EnhancedFloatingHeader(
                primaryImage: primaryImage,
                secondaryImage: secondaryImage,
                style: headerStyle
            )
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { headerHeight = geo.size.height }
                        .modifier(OnChangeHeightModifier(
                            currentHeight: $headerHeight,
                            height: geo.size.height
                        ))
                }
            )
        }
    }
    
    // MARK: - Background Gradient
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Brand.ColorSystem.surfaceBase,
                Brand.ColorSystem.surfaceCard.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Enhanced Home Button
    
    @ViewBuilder
    private var enhancedHomeButton: some View {
        Button {
            // Home button action
        } label: {
            Image(systemName: "house.fill")
                .font(.system(size: 16, weight: .medium))
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
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    Brand.ColorSystem.primary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(
                    color: Brand.ColorSystem.primary.opacity(0.15),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
        .buttonStyle(PlainButtonStyle())
        .brandPressEffect(scale: 0.9)
    }
}

// MARK: - Preview

#Preview("Enhanced Header Styles") {
    VStack(spacing: Brand.Layout.spacing6) {
        EnhancedFloatingHeader(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo",
            style: .compact
        )
        
        EnhancedFloatingHeader(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo",
            style: .standard
        )
        
        EnhancedFloatingHeader(
            primaryImage: "SynagamyLogoTwo",
            secondaryImage: "EducationLogo",
            style: .prominent
        )
    }
    .padding()
    .background(Brand.ColorSystem.surfaceBase)
}