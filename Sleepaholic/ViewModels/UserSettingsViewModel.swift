//
//  UserSettingsViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation

@MainActor
final class UserSettingsViewModel: ObservableObject {
    @Published var settings: UserSettings?
    private let service = FirestoreService.shared
    private let collection = "settings"

    func loadSettings(for userId: String) async {
        do {
            settings = try await service.fetch(from: collection, id: userId)
        } catch {
            print("Error loading settings: \(error)")
        }
    }

    func saveSettings(_ settings: UserSettings) async {
        do {
            try await service.save(settings, to: collection)
            self.settings = settings
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}

