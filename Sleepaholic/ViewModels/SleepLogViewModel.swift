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

struct UnifiedSleepSession {
    let healthSegments: [SleepSegment]?
    let manualLog: SleepLog?
    let clips: [SleepClip]
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
    
    // Apple Health sleep segments cache (per day)
    @Published var healthSegmentsByDate: [Date: [SleepSegment]] = [:]
    
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
        
        let log = SleepLog(start: Date(), end: nil)
        activeLog = log
        bedtimeActive = true
        
        do {
            let ref = try await service.save(log, to: path(for: uid))
            UserDefaults.standard.set(ref.path, forKey: "activeSleepPath")
            
            let data = try JSONEncoder().encode(log)
            UserDefaults.standard.set(data, forKey: activeKey)
            UserDefaults.standard.synchronize()
            
            await WindDownManager.shared.startMonitoringSleep(logPath: ref.path)
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
            sleepLogs.compactMap { log in
                log.end.map { calendar.startOfDay(for: $0) }
            }

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
            
            guard let end = latest.end else { return nil }
            
            let endStr = timeFormatter.string(from: end)

            // Duration
            let duration = end.timeIntervalSince(latest.start)
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

            let durationStr = minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
            let dateStr = dateFormatter.string(from: end)
            
            return FormattedSleep(start: startStr, end: endStr, duration: durationStr, date: dateStr)
        } else {
            return nil
        }
    }
    
    func ageBasedTargetHours(for age: Int?) -> Double {
        guard let age = age else {
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
        
        // Filter logs within the last 7 days and that have an end time
        let recentLogs = logs.filter { log in
            guard let end = log.end else { return false }
            return end >= sevenDaysAgo
        }
        
        guard !recentLogs.isEmpty else { return 0 }
        
        // Total minutes slept in that period
        let totalSlept = recentLogs.reduce(0) { total, log in
            guard let end = log.end else { return total }
            return total + Int(end.timeIntervalSince(log.start) / 60)
        }
        
        let targetTotal = targetMinutes * recentLogs.count
        
        // Sleep debt = how much below your weekly target you are
        let debt = max(0, targetTotal - totalSlept)
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
    
    func cancelBedtime() async {
        guard let path = UserDefaults.standard.string(forKey: "activeSleepPath") else { return }

        do {
            try await Firestore.firestore().document(path).delete()
            print("🗑️ Cancelled sleep session, deleted log")
        } catch {
            print("❌ Failed to delete cancelled sleep log: \(error)")
        }

        stopBedtime()
    }
    
    func stopBedtime() {
        // clear local state
        activeLog = nil
        bedtimeActive = false
        UserDefaults.standard.removeObject(forKey: activeKey)
        UserDefaults.standard.removeObject(forKey: "activeSleepPath")
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
    
    func loadHealthSleep(for date: Date) async {
        // Prevent repeat fetches for the same day
        if healthSegmentsByDate[Calendar.current.startOfDay(for: date)] != nil {
            return
        }

        // Only fetch if user enabled Apple Health
        let useAppleHealth = UserDefaults.standard.bool(forKey: "useAppleHealthSleep")
        if !useAppleHealth { return }

        guard HealthKitManager.shared.isAuthorized() else {
            return
        }

        do {
            let segments = try await HealthKitManager.shared.fetchSleepSegments(for: date)
            let key = Calendar.current.startOfDay(for: date)
            await MainActor.run {
                self.healthSegmentsByDate[key] = segments
            }
        } catch {
            print("❌ Failed to load HealthKit sleep for \(date): \(error)")
        }
    }
    
    func buildUnifiedSession(for date: Date, clips: [SleepClip]) -> UnifiedSleepSession {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        let hkSegments = healthSegmentsByDate[dayStart]

        // Find matching manual log (if any)
        let manual = sleepLogs.first { log in
            if let end = log.end {
                return calendar.isDate(end, inSameDayAs: date)
            }
            return calendar.isDate(log.start, inSameDayAs: date)
        }

        return UnifiedSleepSession(
            healthSegments: hkSegments,
            manualLog: manual,
            clips: clips
        )
    }
}
