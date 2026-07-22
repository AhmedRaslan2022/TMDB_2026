//
//  ImageCache.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import CryptoKit
import Foundation

/// Actor-based image cache: memory (NSCache, cost-limited) → disk (Caches
/// directory) → network (URLSession), with in-flight coalescing so N views
/// asking for the same URL produce one request.
///
/// Failures are never cached; the next request retries. Stored data is raw
/// image bytes — decoding happens at the view layer per platform.
public actor ImageCache {
    private let session: URLSession
    private let directory: URL
    private let memory = NSCache<NSURL, NSData>()
    private var inFlight: [URL: Task<Data, Error>] = [:]

    /// - Parameters:
    ///   - session: Injectable for stubbed tests.
    ///   - directory: Disk location; defaults to `Caches/ImageCache`. Tests
    ///     pass a temporary directory.
    ///   - memoryLimitBytes: NSCache cost ceiling (default 64 MB).
    public init(
        session: URLSession = .shared,
        directory: URL? = nil,
        memoryLimitBytes: Int = 64 * 1024 * 1024
    ) {
        self.session = session
        self.directory = directory ?? URL.cachesDirectory.appending(path: "ImageCache")
        memory.totalCostLimit = memoryLimitBytes
    }

    /// Image bytes for `url`, from the fastest available layer.
    public func data(for url: URL) async throws -> Data {
        if let cached = memory.object(forKey: url as NSURL) {
            return cached as Data
        }
        if let inFlightTask = inFlight[url] {
            return try await inFlightTask.value
        }

        // Detached: disk IO + network shouldn't hop through this actor, and
        // a view's cancelled await must not kill the shared load — the bytes
        // still cache for the next appearance.
        let load = Task.detached(priority: .utility) { [session, directory] in
            let file = directory.appending(path: Self.fileName(for: url))
            if let data = try? Data(contentsOf: file) {
                return data
            }
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            // Best-effort disk write: a full disk degrades to memory-only.
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? data.write(to: file)
            return data
        }
        inFlight[url] = load
        defer { inFlight[url] = nil }

        let data = try await load.value
        memory.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        return data
    }

    /// Drops the in-memory layer (e.g. on memory pressure).
    public func clearMemory() {
        memory.removeAllObjects()
    }

    /// Deletes the on-disk layer. Already-clean is not an error.
    /// (No size cap: the directory lives in `Caches/`, which the system
    /// purges under pressure. Future: LRU sweep if it ever matters.)
    public func clearDisk() throws {
        do {
            try FileManager.default.removeItem(at: directory)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            // Nothing on disk yet — already clean.
        }
    }

    /// Content-addressed filename: SHA-256 of the absolute URL.
    private static func fileName(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
