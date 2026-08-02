//
//  SplashView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import CoreUI
import SwiftUI

/// The in-app splash shown at the root while `LaunchUseCase` resolves the
/// destination. Its background is the brand primary — the same color as the
/// static launch screen (`LaunchBackground`) — so the OS launch screen hands
/// off to it seamlessly; the wordmark then scales and fades in.
struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppColors.brandPrimary
                .ignoresSafeArea()

            Text(verbatim: "TMDB")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(AppColors.brandSecondary)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .accessibilityHidden(true)
        }
        .task {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

#if DEBUG
    #Preview {
        SplashView()
    }
#endif
