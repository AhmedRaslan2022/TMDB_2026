//
//  LoggingAPIClientTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import Foundation
import Testing
@testable import Networking

@Suite("LoggingAPIClient")
struct LoggingAPIClientTests {
    /// Thread-safe capture of the emitted log lines.
    private final class Sink: @unchecked Sendable {
        private let lock = NSLock()
        private var lines: [String] = []
        func append(_ line: String) {
            lock.withLock { lines.append(line) }
        }

        var text: String {
            lock.withLock { lines.joined(separator: "\n") }
        }
    }

    /// Returns a preset payload (or error) without any network.
    private struct MockClient: APIClient {
        var result: Result<Data, Error> = .success(Data())
        func send<T: Decodable & Sendable>(_: some Endpoint) async throws -> T {
            try JSONDecoder().decode(T.self, from: result.get())
        }

        func sendRaw(_: some Endpoint) async throws -> Data {
            try result.get()
        }
    }

    private struct RatingEndpoint: Endpoint {
        let path = "/movie/550/rating"
        let method = HTTPMethod.post
        let queryItems = [
            URLQueryItem(name: "session_id", value: "SECRET-SESSION"),
            URLQueryItem(name: "page", value: "1"),
        ]
        let body = try? JSONSerialization.data(withJSONObject: ["value": 8, "api_key": "SECRET-KEY"])
    }

    private func makeClient(_ result: Result<Data, Error>, into sink: Sink) -> LoggingAPIClient {
        LoggingAPIClient(wrapping: MockClient(result: result), log: { sink.append($0) })
    }

    @Test("sendRaw delegates the wrapped result and logs request + response with emojis")
    func sendRawDelegatesAndLogs() async throws {
        let sink = Sink()
        let client = makeClient(.success(Data("payload".utf8)), into: sink)

        let data = try await client.sendRaw(RatingEndpoint())

        #expect(data == Data("payload".utf8))
        #expect(sink.text.contains("📤"))
        #expect(sink.text.contains("POST /movie/550/rating"))
        #expect(sink.text.contains("📥 ✅"))
    }

    @Test("sensitive query + body values are redacted; safe params are kept")
    func redactsSecrets() async throws {
        let sink = Sink()
        let client = makeClient(.success(Data()), into: sink)

        _ = try await client.sendRaw(RatingEndpoint())

        #expect(sink.text.contains("session_id=•••"), "session id redacted")
        #expect(sink.text.contains("SECRET-SESSION") == false, "raw session never logged")
        #expect(sink.text.contains("SECRET-KEY") == false, "api_key in body redacted")
        #expect(sink.text.contains("page=1"), "non-sensitive params are shown")
    }

    @Test("send decodes, delegates, and logs the response type")
    func sendDecodesAndLogs() async throws {
        struct Model: Decodable, Sendable { let rating: Int }
        let sink = Sink()
        let client = makeClient(.success(Data(#"{"rating": 7}"#.utf8)), into: sink)

        let model: Model = try await client.send(RatingEndpoint())

        #expect(model.rating == 7)
        #expect(sink.text.contains("→ Model"))
    }

    @Test("a failure is logged with the error and rethrown")
    func logsAndRethrowsError() async {
        let sink = Sink()
        let client = makeClient(.failure(APIError.notFound), into: sink)

        await #expect(throws: APIError.self) {
            _ = try await client.sendRaw(RatingEndpoint())
        }
        #expect(sink.text.contains("❌"))
    }

    @Test("a transport error never leaks the request URL's query secrets")
    func transportErrorRedactsURL() async throws {
        // URLSession stamps the full failing URL (query string included) into
        // the URLError, so interpolating it raw would leak session_id/api_key.
        let leakyURL =
            try #require(
                URL(string: "https://api.themoviedb.org/3/movie/550/rating?session_id=SECRET-SESSION&api_key=SECRET-KEY")
            )
        let urlError = URLError(.timedOut, userInfo: [NSURLErrorFailingURLErrorKey: leakyURL])
        let sink = Sink()
        let client = makeClient(.failure(APIError.transport(urlError)), into: sink)

        await #expect(throws: APIError.self) {
            _ = try await client.sendRaw(RatingEndpoint())
        }
        #expect(sink.text.contains("SECRET-SESSION") == false, "session id never logged via error")
        #expect(sink.text.contains("SECRET-KEY") == false, "api_key never logged via error")
        #expect(sink.text.contains("transport(URLError"), "safe error label is logged")
    }

    @Test("sensitive keys nested inside the body are redacted")
    func redactsNestedBodySecrets() async throws {
        struct NestedEndpoint: Endpoint {
            let path = "/account"
            let method = HTTPMethod.post
            let body = try? JSONSerialization.data(
                withJSONObject: ["data": ["session_id": "NESTED-SECRET"], "items": [["api_key": "ARRAY-SECRET"]]]
            )
        }
        let sink = Sink()
        let client = LoggingAPIClient(wrapping: MockClient(result: .success(Data())), log: { sink.append($0) })

        _ = try await client.sendRaw(NestedEndpoint())

        #expect(sink.text.contains("NESTED-SECRET") == false, "secret nested in an object is redacted")
        #expect(sink.text.contains("ARRAY-SECRET") == false, "secret nested in an array is redacted")
        #expect(sink.text.contains("•••"))
    }

    @Test("duration formatting includes whole seconds, not just the sub-second remainder")
    func formatsDurationIncludingSeconds() {
        #expect(LoggingAPIClient.format(.milliseconds(1250)) == "⏱ 1250ms")
        #expect(LoggingAPIClient.format(.seconds(2)) == "⏱ 2000ms")
        #expect(LoggingAPIClient.format(.milliseconds(250)) == "⏱ 250ms")
    }
}
