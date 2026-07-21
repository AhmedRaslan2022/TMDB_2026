//
//  AppIconTests.swift
//  TMDB
//
//  Created by Ahmed Raslan on 21/07/2026.
//

import CoreModels
import CoreUI
import SwiftData
import SwiftDataStorage
import Testing
import UserDefaultsStorage
@testable import TMDB

/// In-memory `DefaultsStorage` — no real `UserDefaults`.
private final class InMemoryDefaults: DefaultsStorage, @unchecked Sendable {
    private var bools: [DefaultsKey: Bool] = [:]
    private var strings: [DefaultsKey: String] = [:]

    func set(_ value: Bool, for key: DefaultsKey) {
        bools[key] = value
    }

    func bool(for key: DefaultsKey) -> Bool {
        bools[key] ?? false
    }

    func set(_ value: String, for key: DefaultsKey) {
        strings[key] = value
    }

    func string(for key: DefaultsKey) -> String? {
        strings[key]
    }

    func removeValue(for key: DefaultsKey) {
        bools[key] = nil; strings[key] = nil
    }

    func removeAll() {
        bools.removeAll(); strings.removeAll()
    }
}

@MainActor
struct AppIconTests {
    @Test("each icon maps to its catalog alternate-icon name (nil for default)")
    func alternateNames() {
        #expect(AppIconController.alternateName(for: .default) == nil)
        #expect(AppIconController.alternateName(for: .midnight) == "AppIcon-Midnight")
        #expect(AppIconController.alternateName(for: .sunset) == "AppIcon-Sunset")
    }

    /// Records what `AppSettings` asks the controller to apply.
    private final class IconControllerSpy: AppIconControlling {
        private(set) var applied: [AppIcon] = []
        func apply(_ icon: AppIcon) {
            applied.append(icon)
        }
    }

    @Test("setting the app icon persists it and applies it through the controller")
    func settingIconAppliesAndPersists() throws {
        let spy = IconControllerSpy()
        let defaults = InMemoryDefaults()
        let settings = try AppSettings(
            defaults: defaults,
            imageCache: .init(),
            modelContainer: ModelContainerFactory.make(inMemory: true),
            iconController: spy
        )

        settings.appIcon = .sunset

        #expect(spy.applied == [.sunset])
        #expect(defaults.string(for: .appIcon) == "sunset")
    }

    @Test("a persisted icon is restored on launch")
    func restoresPersistedIcon() throws {
        let defaults = InMemoryDefaults()
        defaults.set("midnight", for: .appIcon)

        let settings = try AppSettings(
            defaults: defaults,
            imageCache: .init(),
            modelContainer: ModelContainerFactory.make(inMemory: true),
            iconController: IconControllerSpy()
        )

        #expect(settings.appIcon == .midnight)
    }
}
