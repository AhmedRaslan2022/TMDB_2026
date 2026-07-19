//
//  CastSection.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreUI
import SwiftUI

/// Horizontal cast carousel: headshot, name, character. Hidden entirely when
/// the movie has no credited cast.
struct CastSection: View {
    let cast: [CastMember]
    let profileURL: (CastMember) -> URL?

    /// Billing beyond this rarely matters on a phone screen.
    private static let displayLimit = 15

    var body: some View {
        if !cast.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Cast", comment: "Cast section title")
                    .font(AppTypography.title)
                    .padding(.horizontal, AppSpacing.lg)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                        ForEach(cast.prefix(Self.displayLimit)) { member in
                            CastCard(member: member, profileURL: profileURL(member))
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }
}

private struct CastCard: View {
    let member: CastMember
    let profileURL: URL?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            RemoteImage(url: profileURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.15))
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.textSecondary)
                            .accessibilityHidden(true)
                    }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            Text(member.name)
                .font(AppTypography.label)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
            if let character = member.character {
                Text(character)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 100)
        .accessibilityElement(children: .combine)
    }
}
