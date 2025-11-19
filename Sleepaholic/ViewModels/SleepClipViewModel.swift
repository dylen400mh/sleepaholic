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
    func loadClips(for logId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let storage = Storage.storage().reference()
        let folderRef = storage.child("users/\(uid)/sleepLogs/\(logId)/clips")

        do {
            let result = try await folderRef.listAll()

            let items = result.items.map { itemRef in
                SleepClip(id: itemRef.name, storagePath: itemRef.fullPath)
            }

            self.clips = items
        } catch {
            print("❌ Failed to list clips: \(error)")
            self.clips = []
        }
    }
}
