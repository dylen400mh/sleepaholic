//
//  UserProfileViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation
import FirebaseAuth

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    private let service = FirestoreService.shared
    private let collection = "users"

    func loadProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            profile = try await service.fetch(from: collection, id: uid)
        } catch {
            print("Error loading profile: \(error)")
        }
    }

    func saveProfile(_ profile: UserProfile) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await service.save(profile, to: "\(collection)/\(uid)")
            self.profile = profile
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

