//
//  PersonView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The person details screen: headshot + bio header and a filmography grid of
/// their movie/TV credits. Tapping a credit reports the title through
/// `onSelectTitle` — the coordinator decides whether it's a movie or TV push.
public struct PersonView: View {
    @State private var viewModel: PersonViewModel
    private let onSelectTitle: (MediaItem) -> Void

    public init(viewModel: PersonViewModel, onSelectTitle: @escaping (MediaItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectTitle = onSelectTitle
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
                .accessibilityLabel(Text("Loading", comment: "VoiceOver label while person details load"))
        case let .error(message):
            errorView(message)
        case let .loaded(bundle):
            loadedView(bundle)
        }
    }

    private func loadedView(_ bundle: PersonDetailsBundle) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header(bundle.person)
                biography(bundle.person)
                filmography(bundle.filmography)
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle(bundle.person.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func header(_ person: Person) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            RemoteImage(url: viewModel.headshotURL(for: person)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(AppColors.brandPrimary.opacity(0.15))
                    .overlay { Image(systemName: "person.fill").foregroundStyle(AppColors.textSecondary) }
            }
            .frame(width: 110, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(person.name)
                    .font(AppTypography.title)
                    .accessibilityIdentifier("person.name")
                if let department = person.knownForDepartment {
                    Text(verbatim: department)
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.brandSecondary)
                }
                let birth = viewModel.birthLine(for: person)
                if !birth.isEmpty {
                    Text(verbatim: birth)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private func biography(_ person: Person) -> some View {
        if !person.biography.isEmpty {
            Text(person.biography)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private func filmography(_ credits: [PersonCredit]) -> some View {
        if !credits.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Known For", comment: "Person filmography section title")
                    .font(AppTypography.title)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, AppSpacing.lg)
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 130), spacing: AppSpacing.md, alignment: .top)],
                    spacing: AppSpacing.lg
                ) {
                    ForEach(credits) { credit in
                        PosterCard(
                            title: credit.media.title,
                            posterURL: viewModel.posterURL(for: credit),
                            rating: credit.media.voteCount > 0 ? credit.media.voteAverage : nil,
                            accessibilityID: "person.credit.\(credit.id)",
                            onSelect: { onSelectTitle(credit.media) }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    private func errorView(_ message: LocalizedStringResource) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Button { Task { await viewModel.load() } } label: {
                Text("Retry", comment: "Retry loading person details")
                    .font(AppTypography.label)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.brandSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
