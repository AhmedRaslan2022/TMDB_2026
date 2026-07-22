//
//  AppContainer+Person.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreEnvironment
import FeaturePerson

/// Person screen factory — the same screen-factory role as AppContainer's other
/// `make…ViewModel` methods, in its own file to keep AppContainer.swift under
/// the file-length budget.
extension AppContainer {
    /// Builds a person details view model. Called per push — each pushed
    /// person screen owns its own fetch state.
    func makePersonViewModel(personID: Int) -> PersonViewModel {
        #if DEBUG
            if UITestStubs.isActive {
                return PersonViewModel(
                    personID: personID,
                    fetchDetails: StubFetchPersonDetailsUseCase(),
                    imageBaseURL: environment.imageBaseURL
                )
            }
        #endif
        return PersonViewModel(
            personID: personID,
            fetchDetails: FetchPersonDetailsUseCaseImpl(repository: PersonRepositoryImpl(apiClient: apiClient)),
            imageBaseURL: environment.imageBaseURL
        )
    }
}
