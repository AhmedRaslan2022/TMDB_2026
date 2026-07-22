//
//  TMDBApprovalFlowTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation
import Testing
@testable import FeatureAuth

@Suite("TMDBApprovalFlow")
struct TMDBApprovalFlowTests {
    private let token = RequestToken(value: "token-123", expiresAt: .distantFuture)

    @Test("approval URL targets TMDB's authenticate page with our callback")
    func approvalURL() throws {
        let url = try TMDBApprovalFlow.approvalURL(for: token)

        #expect(url.scheme == "https")
        #expect(url.host() == "www.themoviedb.org")
        #expect(url.path() == "/authenticate/token-123")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "redirect_to", value: "tmdb-auth://callback")])
    }

    @Test("approved redirect for the same token is .approved")
    func approvedOutcome() throws {
        let callback = try #require(URL(string: "tmdb-auth://callback?request_token=token-123&approved=true"))

        #expect(TMDBApprovalFlow.outcome(of: callback, expecting: token) == .approved)
    }

    @Test("denied redirect is .denied")
    func deniedOutcome() throws {
        let callback = try #require(URL(string: "tmdb-auth://callback?request_token=token-123&denied=true"))

        #expect(TMDBApprovalFlow.outcome(of: callback, expecting: token) == .denied)
    }

    @Test("approved redirect for a DIFFERENT token is .invalid")
    func tokenMismatchIsInvalid() throws {
        let callback = try #require(URL(string: "tmdb-auth://callback?request_token=other&approved=true"))

        #expect(TMDBApprovalFlow.outcome(of: callback, expecting: token) == .invalid)
    }

    @Test("redirect without approval markers is .invalid")
    func missingMarkersIsInvalid() throws {
        let callback = try #require(URL(string: "tmdb-auth://callback?request_token=token-123"))

        #expect(TMDBApprovalFlow.outcome(of: callback, expecting: token) == .invalid)
    }

    @Test("redirect with no query at all is .invalid")
    func noQueryIsInvalid() throws {
        let callback = try #require(URL(string: "tmdb-auth://callback"))

        #expect(TMDBApprovalFlow.outcome(of: callback, expecting: token) == .invalid)
    }
}
