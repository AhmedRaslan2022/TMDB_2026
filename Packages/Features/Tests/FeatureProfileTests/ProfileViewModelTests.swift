//
//  ProfileViewModelTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import Testing
@testable import FeatureProfile

@MainActor
@Suite("ProfileViewModel")
struct ProfileViewModelTests {
    private enum MockError: Error { case network }

    @MainActor
    private final class RepositoryMock: ProfileRepository {
        var accountResult: Result<Account, Error> = .failure(MockError.network)
        var statsResult: Result<AccountStats, Error> = .success(AccountStats(favoriteCount: 0, watchlistCount: 0))
        private(set) var accountCalls = 0

        func account() async throws -> Account {
            accountCalls += 1
            return try accountResult.get()
        }

        func stats(for _: Int) async throws -> AccountStats {
            try statsResult.get()
        }
    }

    private let repository = RepositoryMock()

    private func makeViewModel() throws -> ProfileViewModel {
        try ProfileViewModel(repository: repository, imageBaseURL: #require(URL(string: "https://img.invalid/t/p")))
    }

    @Test("loads account and stats into the loaded state")
    func loadsAccountAndStats() async throws {
        repository.accountResult = .success(Account(id: 42, username: "ada"))
        repository.statsResult = .success(AccountStats(favoriteCount: 12, watchlistCount: 5))
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.state == .loaded(Account(id: 42, username: "ada"), AccountStats(favoriteCount: 12, watchlistCount: 5)))
    }

    @Test("a stats failure still shows the account with zeroed counts")
    func statsFailureDegrades() async throws {
        repository.accountResult = .success(Account(id: 42, username: "ada"))
        repository.statsResult = .failure(MockError.network)
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.state == .loaded(Account(id: 42, username: "ada"), AccountStats(favoriteCount: 0, watchlistCount: 0)))
    }

    @Test("a guest session lands in the guest state")
    func guestState() async throws {
        repository.accountResult = .failure(ProfileError.notAuthenticated)
        let viewModel = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.state == .guest)
    }

    @Test("a network failure lands in error")
    func errorState() async throws {
        repository.accountResult = .failure(MockError.network)
        let viewModel = try makeViewModel()

        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("expected .error, got \(viewModel.state)")
            return
        }
    }

    @Test("load is idempotent once resolved")
    func idempotent() async throws {
        repository.accountResult = .success(Account(id: 42, username: "ada"))
        let viewModel = try makeViewModel()
        await viewModel.load()

        await viewModel.load()

        #expect(repository.accountCalls == 1)
    }

    @Test("avatar URL prefers TMDB, falls back to Gravatar, else nil")
    func avatarURL() throws {
        let viewModel = try makeViewModel()

        let tmdb = Account(id: 1, username: "a", avatarPath: "/x.jpg", gravatarHash: "h")
        #expect(viewModel.avatarURL(for: tmdb)?.absoluteString == "https://img.invalid/t/p/w185/x.jpg")

        let gravatar = Account(id: 2, username: "b", gravatarHash: "h")
        #expect(viewModel.avatarURL(for: gravatar)?.absoluteString == "https://www.gravatar.com/avatar/h?s=200&d=identicon")

        #expect(viewModel.avatarURL(for: Account(id: 3, username: "c")) == nil)
    }
}
