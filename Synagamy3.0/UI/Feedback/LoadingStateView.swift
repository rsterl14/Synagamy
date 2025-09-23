//
//  LoadingStateView.swift
//  Synagamy3.0
//
//  Enhanced loading states with shimmer effects and proper messaging
//

import SwiftUI

struct LoadingStateView: View {
    let message: String
    let showProgress: Bool
    @State private var shimmerOffset: CGFloat = -200
    
    init(message: String = "Loading...", showProgress: Bool = false) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: Brand.Spacing.spacing6) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: Brand.Spacing.spacing10, height: Brand.Spacing.spacing10)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Brand.Color.primary, Brand.Color.primary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: Brand.Spacing.spacing10, height: Brand.Spacing.spacing10)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .linear(duration: Brand.Motion.slower * 2).repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            }
            .onAppear {
                shimmerOffset = 200
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if showProgress {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Brand.Color.primary))
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
}

// MARK: - Shimmer Effect for Skeleton Loading

struct ShimmerView: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: shimmerOffset)
        .onAppear {
            withAnimation(.linear(duration: Brand.Motion.slower * 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Skeleton Loading for Lists

struct SkeletonListItem: View {
    var body: some View {
        HStack(spacing: Brand.Spacing.md) {
            RoundedRectangle(cornerRadius: Brand.Radius.sm)
                .fill(Color.gray.opacity(0.3))
                .frame(width: Brand.Spacing.spacing10, height: Brand.Spacing.spacing10)
                .overlay(ShimmerView().cornerRadius(Brand.Radius.sm))
            
            VStack(alignment: .leading, spacing: Brand.Spacing.xs + Brand.Spacing.spacing1) {
                RoundedRectangle(cornerRadius: Brand.Radius.sm / 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: Brand.Spacing.lg)
                    .overlay(ShimmerView().cornerRadius(Brand.Radius.sm / 2))
                
                RoundedRectangle(cornerRadius: Brand.Radius.sm / 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: Brand.Spacing.md)
                    .overlay(ShimmerView().cornerRadius(Brand.Radius.sm / 2))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, Brand.Spacing.sm)
    }
}

// MARK: - EmptyStateView is defined in EmptyStateView.swift

#Preview("Loading State") {
    LoadingStateView(message: "Loading your fertility data...", showProgress: true)
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "wifi.exclamationmark",
        title: "No Data Found",
        message: "We couldn't find any information to display. Please check your connection and try again.",
        actionTitle: "Retry",
        action: { }
    )
}

#Preview("Skeleton Loading") {
    VStack {
        ForEach(0..<5, id: \.self) { _ in
            SkeletonListItem()
        }
    }
}