//
//  SleepLogViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-21.
//

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
    
    // Keep track of current bedtime session
    @Published private(set) var activeLog: SleepLog?
    private let activeKey = "activeLog"
    
    @Published private(set) var streakDays: Int
    @Published private(set) var lastSleep: FormattedSleep?
    @Published private(set) var sleepDebt: String
    @Published private(set) var recommendations: [String]
    @Published private(set) var sleepQuality: Int
    
    init() {
        // restore active session if app was restarted
        if let data = UserDefaults.standard.data(forKey: activeKey),
           let decoded = try? JSONDecoder().decode(SleepLog.self, from: data) {
            activeLog = decoded
        }
        
        streakDays = 0
        lastSleep = nil
        sleepDebt = ""
        recommendations = []
        sleepQuality = 0
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
        let log = SleepLog(start: Date(), end: Date()) // dummy end for now
        activeLog = log
        if let data = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(data, forKey: activeKey)
        }
    }

    func logWakeup(at wakeTime: Date,
                   profile: UserProfile?,
                   activities: [Activity],
                   audioClipsCount: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard var log = activeLog else { return }
        
        log.end = wakeTime
        
        if let input = buildInsightInput(
            profile: profile,
            activities: activities,
            audioClipsCount: audioClipsCount,
            pendingLog: log
        ) {
            do {
                let output = try await OpenAIService.shared.generateSleepInsights(from: input)
                log.sleepQuality = output.quality
                log.recommendations = output.recommendations
            } catch {
                print("⚠️ Could not generate insights before save: \(error.localizedDescription)")
            }
        }
        
        do {
            try await service.save(log, to: path(for: uid))

            await loadSleepLogs()
            recalcStats(userAge: profile?.age)
            
            // clear local state
            activeLog = nil
            UserDefaults.standard.removeObject(forKey: activeKey)
            
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
    
    func buildInsightInput(
        profile: UserProfile?,                // from UserProfileViewModel
        activities: [Activity],               // from ActivityViewModel
        audioClipsCount: Int,                 // from SleepClipViewModel
        pendingLog: SleepLog? = nil
    ) -> SleepInsightInput? {
        var logs = sleepLogs
        if let pending = pendingLog {
            logs.insert(pending, at: 0)
        }
        
        // get most recent sleep log
        guard let latest = logs.first else { return nil }

        // derive target sleep hours from age
        let targetHours = ageBasedTargetHours(for: profile?.age)

        // compute total sleep debt hours as Double (strip “h m” formatting)
        let debtComponents = sleepDebt
            .split(separator: " ")
            .compactMap { Double($0.replacingOccurrences(of: "h", with: "")
                                    .replacingOccurrences(of: "m", with: "")) }
        let totalDebtHours = (debtComponents.first ?? 0) +
                             ((debtComponents.count > 1 ? debtComponents[1] / 60 : 0))

        // Get previous 7 sleeps, excluding the latest one
        let recentSleeps = Array(logs.dropFirst().prefix(7)).map {
            SanitizedSleepLog(
                start: $0.start,
                end: $0.end,
                sleepQuality: $0.sleepQuality,
                recommendations: $0.recommendations
            )
        }
        
        let sanitizedActivities: [SanitizedActivity] = activities.map {
            SanitizedActivity(
                type: $0.type,
                loggedAt: $0.loggedAt,
                kind: $0.kind,
                otherDescription: $0.otherDescription,
                amountMg: $0.amountMg,
                durationMin: $0.durationMin,
                drinks: $0.drinks,
                medication: $0.medication,
                start: $0.start,
                end: $0.end
            )
        }
        
        // build the struct
        return SleepInsightInput(
            age: profile?.age,
            targetHours: targetHours,
            streakDays: streakDays,
            bedtime: latest.start,
            wakeup: latest.end,
            sleepDebtHours: totalDebtHours,
            activities: sanitizedActivities,
            audioClipsCount: audioClipsCount, // later on we will actually analyze the audio content
            recentSleeps: recentSleeps
        )
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
}
