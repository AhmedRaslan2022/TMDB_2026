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
    /// Reports a tapped cast member's TMDB person ID; the coordinator pushes
    /// the person screen.
    let onSelectPerson: (Int) -> Void

    /// Billing beyond this rarely matters on a phone screen.
    private static let displayLimit = 15

    var body: some View {
        if !cast.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Cast", comment: "Cast section title")
                    .font(AppTypography.title)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, AppSpacing.lg)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppSpacing.md) {
                        ForEach(cast.prefix(Self.displayLimit)) { member in
                            CastCard(
                                member: member,
                                profileURL: profileURL(member),
                                onSelect: { onSelectPerson(member.personID) }
                            )
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
    let onSelect: () -> Void

    // Scale the headshot + card with Dynamic Type so names don't crush at large
    // accessibility text sizes.
    @ScaledMetric(relativeTo: .body) private var headshot: CGFloat = 80
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 100

    var body: some View {
        Button(action: onSelect) {
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
                .frame(width: headshot, height: headshot)
                .clipShape(Circle())

                Text(member.name)
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
                if let character = member.character {
                    Text(character)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: cardWidth)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("details.cast.\(member.personID)")
    }
}
