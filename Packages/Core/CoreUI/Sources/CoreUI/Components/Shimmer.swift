//
//  Shimmer.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import SwiftUI

public extension View {
    /// Skeleton shimmer for loading placeholders: a highlight band sweeps
    /// across the masked content. Falls back to a gentle opacity pulse when
    /// Reduce Motion is on.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// See `View.shimmering()`.
public struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.3
    @State private var pulsing = false

    public init() {}

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
                .opacity(pulsing ? 0.45 : 0.8)
                .onAppear {
                    // Reset without animating first: onAppear can re-fire
                    // (backgrounding kills animations; tab round-trips), and
                    // restarting from the end value would freeze the pulse.
                    withTransaction(Transaction(animation: nil)) { pulsing = false }
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                }
        } else {
            content
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.4), location: phase - 0.3),
                            .init(color: .black, location: phase),
                            .init(color: .black.opacity(0.4), location: phase + 0.3),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .onAppear {
                    withTransaction(Transaction(animation: nil)) { phase = -0.3 }
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1.3
                    }
                }
        }
    }
}

/// A neutral rounded block used to sketch loading layouts.
public struct SkeletonBox: View {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = AppRadius.sm) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.textSecondary.opacity(0.2))
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        SkeletonBox(cornerRadius: AppRadius.md)
            .frame(width: 130, height: 195)
        SkeletonBox()
            .frame(width: 110, height: 12)
        SkeletonBox()
            .frame(width: 70, height: 12)
    }
    .shimmering()
    .padding(AppSpacing.lg)
}
