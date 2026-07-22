//
//  ImageCacheTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import Foundation
import SharedTestSupport
import Testing
@testable import CoreUI

/// A class suite so `deinit` reliably removes the temp directory even when a
/// test throws mid-body.
@Suite("ImageCache")
final class ImageCacheTests {
    private let stub: URLProtocolStub.Handle
    private let session: URLSession
    private let directory: URL
    private let cache: ImageCache
    private let imageURL: URL

    init() throws {
        let (session, stub) = URLProtocolStub.makeSession()
        self.session = session
        self.stub = stub
        directory = URL.temporaryDirectory.appending(path: "ImageCacheTests-\(UUID().uuidString)")
        cache = ImageCache(session: session, directory: directory)
        imageURL = try #require(URL(string: "https://img.invalid/t/p/w342/poster.jpg"))
        stub.stub(data: Data("image-bytes".utf8))
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test("a miss fetches from the network and returns the bytes")
    func networkFetch() async throws {
        let data = try await cache.data(for: imageURL)

        #expect(data == Data("image-bytes".utf8))
        #expect(stub.requestCount == 1)
    }

    @Test("a second request hits memory — even with the disk layer gone")
    func memoryHit() async throws {
        _ = try await cache.data(for: imageURL)
        // Remove the disk layer so only memory can serve the second call.
        try FileManager.default.removeItem(at: directory)

        let data = try await cache.data(for: imageURL)

        #expect(data == Data("image-bytes".utf8))
        #expect(stub.requestCount == 1)
    }

    @Test("a fresh instance over the same directory hits disk — no network")
    func diskHit() async throws {
        _ = try await cache.data(for: imageURL)

        let freshCache = ImageCache(session: session, directory: directory)
        let data = try await freshCache.data(for: imageURL)

        #expect(data == Data("image-bytes".utf8))
        #expect(stub.requestCount == 1)
    }

    @Test("concurrent requests for one URL coalesce into a single fetch")
    func coalescing() async throws {
        // Local bindings: `async let` may not capture the non-Sendable suite.
        let (cache, imageURL) = (cache, imageURL)
        async let first = cache.data(for: imageURL)
        async let second = cache.data(for: imageURL)

        let (firstData, secondData) = try await (first, second)

        #expect(firstData == secondData)
        #expect(stub.requestCount == 1)
    }

    @Test("an HTTP failure throws, caches nothing, and the next request retries")
    func failureNotCached() async throws {
        stub.stub(statusCode: 404)

        await #expect(throws: URLError.self) {
            _ = try await self.cache.data(for: self.imageURL)
        }

        stub.stub(data: Data("image-bytes".utf8))
        let data = try await cache.data(for: imageURL)
        #expect(data == Data("image-bytes".utf8))
        #expect(stub.requestCount == 2)
    }

    @Test("clearMemory forces the next request to fall back to disk, not network")
    func clearMemoryFallsBackToDisk() async throws {
        _ = try await cache.data(for: imageURL)

        await cache.clearMemory()
        let data = try await cache.data(for: imageURL)

        #expect(data == Data("image-bytes".utf8))
        #expect(stub.requestCount == 1)
    }

    @Test("clearing both layers forces a refetch; clearing a clean cache is fine")
    func fullClearRefetches() async throws {
        // Clearing before anything exists must not throw.
        try await cache.clearDisk()

        _ = try await cache.data(for: imageURL)
        await cache.clearMemory()
        try await cache.clearDisk()
        _ = try await cache.data(for: imageURL)

        #expect(stub.requestCount == 2)
    }
}
