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
    @Published private(set) var activeLog: SleepLog?
    private let activeKey = "activeLog"
    
    @Published private(set) var streakDays: Int
    @Published private(set) var lastSleep: String
    @Published private(set) var sleepDebt: String
    @Published private(set) var recommendation: String
    @Published private(set) var sleepQuality: Int
    
    init() {
        // restore active session if app was restarted
        if let data = UserDefaults.standard.data(forKey: activeKey),
           let decoded = try? JSONDecoder().decode(SleepLog.self, from: data) {
            activeLog = decoded
        }
        
        // load cached values (so UI has something right away)
        let defaults = UserDefaults.standard
        self.streakDays = defaults.integer(forKey: "streakDays")
        self.lastSleep = defaults.string(forKey: "lastSleep") ?? ""
        self.sleepDebt = defaults.string(forKey: "sleepDebt") ?? ""
        self.recommendation = defaults.string(forKey: "recommendation") ?? ""
        self.sleepQuality = defaults.integer(forKey: "sleepQuality")
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
            
            recalcStats()
        } catch {
            print("Error loading sleep logs: \(error)")
        }
    }

    func startBedtime() async {
        guard activeLog == nil else { return }
        let log = SleepLog(start: Date(), end: Date()) // dummy end for now
        activeLog = log
        if let data = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(data, forKey: activeKey)
        }
    }

    func logWakeup(at wakeTime: Date) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard var log = activeLog else { return }
        
        log.end = wakeTime
        do {
            try await service.save(log, to: path(for: uid))
        } catch {
            print("Error logging wakeup: \(error)")
        }

        // clear local state
        activeLog = nil
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
    
    func getLastSleep() -> String {
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

            // Example: "11:00 PM → 7:15 AM (8h 15m) • Oct 2, 2025"
            if minutes > 0 {
                lastSleep = "\(startStr) → \(endStr) (\(hours)h \(minutes)m) • \(dateFormatter.string(from: latest.end))"
            } else {
                lastSleep = "\(startStr) → \(endStr) (\(hours)h) • \(dateFormatter.string(from: latest.end))"
            }
        } else {
            lastSleep = ""
        }
        return lastSleep
    }
    
    func recalcStats() {
        let defaults = UserDefaults.standard

        // 🔥 streak
        streakDays = calculateStreak()
        defaults.set(streakDays, forKey: "streakDays")

        // 🕒 last sleep
        lastSleep = getLastSleep()
        defaults.set(lastSleep, forKey: "lastSleep")
        

        // 😴 sleep debt (placeholder for now)
        sleepDebt = "6h 30m"
        defaults.set(sleepDebt, forKey: "sleepDebt")

        // 📈 sleep quality (placeholder for now)
        sleepQuality = 82
        defaults.set(sleepQuality, forKey: "sleepQuality")

        // 💡 recommendation (placeholder for now)
        recommendation = "Try going to bed 30 minutes earlier tonight."
        defaults.set(recommendation, forKey: "recommendation")
    }
}
