// By Ahmed Raslan ®

import Foundation
import Testing
@testable import CoreEnvironment

struct AppEnvironmentTests {
    private func validDictionary() -> [String: Any] {
        [
            "APP_ENVIRONMENT_NAME": "Dev",
            "TMDB_API_BASE_URL": "https://api.themoviedb.org/3",
            "TMDB_IMAGE_BASE_URL": "https://image.tmdb.org/t/p",
            "TMDB_ACCESS_TOKEN": "test-token",
        ]
    }

    @Test func readsAllValuesFromValidDictionary() throws {
        let environment = try AppEnvironment(infoDictionary: validDictionary())

        #expect(environment.name == .dev)
        #expect(environment.apiBaseURL.absoluteString == "https://api.themoviedb.org/3")
        #expect(environment.imageBaseURL.absoluteString == "https://image.tmdb.org/t/p")
        #expect(environment.accessToken == "test-token")
    }

    @Test(arguments: ["Dev", "Staging", "Test", "Live"])
    func parsesEveryEnvironmentName(rawName: String) throws {
        var dictionary = validDictionary()
        dictionary["APP_ENVIRONMENT_NAME"] = rawName

        let environment = try AppEnvironment(infoDictionary: dictionary)

        #expect(environment.name.rawValue == rawName)
    }

    @Test(arguments: [
        "APP_ENVIRONMENT_NAME",
        "TMDB_API_BASE_URL",
        "TMDB_IMAGE_BASE_URL",
        "TMDB_ACCESS_TOKEN",
    ])
    func throwsWhenKeyIsMissing(key: String) {
        var dictionary = validDictionary()
        dictionary.removeValue(forKey: key)

        #expect(throws: AppEnvironment.ReadError.missingKey(key)) {
            try AppEnvironment(infoDictionary: dictionary)
        }
    }

    @Test(arguments: [
        "APP_ENVIRONMENT_NAME",
        "TMDB_API_BASE_URL",
        "TMDB_IMAGE_BASE_URL",
        "TMDB_ACCESS_TOKEN",
    ])
    func treatsEmptyStringAsMissing(key: String) {
        var dictionary = validDictionary()
        dictionary[key] = ""

        #expect(throws: AppEnvironment.ReadError.missingKey(key)) {
            try AppEnvironment(infoDictionary: dictionary)
        }
    }

    @Test func throwsOnUnknownEnvironmentName() {
        var dictionary = validDictionary()
        dictionary["APP_ENVIRONMENT_NAME"] = "Production"

        #expect(throws: AppEnvironment.ReadError.invalidValue(key: "APP_ENVIRONMENT_NAME", value: "Production")) {
            try AppEnvironment(infoDictionary: dictionary)
        }
    }

    @Test func throwsOnSchemelessURL() {
        var dictionary = validDictionary()
        dictionary["TMDB_API_BASE_URL"] = "api.themoviedb.org/3"

        #expect(throws: AppEnvironment.ReadError.invalidValue(key: "TMDB_API_BASE_URL", value: "api.themoviedb.org/3")) {
            try AppEnvironment(infoDictionary: dictionary)
        }
    }
}
