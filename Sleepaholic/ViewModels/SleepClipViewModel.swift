//
//  SleepClipViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-27.
//

import Foundation
import FirebaseAuth
import FirebaseStorage

@MainActor
final class SleepClipViewModel: ObservableObject {
    @Published var clips: [SleepClip] = []
    private let service = FirestoreService.shared
    private let collection = "clips"
    
    private func path(for userId: String, logId: String) -> String {
        "users/\(userId)/sleepLogs/\(logId)/\(collection)"
    }
    
    func loadClips(for logId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            clips = try await service.fetchAll(from: path(for: uid, logId: logId)) as [SleepClip]
        } catch {
            print("Error loading clips: \(error)")
        }
    }
    
    func addClip(for logId: String, storagePath: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let clip = SleepClip(storagePath: storagePath)
        do {
            try await service.save(clip, to: path(for: uid, logId: logId))
            await loadClips(for: logId)
        } catch {
            print("Error adding clip: \(error)")
        }
    }
    
    func deleteClip(for logId: String, clipId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await service.delete(from: path(for: uid, logId: logId), id: clipId)
            await loadClips(for: logId)
        } catch {
            print("Error deleting clip: \(error)")
        }
    }
    
    func uploadClip(for logId: String, fileURL: URL) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference()
            .child("users/\(uid)/sleepLogs/\(logId)/clips/\(UUID().uuidString).m4a")

        do {
            // Upload file
            let _ = try await storageRef.putFileAsync(from: fileURL, metadata: nil)
            
            // Save Firestore reference
            let path = storageRef.fullPath
            await addClip(for: logId, storagePath: path)
        } catch {
            print("❌ Failed to upload clip: \(error)")
        }
    }
}
