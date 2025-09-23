//
//  UserSettingsViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation
import FirebaseAuth

@MainActor
final class UserSettingsViewModel: ObservableObject {
    @Published var settings: UserSettings?
    private let service = FirestoreService.shared
    
    private func path(for userId: String) -> String {
        return "users/\(userId)/settings"
    }
    
    private let docId = "settings"

    func loadSettings() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            settings = try await service.fetch(from: path(for: uid), id: docId)
        } catch {
            print("Error loading settings: \(error)")
        }
    }

    func saveSettings(_ settings: UserSettings) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await service.save(settings, to: path(for: uid), id: docId)
            self.settings = settings
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}

