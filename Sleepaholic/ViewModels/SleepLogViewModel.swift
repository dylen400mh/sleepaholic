//
//  SleepLogViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation

@MainActor
final class SleepLogViewModel: ObservableObject {
    @Published var sleepLogs: [SleepLog] = []
    private let service = FirestoreService.shared
    private let collection = "sleepLogs"

    func loadSleepLogs() async {
        do {
            sleepLogs = try await service.fetchAll(from: collection)
        } catch {
            print("Error loading sleep logs: \(error)")
        }
    }

    func addSleepLog(_ log: SleepLog) async {
        do {
            try await service.save(log, to: collection)
            await loadSleepLogs()
        } catch {
            print("Error saving sleep log: \(error)")
        }
    }

    func deleteSleepLog(_ log: SleepLog) async {
        do {
            try await service.delete(from: collection, id: log.id)
            await loadSleepLogs()
        } catch {
            print("Error deleting sleep log: \(error)")
        }
    }
}
