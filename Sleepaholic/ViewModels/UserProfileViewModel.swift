//
//  UserProfileViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import SwiftUI
import Foundation
import FirebaseAuth

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    private let service = FirestoreService.shared
    private let collection = "users"
    
    // MARK: - Local Cache (for unsigned users)
    @AppStorage("cachedName") private var cachedName = ""
    @AppStorage("cachedAge") private var cachedAge = 0
    @AppStorage("cachedGender") private var cachedGender = ""
    @AppStorage("hasCachedProfile") private var hasCachedProfile = false

    func loadProfile() async {
        if let uid = Auth.auth().currentUser?.uid {
            do {
                let fetched = try await service.fetch(from: collection, id: uid) as UserProfile?
                
                if let existing = fetched {
                    profile = existing
                } else if hasCachedProfile {
                    let newProfile = UserProfile(
                        name: cachedName,
                        age: cachedAge,
                        gender: cachedGender,
                        createdAt: Date()
                    )
                    
                    await saveProfile(newProfile)
                    profile = newProfile
                    
                    cachedName = ""
                    cachedAge = 0
                    cachedGender = ""
                    hasCachedProfile = false
                }
            } catch {
                print("Error loading profile: \(error)")
            }
            
            return
        }
        
        if hasCachedProfile {
            profile = UserProfile(
                name: cachedName,
                age: cachedAge,
                gender: cachedGender,
                createdAt: Date()
            )
        }
    }

    func saveProfile(_ profile: UserProfile) async {
        if let uid = Auth.auth().currentUser?.uid {
            do {
                try await service.save(profile, to: collection, id: uid)
                self.profile = profile
            } catch {
                print("Error saving profile: \(error)")
            }
        } else {
            // MARK: - No signed-in user → cache locally
            if !profile.name.isEmpty {
                cachedName = profile.name
            }
            if profile.age != 0 {
                cachedAge = profile.age
            }
            if !profile.gender.isEmpty {
                cachedGender = profile.gender
            }
            hasCachedProfile = true
            self.profile = profile
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

