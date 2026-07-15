import Foundation

/// Intercepts every request on a stubbed `URLSession` and replies with the
/// configured result. No test ever touches the real network.
final class URLProtocolStub: URLProtocol {
    struct Stub {
        let statusCode: Int
        let data: Data
        let error: URLError?
    }

    /// Isolated mutable state — tests run in parallel.
    private static let state = State()

    final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var stub: Stub?
        private var lastRequest: URLRequest?

        func set(_ stub: Stub?) {
            lock.lock(); defer { lock.unlock() }
            self.stub = stub
        }

        func current() -> Stub? {
            lock.lock(); defer { lock.unlock() }
            return stub
        }

        func recordRequest(_ request: URLRequest) {
            lock.lock(); defer { lock.unlock() }
            lastRequest = request
        }

        func recordedRequest() -> URLRequest? {
            lock.lock(); defer { lock.unlock() }
            return lastRequest
        }
    }

    static func stub(statusCode: Int = 200, data: Data = Data(), error: URLError? = nil) {
        state.set(Stub(statusCode: statusCode, data: data, error: error))
    }

    static func reset() {
        state.set(nil)
    }

    static var lastRequest: URLRequest? {
        state.recordedRequest()
    }

    /// A session whose requests are all served by this stub.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.state.recordRequest(request)
        guard let stub = Self.state.current() else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        guard let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: stub.statusCode,
            httpVersion: nil,
            headerFields: nil
        ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
