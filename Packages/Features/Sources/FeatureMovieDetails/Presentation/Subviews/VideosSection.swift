//
//  VideosSection.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreUI
import SwiftUI

/// Horizontal trailer cards. Tapping opens the hosting site (YouTube/Vimeo)
/// externally via `Link` — external URLs aren't coordinator navigation.
struct VideosSection: View {
    let videos: [MovieVideo]
    let watchURL: (MovieVideo) -> URL?
    let thumbnailURL: (MovieVideo) -> URL?

    var body: some View {
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Trailers", bundle: .module, comment: "Trailers section title")
                    .font(AppTypography.title)
                    .padding(.horizontal, AppSpacing.lg)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                        ForEach(videos) { video in
                            if let url = watchURL(video) {
                                Link(destination: url) {
                                    VideoCard(video: video, thumbnailURL: thumbnailURL(video))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }
}

private struct VideoCard: View {
    let video: MovieVideo
    let thumbnailURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            RemoteImage(url: thumbnailURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(AppColors.brandPrimary.opacity(0.2))
            }
            .frame(width: 200, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityHidden(true)
            }

            Text(video.name)
                .font(AppTypography.label)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(width: 200)
        .accessibilityElement(children: .combine)
    }
}
