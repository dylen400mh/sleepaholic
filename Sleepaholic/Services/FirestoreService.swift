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
                                         to collection: String) async throws {
        let id = String(describing: item.id) // ensure String id
        try db.collection(collection).document(id).setData(from: item, merge: true)
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
        let snapshot = try await db.collection(collection).document(id).getDocument()
        return try snapshot.data(as: T.self)
    }

    // MARK: - Delete
    func delete(from collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}
