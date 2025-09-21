//
//  UserProfileViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    private let service = FirestoreService.shared
    private let collection = "users"

    func loadProfile(for userId: String) async {
        do {
            profile = try await service.fetch(from: collection, id: userId)
        } catch {
            print("Error loading profile: \(error)")
        }
    }

    func saveProfile(_ profile: UserProfile) async {
        do {
            try await service.save(profile, to: collection)
            self.profile = profile
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

