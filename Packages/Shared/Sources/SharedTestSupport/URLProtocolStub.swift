//
//  URLProtocolStub.swift
//  TMDB
//
//  Created by Ahmed Raslan on 17/07/2026.
//

import Foundation

/// Serves stubbed responses for a single `URLSession`. Each call to
/// `makeSession()` returns an isolated handle, so parallel tests never share
/// state. No test ever touches the real network.
///
/// Public twin of the stub in `NetworkingTests` — that copy cannot move here
/// because Shared already depends on Networking and the reverse test-target
/// edge would cycle at the package level.
public final class URLProtocolStub: URLProtocol {
    struct Stub {
        var statusCode = 200
        var data = Data()
        var error: URLError?
    }

    /// Per-session stub configuration and request recording.
    public final class Handle: @unchecked Sendable {
        private let lock = NSLock()
        private var _stub = Stub()
        private var _lastRequest: URLRequest?

        public func stub(statusCode: Int = 200, data: Data = Data(), error: URLError? = nil) {
            lock.lock(); defer { lock.unlock() }
            _stub = Stub(statusCode: statusCode, data: data, error: error)
        }

        public var lastRequest: URLRequest? {
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
    public static func makeSession() -> (session: URLSession, stub: Handle) {
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

    override public static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override public static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
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

    override public func stopLoading() {}
}
