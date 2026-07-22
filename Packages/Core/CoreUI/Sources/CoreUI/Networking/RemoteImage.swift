//
//  RemoteImage.swift
//  TMDB
//
//  Created by Ahmed Raslan on 18/07/2026.
//

import SwiftUI

/// Stable process-wide default. The `@Entry` default expression is
/// re-evaluated on every read of an unset key, so the shared identity MUST
/// live in this global — `@Entry var x = ImageCache()` would silently hand
/// each view its own cache, killing the memory layer and coalescing.
private let defaultImageCache = ImageCache()

public extension EnvironmentValues {
    /// The image cache views load through. A stable process-wide default is
    /// provided so screens work unconfigured; the composition root (or a
    /// test) can override it via `.environment(\.imageCache, …)`.
    @Entry var imageCache = defaultImageCache
}

/// `AsyncImage` twin backed by the actor `ImageCache` (memory → disk →
/// network, coalesced). Same closure shape as `AsyncImage`, so swapping it
/// in is layout-neutral.
public struct RemoteImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @Environment(\.imageCache) private var cache
    @State private var loadedImage: Image?
    @State private var loadedURL: URL?

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        ZStack {
            if let loadedImage {
                content(loadedImage)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            // Reset only on an actual URL change (cell reuse); a re-fired
            // task for the same URL keeps the image — no placeholder flash.
            if loadedURL != url {
                loadedImage = nil
                loadedURL = nil
            }
            guard loadedImage == nil, let url else { return }
            guard let data = try? await cache.data(for: url) else { return }
            // The shared cache load survives awaiter cancellation by design,
            // so a task cancelled by a URL change (cell reuse) still resumes
            // here — and must not write the OLD url's image over the new one.
            guard !Task.isCancelled else { return }
            loadedImage = Self.decode(data)
            loadedURL = url
        }
    }

    private static func decode(_ data: Data) -> Image? {
        #if canImport(UIKit)
            UIImage(data: data).map(Image.init(uiImage:))
        #elseif canImport(AppKit)
            NSImage(data: data).map(Image.init(nsImage:))
        #endif
    }
}
