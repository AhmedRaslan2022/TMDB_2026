//
//  TVHomeView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// The TV tab: on-air / popular / top-rated shows as vertically stacked
/// horizontal carousels. Navigation intent is reported through `onSelectShow`
/// — the coordinator decides what happens.
public struct TVHomeView: View {
    @State private var viewModel: TVHomeViewModel
    private let onSelectShow: (Int) -> Void

    public init(viewModel: TVHomeViewModel, onSelectShow: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectShow = onSelectShow
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                ForEach(TVList.allCases, id: \.self) { list in
                    TVSectionView(
                        list: list,
                        state: viewModel.state(for: list),
                        posterURL: viewModel.posterURL(for:),
                        onSelectShow: onSelectShow,
                        onRetry: { Task { await viewModel.retry(list: list) } }
                    )
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle(Text("TV Shows", comment: "TV tab title"))
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
    }
}
