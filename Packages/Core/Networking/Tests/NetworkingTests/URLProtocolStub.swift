import Foundation

/// Serves stubbed responses for a single `URLSession`. Each call to
/// `makeSession()` returns an isolated handle, so parallel tests never share
/// state. No test ever touches the real network.
final class URLProtocolStub: URLProtocol {
    struct Stub {
        var statusCode = 200
        var data = Data()
        var error: URLError?
    }

    /// Per-session stub configuration and request recording.
    final class Handle: @unchecked Sendable {
        private let lock = NSLock()
        private var _stub = Stub()
        private var _lastRequest: URLRequest?

        func stub(statusCode: Int = 200, data: Data = Data(), error: URLError? = nil) {
            lock.lock(); defer { lock.unlock() }
            _stub = Stub(statusCode: statusCode, data: data, error: error)
        }

        var lastRequest: URLRequest? {
            lock.lock(); defer { lock.unlock() }
            return _lastRequest
        }

        fileprivate var current: Stub {
            lock.lock(); defer { lock.unlock() }
            return _stub
        }

        fileprivate func record(_ request: URLRequest) {
            lock.lock(); defer { lock.unlock() }
            _lastRequest = request
        }
    }

    private final class Registry: @unchecked Sendable {
        private let lock = NSLock()
        private var handles = [String: Handle]()

        func register(_ handle: Handle, id: String) {
            lock.lock(); defer { lock.unlock() }
            handles[id] = handle
        }

        func handle(for id: String) -> Handle? {
            lock.lock(); defer { lock.unlock() }
            return handles[id]
        }
    }

    private static let registry = Registry()
    private static let headerField = "X-URLProtocolStub-ID"

    /// A session whose requests are all served by the returned handle.
    static func makeSession() -> (session: URLSession, stub: Handle) {
        let id = UUID().uuidString
        let handle = Handle()
        registry.register(handle, id: id)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        configuration.httpAdditionalHeaders = [headerField: id]
        return (URLSession(configuration: configuration), handle)
    }

    private static func handle(for request: URLRequest) -> Handle? {
        guard let id = request.value(forHTTPHeaderField: headerField) else { return nil }
        return registry.handle(for: id)
    }

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handle = Self.handle(for: request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        handle.record(request)
        let stub = handle.current

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
