//
//  FirestoreService.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService() // singleton for convenience
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Test method
    func addTestMessage() {
        db.collection("test").addDocument(data: [
            "message": "Hello Firebase!",
            "timestamp": Date()
        ]) { error in
            if let error = error {
                print("❌ Error writing test message: \(error)")
            } else {
                print("✅ Test message successfully written!")
            }
        }
    }
}
