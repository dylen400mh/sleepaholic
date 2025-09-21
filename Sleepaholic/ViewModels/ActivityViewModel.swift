//
//  ActivityViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    private let service = FirestoreService.shared
    private let collection = "activities"

    func loadActivities() async {
        do {
            activities = try await service.fetchAll(from: collection)
        } catch {
            print("Error loading activities: \(error)")
        }
    }

    func addActivity(_ activity: Activity) async {
        do {
            try await service.save(activity, to: collection)
            await loadActivities()
        } catch {
            print("Error saving activity: \(error)")
        }
    }

    func deleteActivity(_ activity: Activity) async {
        do {
            try await service.delete(from: collection, id: activity.id)
            await loadActivities()
        } catch {
            print("Error deleting activity: \(error)")
        }
    }
}
