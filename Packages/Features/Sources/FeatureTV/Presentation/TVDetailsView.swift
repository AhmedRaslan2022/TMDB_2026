//
//  TVDetailsView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The TV details screen: backdrop header, metadata, overview, and a "More
/// Like This" carousel. Navigation intent is reported through `onSelectShow`.
public struct TVDetailsView: View {
    @State private var viewModel: TVDetailsViewModel
    private let onSelectShow: (Int) -> Void

    public init(viewModel: TVDetailsViewModel, onSelectShow: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectShow = onSelectShow
    }

    public var body: some View {
        content
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(Text("Loading", bundle: .module, comment: "VoiceOver label while TV details load"))
        case let .error(message):
            errorView(message)
        case let .loaded(bundle):
            loadedView(bundle)
        }
    }

    private func loadedView(_ bundle: TVShowDetailsBundle) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                RemoteImage(url: viewModel.backdropURL(for: bundle.details)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.brandPrimary.opacity(0.2))
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)

                summaryBlock(bundle.details)
                relatedCarousel(bundle.similar)
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .navigationTitle(bundle.details.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .ignoresSafeArea(edges: .top)
    }

    private func summaryBlock(_ details: TVShowDetails) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(details.name)
                .font(AppTypography.title)
                .accessibilityIdentifier("tv.details.title")
            metadataLine(details)
            if !details.genres.isEmpty {
                Text(details.genres.joined(separator: ", "))
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.brandSecondary)
            }
            if !details.overview.isEmpty {
                Text(details.overview)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private func metadataLine(_ details: TVShowDetails) -> some View {
        let metadata = viewModel.metadata(for: details)
        if !metadata.isEmpty {
            Text(verbatim: metadata)
                .font(AppTypography.label)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    @ViewBuilder
    private func relatedCarousel(_ shows: [MediaItem]) -> some View {
        if !shows.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("More Like This", bundle: .module, comment: "Similar TV shows section title")
                    .font(AppTypography.title)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, AppSpacing.lg)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                        ForEach(shows) { show in
                            PosterCard(
                                title: show.title,
                                posterURL: viewModel.posterURL(for: show),
                                rating: show.voteCount > 0 ? show.voteAverage : nil,
                                accessibilityID: "tv.similar.\(show.id)",
                                onSelect: { onSelectShow(show.id) }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }

    private func errorView(_ message: LocalizedStringResource) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Button { Task { await viewModel.load() } } label: {
                Text("Retry", bundle: .module, comment: "Retry loading TV details")
                    .font(AppTypography.label)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.brandSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
