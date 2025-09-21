//
//  SoundViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation

@MainActor
final class SoundsViewModel: ObservableObject {
    @Published var sounds: [Sound] = []
    private let service = FirestoreService.shared
    private let collection = "sounds"

    func loadSounds() async {
        do {
            sounds = try await service.fetchAll(from: collection)
        } catch {
            print("Error loading sounds: \(error)")
        }
    }
}
