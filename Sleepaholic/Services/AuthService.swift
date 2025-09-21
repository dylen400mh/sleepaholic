//
//  AuthService.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation
import FirebaseAuth

class AuthService {
    static let shared = AuthService()

    func signInAnonymously() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("❌ Auth error: \(error.localizedDescription)")
                } else if let user = result?.user {
                    print("✅ Signed in anonymously with uid: \(user.uid)")
                }
            }
        }
    }
}
