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
            try await service.save(profile, to: collection, id: uid)
            self.profile = profile
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    // MARK: - Delete Account
    func deleteProfile() async {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        do {
            // 1️⃣ Delete Firestore user doc (triggers Cloud Function)
            try await service.delete(from: collection, id: uid)
            print("🗑️ Firestore user document deleted — Cloud Function triggered")

            // 2️⃣ Delete Firebase Auth account
            try await user.delete()
            print("✅ Firebase Auth user deleted")

            // 3️⃣ Sign out locally
            AuthService.shared.signOut()

        } catch let error as NSError {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                print("⚠️ Requires recent login. Prompt user to reauthenticate.")
            } else {
                print("❌ Error deleting account: \(error.localizedDescription)")
            }
        }
    }
}

