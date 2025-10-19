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
    
    private let lastInsightKey = "lastInsightGeneratedAt"
    
    @Published private(set) var streakDays: Int
    @Published private(set) var lastSleep: FormattedSleep?
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
        self.lastSleep = nil
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
        audioClipsCount: Int                  // from SleepClipViewModel
    ) -> SleepInsightInput? {

        // get most recent sleep log
        guard let latest = sleepLogs.first else { return nil }

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
        let recentSleeps = Array(sleepLogs.dropFirst().prefix(7))
        
        // build the struct
        return SleepInsightInput(
            age: profile?.age,
            targetHours: targetHours,
            streakDays: streakDays,
            bedtime: latest.start,
            wakeup: latest.end,
            sleepDebtHours: totalDebtHours,
            activities: activities,
            audioClipsCount: audioClipsCount, // later on we will actually analyze the audio content
            recentSleeps: recentSleeps
        )
    }
    
    func generateSleepInsights(
        profile: UserProfile?,
        activities: [Activity],
        audioClipsCount: Int
    ) async {
        guard let input = buildInsightInput(
            profile: profile,
            activities: activities,
            audioClipsCount: audioClipsCount
        ) else {
            print("⚠️ Missing sleep data for AI insights")
            return
        }

        do {
            let output = try await OpenAIService.shared.generateSleepInsights(from: input)
            await MainActor.run {
                self.sleepQuality = output.quality
                self.recommendation = "• " + output.recommendations.joined(separator: "\n• ")
            }

            // Persist
            UserDefaults.standard.set(self.sleepQuality, forKey: "sleepQuality")
            UserDefaults.standard.set(self.recommendation, forKey: "recommendation")
            
            UserDefaults.standard.set(Date(), forKey: lastInsightKey)
        } catch {
            print("❌ Failed to generate insights: \(error.localizedDescription)")
        }
    }

    
    func recalcStats(userAge: Int?) {
        let defaults = UserDefaults.standard

        // 🔥 streak
        streakDays = calculateStreak()
        defaults.set(streakDays, forKey: "streakDays")

        // 🕒 last sleep
        lastSleep = getLastSleep()

        // 😴 sleep debt
        let debtMinutes = calculateSleepDebt(for: sleepLogs, age: userAge)
        sleepDebt = formatMinutes(debtMinutes)
        defaults.set(sleepDebt, forKey: "sleepDebt")
    }
}
