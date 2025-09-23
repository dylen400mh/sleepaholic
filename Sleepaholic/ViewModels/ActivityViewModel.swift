//
//  ActivityViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation
import FirebaseAuth

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    private let service = FirestoreService.shared
    
    private func path(for userId: String) -> String {
            return "users/\(userId)/activities"
        }

    func loadActivities() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            var fetched = try await service.fetchAll(from: path(for: uid)) as [Activity]
            fetched.sort { $0.loggedAt > $1.loggedAt }
            activities = fetched
        } catch {
            print("Error loading activities: \(error)")
        }
    }

    func addActivity(_ activity: Activity) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await service.save(activity, to: path(for: uid))
            await loadActivities()
        } catch {
            print("Error saving activity: \(error)")
        }
    }

    func deleteActivity(_ activity: Activity) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await service.delete(from: path(for: uid), id: activity.id)
            await loadActivities()
        } catch {
            print("Error deleting activity: \(error)")
        }
    }
}
