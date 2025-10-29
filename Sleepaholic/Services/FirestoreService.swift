//
//  FirestoreService.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Create / Update
    func save<T: Codable & Identifiable>(_ item: T,
                                         to collection: String) async throws -> DocumentReference {
        if let id = (item.id as? String), !id.isEmpty {
            let ref = db.collection(collection).document(id)
            try ref.setData(from: item, merge: true)
            return ref
        } else {
            // No ID -> create new doc with Firestore-generated ID
            let ref = try db.collection(collection).addDocument(from: item)
            return ref
        }
    }
    
    // MARK: - Save with explicit ID
    func save<T: Codable>(_ item: T,
                          to collection: String,
                          id: String) async throws {
        try db.collection(collection).document(id).setData(from: item, merge: true)
    }

    // MARK: - Read All
    func fetchAll<T: Codable>(from collection: String) async throws -> [T] {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    // MARK: - Read One
    func fetch<T: Codable>(from collection: String, id: String) async throws -> T? {
        let docRef = db.collection(collection).document(id)
        let snapshot = try await docRef.getDocument()
        
        // Handle missing document
        guard snapshot.exists else {
            print("⚠️ Firestore doc \(collection)/\(id) does not exist.")
            return nil
        }
        
        // Handle empty or null data
        guard let data = snapshot.data(), !data.isEmpty else {
            print("⚠️ Firestore doc \(collection)/\(id) exists but is empty.")
            return nil
        }
        
        // Safe decoding
        do {
            return try snapshot.data(as: T.self)
        } catch {
            print("❌ Failed to decode Firestore doc \(collection)/\(id): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Delete
    func delete(from collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}
