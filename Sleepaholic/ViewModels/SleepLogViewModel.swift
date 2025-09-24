//
//  SleepLogViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SleepLogViewModel: ObservableObject {
    @Published var sleepLogs: [SleepLog] = []
    private let service = FirestoreService.shared
    private let collection = "sleepLogs"
    
    // Keep track of current bedtime session
    @Published private(set) var activeStart: Date?
    private let activeKey = "activeStart"
    
    init() {
        // restore active session if app was restarted
        if let t = UserDefaults.standard.object(forKey: activeKey) as? TimeInterval {
            activeStart = Date(timeIntervalSince1970: t)
        }
    }
    
    private func path(for userId: String) -> String {
        "users/\(userId)/sleepLogs"
    }

    func loadSleepLogs() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            var fetched = try await service.fetchAll(from: path(for: uid)) as [SleepLog]
            fetched.sort { $0.start > $1.start }
            sleepLogs = fetched
        } catch {
            print("Error loading sleep logs: \(error)")
        }
    }

    func startBedtime() async {
        guard activeStart == nil else { return }
        let now = Date()
        activeStart = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: activeKey)
    }

    func logWakeup(at wakeTime: Date) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let start = activeStart ?? wakeTime
        let log = SleepLog(start: start, end: wakeTime)
        do {
            try await service.save(log, to: path(for: uid))
        } catch {
            print("Error logging wakeup: \(error)")
        }

        // clear local state
        activeStart = nil
        UserDefaults.standard.removeObject(forKey: activeKey)

        await loadSleepLogs()
    }

    func deleteSleepLog(_ log: SleepLog) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await service.delete(from: path(for: uid), id: log.id)
            await loadSleepLogs()
        } catch {
            print("Error deleting sleep log: \(error)")
        }
    }
}
