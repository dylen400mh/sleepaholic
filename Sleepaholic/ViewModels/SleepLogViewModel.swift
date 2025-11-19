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
    
    @AppStorage("bedtimeActive") private var bedtimeActive: Bool = false
    @AppStorage("useAppleHealthSleep") private var useAppleHealthSleep = false
    
    @Published var fetchedHealthSegments: [SleepSegment] = []

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
                   profile: UserProfile?) async {
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
            
            HealthKitManager.shared.writeSleep(
                start: log.start,
                end: wakeTime
            )

            await loadSleepLogs()
            await recalcStats(userAge: profile?.age)
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
    
    func getLastSleep() async -> FormattedSleep? {
        let calendar = Calendar.current

        // Determine the most recent day with either HealthKit or manual data
        let today = calendar.startOfDay(for: Date())

        await loadHealthSleep(for: today)

        // Prefer HealthKit if available
        let healthSegments = fetchedHealthSegments // health segments for today
        if !healthSegments.isEmpty {
            guard let first = healthSegments.first,
                  let last = healthSegments.last else {
                return nil
            }

            let hasRealSleep = healthSegments.contains { $0.stage.isAsleep }
            if hasRealSleep {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                let startStr = timeFormatter.string(from: first.start)
                let endStr   = timeFormatter.string(from: last.end)
                
                let duration = last.end.timeIntervalSince(first.start)
                let h = Int(duration / 3600)
                let m = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                let durationStr = m > 0 ? "\(h)h \(m)m" : "\(h)h"
                
                let dateStr = dateFormatter.string(from: last.end)
                
                return FormattedSleep(
                    start: startStr,
                    end: endStr,
                    duration: durationStr,
                    date: dateStr
                )
            }
        }
        
        // manual sleep log if no health data
        if let latest = sleepLogs.first, let end = latest.end {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium // e.g., Oct 2, 2025

            // Format times
            let startStr = timeFormatter.string(from: latest.start)
            let endStr = timeFormatter.string(from: end)

            // Duration
            let duration = end.timeIntervalSince(latest.start)
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

            let durationStr = minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
            let dateStr = dateFormatter.string(from: end)
            
            return FormattedSleep(start: startStr, end: endStr, duration: durationStr, date: dateStr)
        }
        
        return nil
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
    
    private func calculateSleepDebt(for logs: [SleepLog], age: Int?) async -> Int {
        let calendar = Calendar.current
        let targetMinutes = Int(ageBasedTargetHours(for: age) * 60)
        
        // look at today + previous 6 days
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
        
        var totalSleptMinutes = 0
        var daysCounted = 0
        
        for day in days {
            await loadHealthSleep(for: day)
            // Prefer HealthKit if available for that day
            let segments = fetchedHealthSegments
            if let first = segments.first,
               let last = segments.last {
                let hasRealSleep = segments.contains { $0.stage.isAsleep }
                  
                if hasRealSleep {
                    let duration = last.end.timeIntervalSince(first.start)
                    let hkDuration = Int(duration / 60)
                       totalSleptMinutes += hkDuration
                       daysCounted += 1
                       continue
                }
           }

            // Else fallback to manual Sleepaholic log
            if let log = logs.first(where: { log in
                guard let end = log.end else { return false }
                return calendar.isDate(end, inSameDayAs: day)
            }) {
                if let end = log.end {
                    let minutes = Int(end.timeIntervalSince(log.start) / 60)
                    totalSleptMinutes += minutes
                    daysCounted += 1
                    continue
                }
            }

            // no data for this day → skip
        }

        guard daysCounted > 0 else { return 0 }

        let targetTotal = targetMinutes * daysCounted
        let debt = max(0, targetTotal - totalSleptMinutes)
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
    
    func recalcStats(userAge: Int?) async -> Void {
        // 🔥 streak
        streakDays = calculateStreak()

        // 🕒 last sleep
        lastSleep = await getLastSleep()

        // 😴 sleep debt
        let debtMinutes = await calculateSleepDebt(for: sleepLogs, age: userAge)
        sleepDebt = formatMinutes(debtMinutes)
        
        // Recommendations
        if let latest = sleepLogs.first {
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
                        await self.recalcStats(userAge: userAge)
                    }
                } catch {
                    print("❌ Decoding error: \(error)")
                }
            }
    }
    
    // MARK: HealthKit
    
    func loadHealthSleep(for date: Date) async {
        // Only fetch if user enabled Apple Health
        guard useAppleHealthSleep else {
            await MainActor.run { fetchedHealthSegments = [] }
            return
        }

        guard HealthKitManager.shared.isAuthorized() else {
            await MainActor.run { fetchedHealthSegments = [] }
            return
        }

        do {
            let segments = try await HealthKitManager.shared.fetchSleepSegments(for: date)
            
            // cluster into distinct sleep sessions
            let sessions = clusterSessions(segments)

            // find the session whose END matches this day
            let calendar = Calendar.current
            guard let matched = sessions.first(where: { session in
                if let last = session.last {
                    return calendar.isDate(last.end, inSameDayAs: date)
                }
                return false
            }) else {
                await MainActor.run { self.fetchedHealthSegments = [] }
                return
            }

            await MainActor.run {
                self.fetchedHealthSegments = matched.sorted { $0.start < $1.start }
            }
        } catch {
            print("❌ Failed to load HealthKit sleep for \(date): \(error)")
        }
    }
    
    /// Groups incoming HK segments into separate sleep sessions.
    /// Any gap > 90 minutes indicates a new session.
    func clusterSessions(_ segments: [SleepSegment]) -> [[SleepSegment]] {
        guard !segments.isEmpty else { return [] }

        var sessions: [[SleepSegment]] = []
        var current: [SleepSegment] = [segments[0]]

        for i in 1..<segments.count {
            let prev = segments[i-1]
            let next = segments[i]

            let gap = next.start.timeIntervalSince(prev.end)

            if gap > 90 * 60 {
                // New session
                sessions.append(current)
                current = [next]
            } else {
                // Same session
                current.append(next)
            }
        }

        sessions.append(current)
        return sessions
    }
    
    // MARK: Stats & Helpers
    
    func computeSleepScore(from segments: [SleepSegment]) -> Int {
        // total awake time
        let awake = segments
            .filter { $0.stage == .awake }
            .reduce(0) { $0 + $1.duration }

        // total asleep time
        let asleep = segments
            .filter { $0.stage.isAsleep }
            .reduce(0) { $0 + $1.duration }

        let timeInBed = asleep + awake
        guard timeInBed > 0 else { return 0 }
        
        let ratio = asleep / timeInBed
        let clamped = min(max(ratio, 0), 1)

        return Int(clamped * 100)
    }
    
    func computeTimeAsleep(from segments: [SleepSegment]) -> TimeInterval {
        let realSleep = segments.filter { $0.stage.isAsleep }
        return realSleep.reduce(0) { $0 + $1.duration }
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}
