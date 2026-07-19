//
//  RecentSearchesView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 19/07/2026.
//

import CoreUI
import SwiftUI

/// The idle-state content: a list of recent queries (tap to re-run,
/// swipe to remove, Clear All), or a friendly prompt when there are none.
struct RecentSearchesView: View {
    let recents: [String]
    let onSelect: (String) -> Void
    let onDelete: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        if recents.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("Search Movies", comment: "Empty search prompt title")
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
            } description: {
                Text("Find movies by title.", comment: "Empty search prompt description")
            }
        } else {
            list
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(recents, id: \.self) { query in
                    Button {
                        onSelect(query)
                    } label: {
                        Label {
                            Text(query)
                                .foregroundStyle(AppColors.textPrimary)
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .accessibilityIdentifier("search.recent.\(query)")
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(query)
                        } label: {
                            Label {
                                Text("Delete", comment: "Delete a recent search")
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Recent", comment: "Recent searches section header")
                    Spacer()
                    Button(action: onClear) {
                        Text("Clear All", comment: "Clear all recent searches")
                            .font(AppTypography.caption)
                    }
                    .accessibilityIdentifier("search.recent.clearAll")
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    RecentSearchesView(
        recents: ["dune", "blade runner", "arrival"],
        onSelect: { _ in },
        onDelete: { _ in },
        onClear: {}
    )
}
