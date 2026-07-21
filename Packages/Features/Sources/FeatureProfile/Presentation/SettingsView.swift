//
//  SettingsView.swift
//  TMDB
//
//  Created by Ahmed Raslan on 20/07/2026.
//

import CoreModels
import CoreUI
import SwiftUI

/// App settings: appearance, content language, cache management, and sign out.
/// Preferences persist through the view model's injected `SettingsStore`; theme
/// changes are applied at the app root.
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var showClearCacheConfirm = false

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            appearanceSection
            languageSection
            appIconSection
            dataSection
            accountSection
        }
        .navigationTitle(Text("Settings", bundle: .module, comment: "Settings nav title"))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var appearanceSection: some View {
        Section {
            ForEach(AppTheme.allCases) { theme in
                selectableRow(Self.themeLabel(theme), isSelected: viewModel.theme == theme) {
                    viewModel.selectTheme(theme)
                }
                .accessibilityIdentifier("settings.theme.\(theme.rawValue)")
            }
        } header: {
            Text("Appearance", bundle: .module, comment: "Settings appearance section header")
        }
    }

    private var languageSection: some View {
        Section {
            ForEach(AppLanguage.allCases) { language in
                selectableRow(Self.languageLabel(language), isSelected: viewModel.language == language) {
                    viewModel.selectLanguage(language)
                }
                .accessibilityIdentifier("settings.language.\(language.rawValue)")
            }
        } header: {
            Text("Content Language", bundle: .module, comment: "Settings language section header")
        } footer: {
            Text("Applies to titles and descriptions from TMDB.", bundle: .module, comment: "Settings language footer")
        }
    }

    private var appIconSection: some View {
        Section {
            ForEach(AppIcon.allCases) { icon in
                selectableRow(Self.iconLabel(icon), isSelected: viewModel.appIcon == icon) {
                    viewModel.selectIcon(icon)
                }
                .accessibilityIdentifier("settings.icon.\(icon.rawValue)")
            }
        } header: {
            Text("App Icon", bundle: .module, comment: "Settings app-icon section header")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                showClearCacheConfirm = true
            } label: {
                HStack {
                    Text("Clear Cache", bundle: .module, comment: "Settings clear-cache button")
                    Spacer()
                    if viewModel.isClearingCache {
                        ProgressView()
                    } else if viewModel.didClearCache {
                        Image(systemName: "checkmark")
                            .foregroundStyle(AppColors.brandTertiary)
                    }
                }
            }
            .disabled(viewModel.isClearingCache)
            .accessibilityIdentifier("settings.clearCache")
            .confirmationDialog(
                Text("Clear cached images and data?", bundle: .module, comment: "Clear-cache confirmation title"),
                isPresented: $showClearCacheConfirm,
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    Task { await viewModel.clearCache() }
                } label: {
                    Text("Clear Cache", bundle: .module, comment: "Confirm clear cache")
                }
            }
        } header: {
            Text("Storage", bundle: .module, comment: "Settings storage section header")
        }
    }

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.signOut()
            } label: {
                Text("Sign Out", bundle: .module, comment: "Settings sign-out button")
            }
            .accessibilityIdentifier("settings.signOut")
        }
    }

    /// A tappable row with a trailing checkmark when it's the active choice.
    private func selectableRow(_ title: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                title.foregroundStyle(AppColors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColors.brandSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private static func themeLabel(_ theme: AppTheme) -> Text {
        switch theme {
        case .system: Text("System", bundle: .module, comment: "Theme option: follow system")
        case .light: Text("Light", bundle: .module, comment: "Theme option: light")
        case .dark: Text("Dark", bundle: .module, comment: "Theme option: dark")
        }
    }

    private static func languageLabel(_ language: AppLanguage) -> Text {
        switch language {
        case .english: Text("English", bundle: .module, comment: "Language option: English")
        case .arabic: Text("العربية", bundle: .module, comment: "Language option: Arabic")
        }
    }

    private static func iconLabel(_ icon: AppIcon) -> Text {
        switch icon {
        case .default: Text("Default", bundle: .module, comment: "App icon option: default")
        case .midnight: Text("Midnight", bundle: .module, comment: "App icon option: midnight")
        case .sunset: Text("Sunset", bundle: .module, comment: "App icon option: sunset")
        }
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            SettingsView(viewModel: SettingsViewModel(store: PreviewSettingsStore(), onSignOut: {}))
        }
    }

    @MainActor
    private final class PreviewSettingsStore: SettingsStore {
        var theme: AppTheme = .system
        var language: AppLanguage = .english
        var appIcon: AppIcon = .default
        func clearCache() async {}
    }
#endif
