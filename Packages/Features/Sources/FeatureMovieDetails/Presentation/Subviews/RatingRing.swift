//
//  RatingRing.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreUI
import SwiftUI

/// Circular score indicator for TMDB's 0–10 vote average.
struct RatingRing: View {
    let score: Double

    private var fraction: Double {
        min(max(score / 10, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.rating.opacity(0.25), lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(AppColors.rating, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(score, format: .number.precision(.fractionLength(1)))
                .font(AppTypography.label)
        }
        .frame(width: 56, height: 56)
        .accessibilityElement()
        .accessibilityLabel(Text(
            "Rated \(score, format: .number.precision(.fractionLength(1))) out of 10",
            comment: "VoiceOver label for the details rating ring"
        ))
    }
}

#Preview {
    RatingRing(score: 8.4)
        .padding()
}
