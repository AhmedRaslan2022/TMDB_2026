//
//  AppContainer+TV.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreEnvironment
import FeatureTV

/// TV tab factories — the same screen-factory role as AppContainer's other
/// `make…ViewModel` methods, split into their own file so AppContainer.swift
/// stays under the file-length budget.
extension AppContainer {
    /// Builds the TV tab's browse view model. Screen-scoped, one per shell.
    func makeTVHomeViewModel() -> TVHomeViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return TVHomeViewModel(fetchTVList: StubFetchTVListUseCase(), imageBaseURL: environment.imageBaseURL)
            }
        #endif
        return TVHomeViewModel(
            fetchTVList: FetchTVListUseCaseImpl(repository: TVListRepositoryImpl(apiClient: apiClient)),
            imageBaseURL: environment.imageBaseURL
        )
    }

    /// Builds a TV details view model. Called per push — each pushed screen
    /// owns its own fetch state.
    func makeTVDetailsViewModel(showID: Int) -> TVDetailsViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return TVDetailsViewModel(
                    showID: showID,
                    fetchDetails: StubFetchTVDetailsUseCase(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return TVDetailsViewModel(
            showID: showID,
            fetchDetails: FetchTVDetailsUseCaseImpl(repository: TVDetailsRepositoryImpl(apiClient: apiClient)),
            imageBaseURL: environment.imageBaseURL
        )
    }
}
