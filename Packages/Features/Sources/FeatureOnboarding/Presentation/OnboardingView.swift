//
//  OnboardingView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 26/07/2026.
//

import CoreUI
import SwiftUI

/// First-launch walkthrough: a swipeable, paged set of slides with a Skip
/// shortcut and a primary CTA that advances (or finishes on the last slide).
/// Purely presentational — all decisions live in `OnboardingViewModel`.
public struct OnboardingView: View {
    @Bindable private var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        _viewModel = Bindable(viewModel)
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            skipBar

            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingSlide(page: page)
                        .tag(index)
                }
            }
            .animation(.easeInOut, value: viewModel.currentIndex)
            // `.page` paging is iOS-only; the package also builds for the
            // macOS host (unit tests), where a plain TabView still compiles.
            #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
            #endif

            cta
        }
        .accessibilityIdentifier("onboarding.root")
    }

    private var skipBar: some View {
        HStack {
            Spacer()
            // Reserve the row even on the last slide so the pager doesn't jump.
            Button {
                withAnimation { viewModel.skip() }
            } label: {
                Text("Skip", bundle: .module, comment: "Onboarding: skip the walkthrough")
                    .font(AppTypography.label)
            }
            .tint(AppColors.brandSecondary)
            .opacity(viewModel.isOnLastPage ? 0 : 1)
            .disabled(viewModel.isOnLastPage)
            .accessibilityIdentifier("onboarding.skip")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
    }

    private var cta: some View {
        Button {
            withAnimation { viewModel.advance() }
        } label: {
            Group {
                if viewModel.isOnLastPage {
                    Text("Get Started", bundle: .module, comment: "Onboarding: finish and enter the app")
                } else {
                    Text("Next", bundle: .module, comment: "Onboarding: advance to the next slide")
                }
            }
            .font(AppTypography.title)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.brandSecondary)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
        .accessibilityIdentifier("onboarding.cta")
    }
}

/// A single onboarding slide: large SF Symbol over a title and message.
private struct OnboardingSlide: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: page.systemImage)
                .font(.system(size: 88, weight: .semibold))
                .foregroundStyle(AppColors.brandSecondary)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.md) {
                Text(page.title)
                    .font(AppTypography.screenTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(page.message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
    private struct PreviewCompletion: OnboardingCompletion {
        func completeOnboarding() {}
    }

    #Preview {
        OnboardingView(viewModel: OnboardingViewModel(completion: PreviewCompletion()))
    }
#endif
