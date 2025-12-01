//
//  ShieldController.swift
//  Sleepaholic
//

import Foundation
import ManagedSettings
import FamilyControls

final class ShieldController {
    static let shared = ShieldController()
    private let store = ManagedSettingsStore()

    private let appGroupId = "group.sleepaholic"
    private let selectionKey = "shieldSelection"

    var latestSelection: FamilyActivitySelection = .init()

    private init() {
        // Try to restore from shared UserDefaults
        if let data = UserDefaults(suiteName: appGroupId)?.data(forKey: selectionKey),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            latestSelection = selection
            print("📦 ShieldController: restored selection from app group")
        } else {
            print("📦 ShieldController: no saved selection in app group")
        }
    }

    func applyShield() {
        let selection = latestSelection

        let apps       = selection.applicationTokens
        let categories = selection.categoryTokens
        let webDomains = selection.webDomainTokens

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains

        print("🛡️ ShieldController: applied shield")
    }

    func clearShield() {
        store.clearAllSettings()
        print("🧹 ShieldController: cleared shield")
    }
}
