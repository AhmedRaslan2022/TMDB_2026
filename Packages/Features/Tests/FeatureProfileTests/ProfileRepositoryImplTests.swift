//
//  ProfileRepositoryImplTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import Foundation
import KeychainStorage
import Testing
@testable import FeatureProfile

@Suite("ProfileRepositoryImpl")
struct ProfileRepositoryImplTests {
    private enum MockError: Error { case network }

    /// Mock wire — distinct favorite/watchlist counts, which a single
    /// URLProtocol stub can't express.
    private actor DataSourceMock: ProfileRemoteDataSource {
        var accountResult: Result<AccountDTO, Error>
        var favoriteCountValue = 0
        var watchlistCountValue = 0
        private(set) var accountSessions: [String] = []

        init(accountResult: Result<AccountDTO, Error> = .failure(MockError.network)) {
            self.accountResult = accountResult
        }

        func account(sessionID: String) async throws -> AccountDTO {
            accountSessions.append(sessionID)
            return try accountResult.get()
        }

        func favoriteCount(accountID _: Int, sessionID _: String) async throws -> Int {
            favoriteCountValue
        }

        func watchlistCount(accountID _: Int, sessionID _: String) async throws -> Int {
            watchlistCountValue
        }

        func setCounts(favorite: Int, watchlist: Int) {
            favoriteCountValue = favorite
            watchlistCountValue = watchlist
        }
    }

    /// In-memory keychain.
    private actor StorageMock: SecureStorage {
        private var values: [SecureStorageKey: String] = [:]
        func set(_ value: String, for key: SecureStorageKey) async throws {
            values[key] = value
        }

        func string(for key: SecureStorageKey) async throws -> String? {
            values[key]
        }

        func removeValue(for key: SecureStorageKey) async throws {
            values[key] = nil
        }

        func removeAll() async throws {
            values.removeAll()
        }
    }

    private func accountDTO(
        name: String? = "Ada",
        avatarPath: String? = "/a.jpg",
        gravatarHash: String? = "abc"
    ) -> AccountDTO {
        AccountDTO(
            id: 42,
            username: "ada",
            name: name,
            avatar: AvatarDTO(tmdb: TMDBAvatarDTO(avatarPath: avatarPath), gravatar: GravatarDTO(hash: gravatarHash))
        )
    }

    @Test("account maps the DTO and caches the account id for sync")
    func fetchesAndCachesAccountID() async throws {
        let storage = StorageMock()
        try await storage.set("sess-1", for: .sessionID)
        let dataSource = DataSourceMock(accountResult: .success(accountDTO()))
        let repository = ProfileRepositoryImpl(dataSource: dataSource, secureStorage: storage)

        let account = try await repository.account()

        #expect(account.id == 42)
        #expect(account.username == "ada")
        #expect(account.name == "Ada")
        #expect(account.avatarPath == "/a.jpg")
        #expect(account.gravatarHash == "abc")
        #expect(try await storage.string(for: .accountID) == "42", "account id cached to activate sync")
        #expect(await dataSource.accountSessions == ["sess-1"])
    }

    @Test("an empty display name normalizes to nil")
    func emptyNameNormalized() async throws {
        let storage = StorageMock()
        try await storage.set("sess-1", for: .sessionID)
        let dataSource = DataSourceMock(accountResult: .success(accountDTO(name: "", avatarPath: "", gravatarHash: "")))
        let repository = ProfileRepositoryImpl(dataSource: dataSource, secureStorage: storage)

        let account = try await repository.account()

        #expect(account.name == nil)
        #expect(account.avatarPath == nil)
        #expect(account.gravatarHash == nil)
    }

    @Test("account throws notAuthenticated when there's no session")
    func notAuthenticated() async {
        let dataSource = DataSourceMock(accountResult: .success(accountDTO()))
        let repository = ProfileRepositoryImpl(dataSource: dataSource, secureStorage: StorageMock())

        await #expect(throws: ProfileError.notAuthenticated) {
            try await repository.account()
        }
    }

    @Test("stats maps favorite and watchlist counts to the right fields")
    func statsMapsCounts() async throws {
        let storage = StorageMock()
        try await storage.set("sess-1", for: .sessionID)
        let dataSource = DataSourceMock()
        await dataSource.setCounts(favorite: 12, watchlist: 5)
        let repository = ProfileRepositoryImpl(dataSource: dataSource, secureStorage: storage)

        let stats = try await repository.stats(for: 42)

        #expect(stats == AccountStats(favoriteCount: 12, watchlistCount: 5))
    }

    @Test("stats throws notAuthenticated when there's no session")
    func statsNotAuthenticated() async {
        let repository = ProfileRepositoryImpl(dataSource: DataSourceMock(), secureStorage: StorageMock())

        await #expect(throws: ProfileError.notAuthenticated) {
            try await repository.stats(for: 42)
        }
    }
}
