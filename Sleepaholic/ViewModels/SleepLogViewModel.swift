//
//  SleepLogViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseFirestore

struct FormattedSleep {
    let start: String
    let end: String
    let duration: String
    let date: String
}

@MainActor
final class SleepLogViewModel: ObservableObject {
    @Published var sleepLogs: [SleepLog] = []
    private let service = FirestoreService.shared
    private let collection = "sleepLogs"
    private var listener: ListenerRegistration?
    
    // Keep track of current bedtime session
    @Published private(set) var activeLog: SleepLog?
    private let activeKey = "activeLog"
    
    @Published private(set) var streakDays: Int
    @Published private(set) var lastSleep: FormattedSleep?
    @Published private(set) var sleepDebt: String
    @Published private(set) var recommendations: [String]
    @Published private(set) var sleepQuality: Int
    
    @AppStorage("bedtimeActive") private var bedtimeActive: Bool = false
    
    init() {
        // restore active session if app was restarted
        if let data = UserDefaults.standard.data(forKey: activeKey) {
            if let decoded = try? JSONDecoder().decode(SleepLog.self, from: data) {
                self.activeLog = decoded
                print("✅ Restored active sleep log with start time \(decoded.start)")
            } else {
                print("⚠️ Failed to decode active log")
            }
        } else {
            print("ℹ️ No active sleep log found")
        }
        
        streakDays = 0
        lastSleep = nil
        sleepDebt = ""
        recommendations = []
        sleepQuality = 0
    }
    
    deinit {
        listener?.remove()
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
        guard activeLog == nil else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let log = SleepLog(start: Date(), end: Date())
        activeLog = log
        bedtimeActive = true
        
        do {
            let ref = try await service.save(log, to: path(for: uid))
            UserDefaults.standard.set(ref.path, forKey: "activeSleepPath")
            
            let data = try JSONEncoder().encode(log)
            UserDefaults.standard.set(data, forKey: activeKey)
            UserDefaults.standard.synchronize()
            
            WindDownManager.shared.startMonitoringSleep(logPath: ref.path)
            print("✅ Bedtime started — Firestore path: \(ref.path)")
        } catch {
            print("❌ Failed to encode active log: \(error)")
        }
    }

    func logWakeup(at wakeTime: Date,
                   profile: UserProfile?,
                   activities: [Activity],
                   audioClipsCount: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard var log = activeLog else { return }
        
        log.end = wakeTime
        
        do {
            if let path = UserDefaults.standard.string(forKey: "activeSleepPath") {
                let ref = Firestore.firestore().document(path)
                try await ref.updateData(["end": wakeTime])
                WindDownManager.shared.stopMonitoringSleep(logPath: path)
                UserDefaults.standard.removeObject(forKey: "activeSleepPath")
            } else {
                _ = try await service.save(log, to: path(for: uid))
            }

            await loadSleepLogs()
            recalcStats(userAge: profile?.age)
            stopBedtime()
        } catch {
            print("Error logging wakeup: \(error)")
        }
    }

    func deleteSleepLog(_ log: SleepLog) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let id = log.id else { return }
        do {
            try await service.delete(from: path(for: uid), id: id)
            await loadSleepLogs()
        } catch {
            print("Error deleting sleep log: \(error)")
        }
    }
    
    func calculateStreak() -> Int {
        // use calendar to compare days
        let calendar = Calendar.current
        
        let daysWithLogs: Set<Date> = Set(
            sleepLogs.map { calendar.startOfDay(for: $0.end) }
        )
        guard !daysWithLogs.isEmpty else { return 0 }
        
        let todayStart = calendar.startOfDay(for: Date())
        
        // Anchor to today if logged, else to yesterday if logged, else 0
        let anchor: Date? = {
            if daysWithLogs.contains(todayStart) {
                return todayStart
            }
            let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart)!
            return daysWithLogs.contains(yesterday) ? yesterday : nil
        }()

        guard var day = anchor else { return 0 }

        var streak = 0
        while daysWithLogs.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }
    
    func getLastSleep() -> FormattedSleep? {
        if let latest = sleepLogs.first {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium // e.g., Oct 2, 2025

            // Format times
            let startStr = timeFormatter.string(from: latest.start)
            let endStr = timeFormatter.string(from: latest.end)

            // Duration
            let duration = latest.end.timeIntervalSince(latest.start)
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

            let durationStr = minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
            let dateStr = dateFormatter.string(from: latest.end)
            
            return FormattedSleep(start: startStr, end: endStr, duration: durationStr, date: dateStr)
        } else {
            return nil
        }
    }
    
    func ageBasedTargetHours(for age: Int?) -> Double {
        guard let age = age, age > 0 else {
            return 8.0      // Default target hours if no age is provided
        }
        
        switch age {
        case ..<18:
            return 9.0      // Teens (8-10 hours recommended)
        case 18...64:
            return 8.0      // Adults (7-9 hours recommended)
        default:
            return 7.5      // Seniors (7-8 hours recommended)
        }
    }
    
    private func calculateSleepDebt(for logs: [SleepLog], age: Int?) -> Int {
        let targetMinutes = Int(ageBasedTargetHours(for: age) * 60)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var debt = 0

        for log in logs where log.end >= sevenDaysAgo {
            let actualMinutes = Int(log.end.timeIntervalSince(log.start) / 60)

            if actualMinutes < targetMinutes {
                // slept less → add debt
                debt += targetMinutes - actualMinutes
            } else {
                // overslept → repay
                debt -= actualMinutes - targetMinutes
            }

            // Cap at 0
            if debt < 0 {
                debt = 0
            }
        }

        return debt
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    func recalcStats(userAge: Int?) {
        // 🔥 streak
        streakDays = calculateStreak()

        // 🕒 last sleep
        lastSleep = getLastSleep()

        // 😴 sleep debt
        let debtMinutes = calculateSleepDebt(for: sleepLogs, age: userAge)
        sleepDebt = formatMinutes(debtMinutes)
        
        // Sleep Quality + Recommendations
        if let latest = sleepLogs.first {
            sleepQuality = latest.sleepQuality ?? 0
            recommendations = latest.recommendations ?? []
        }
    }
    
    func stopBedtime() {
        // clear local state
        activeLog = nil
        UserDefaults.standard.removeObject(forKey: activeKey)
    }
    
    func startListeningForSleepLogs(userAge: Int?) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove() // stop previous listener if any

        listener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("sleepLogs")
            .order(by: "start", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening for sleep logs: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No sleep logs found")
                    return
                }

                do {
                    let fetched = try documents.compactMap { doc -> SleepLog? in
                        var log = try doc.data(as: SleepLog.self)
                        log.id = doc.documentID
                        return log
                    }

                    Task { @MainActor in
                        self.sleepLogs = fetched
                        self.recalcStats(userAge: userAge)
                    }
                } catch {
                    print("❌ Decoding error: \(error)")
                }
            }
    }

}
