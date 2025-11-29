//
//  DailyGoalsViewModel.swift
//  Sleepaholic
//
//  Created by OpenAI John on 2025-11-28.
//

import Foundation
import SwiftUI

struct DailyGoal: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let isKeystone: Bool
}

enum DayStatusState: String, Codable {
    case complete
    case partial
    case missed
    case upcoming
}

struct DayStatusItem: Identifiable, Hashable {
    let id = UUID()
    let dateKey: String
    let letter: String
    let status: DayStatusState
}

@MainActor
final class DailyGoalsViewModel: ObservableObject {
    @Published private(set) var todayGoals: [DailyGoal] = []
    @Published private(set) var completed: Set<String> = []
    @Published private(set) var weeklyStatuses: [DayStatusItem] = []

    private let defaults = UserDefaults.standard
    private let dayKeyStorage = "dailyGoals.dayKey"
    private let goalsStorage = "dailyGoals.goals"
    private let completedStorage = "dailyGoals.completed"
    private let historyStorage = "dailyGoals.history"

    private let pool: [DailyGoal] = [
        DailyGoal(id: "bed-temp", title: "Cool room: 65–68°F", detail: "Aim for a bedroom temperature between 65–68°F for deeper sleep quality.", icon: "thermometer", isKeystone: false),
        DailyGoal(id: "bedtime-target", title: "Hit your target bedtime", detail: "Got in bed within 30 minutes of the bedtime you planned.", icon: "moon.zzz", isKeystone: false),
        DailyGoal(id: "wake-target", title: "Consistent wake-up", detail: "Woke up within 30 minutes of your planned wake time.", icon: "alarm", isKeystone: false),
        DailyGoal(id: "no-phone", title: "No phone before bed", detail: "Avoided screens for at least 30 minutes before sleep.", icon: "iphone.slash", isKeystone: false),
        DailyGoal(id: "caffeine-cutoff", title: "Caffeine cut-off", detail: "No caffeine in the 8 hours before bed.", icon: "cup.and.saucer.fill", isKeystone: false),
        DailyGoal(id: "alcohol-light", title: "Light or no alcohol", detail: "No alcohol, or stopped 3+ hours before bed.", icon: "wineglass", isKeystone: false),
        DailyGoal(id: "heavy-meal", title: "Light evening meal", detail: "No heavy meals within 3 hours of bedtime.", icon: "takeoutbag.and.cup.and.straw.fill", isKeystone: false),
        DailyGoal(id: "hydration", title: "Smart hydration", detail: "Hydrated during the day, but tapered 1 hour before bed.", icon: "drop.fill", isKeystone: false),
        DailyGoal(id: "sunlight-am", title: "AM sunlight", detail: "Got 10+ minutes of outdoor light before 10am.", icon: "sun.max.fill", isKeystone: false),
        DailyGoal(id: "no-late-nap", title: "No late naps", detail: "No naps after 3pm to protect night sleep pressure.", icon: "bed.double.circle.fill", isKeystone: false),
        DailyGoal(id: "light-dim", title: "Dim the lights", detail: "Lowered lights 60 minutes before bed to cue melatonin.", icon: "lightbulb.slash.fill", isKeystone: false),
        DailyGoal(id: "bedroom-dark", title: "Dark room", detail: "Slept in a dark room (blackout curtains or eye mask).", icon: "moon.stars.fill", isKeystone: false),
        DailyGoal(id: "bedroom-quiet", title: "Quiet room", detail: "Kept noise low or used white/pink noise at a gentle level.", icon: "ear", isKeystone: false),
        DailyGoal(id: "winddown", title: "Wind-down routine", detail: "Did a calming 10-minute routine (stretching, reading, breathwork).", icon: "sparkles", isKeystone: false),
        DailyGoal(id: "gratitude", title: "Brain dump", detail: "Jotted a quick worry/next-day list to clear your mind.", icon: "list.bullet.rectangle", isKeystone: false),
        DailyGoal(id: "movement", title: "Daytime movement", detail: "Got 20+ minutes of movement today (walk counts).", icon: "figure.walk.motion", isKeystone: false),
        DailyGoal(id: "bed-is-bed", title: "Bed is for sleep", detail: "Used the bed only for sleep/relaxation (no work/scrolling).", icon: "bed.double.fill", isKeystone: false),
        DailyGoal(id: "breathing", title: "Slow breathing", detail: "Did 2–5 minutes of slow breathing (e.g., 4-7-8).", icon: "lungs.fill", isKeystone: false),
        DailyGoal(id: "morning-water", title: "Morning water", detail: "Had a glass of water within 30 minutes of waking.", icon: "water.waves", isKeystone: false),
        DailyGoal(id: "no-snooze", title: "No snooze", detail: "Got up with your first alarm (no snoozing).", icon: "bell.slash.fill", isKeystone: false),
        DailyGoal(id: "bedroom-tidy", title: "Tidy sleep space", detail: "Kept the bedroom clutter-free to reduce cognitive load.", icon: "square.stack.3d.up.fill", isKeystone: false),
        DailyGoal(id: "mask", title: "Wear an eye mask", detail: "If light leaks, used an eye mask to stay asleep.", icon: "eye.slash.fill", isKeystone: false),
        DailyGoal(id: "earplugs", title: "Noise blockers", detail: "Used earplugs/white noise if noise is common.", icon: "ear.and.waveform", isKeystone: false),
        // App-specific keystone habits
        DailyGoal(id: "set-winddown-time", title: "Set wind-down time", detail: "Chose your nightly wind-down time in the Wind Down tab.", icon: "timer", isKeystone: true),
        DailyGoal(id: "set-wakeup-time", title: "Set wake-up time", detail: "Confirmed your target wake time in the Wind Down tab.", icon: "alarm.waves.left.and.right", isKeystone: true),
        DailyGoal(id: "app-restrictions", title: "Lock distractions", detail: "Enabled app restrictions to stop doomscrolling before bed.", icon: "lock.iphone", isKeystone: true),
        DailyGoal(id: "sleep-tracker-on", title: "Sleep tracker on", detail: "Turned on Sleep Tracker for smarter recommendations.", icon: "waveform.path.ecg", isKeystone: true),
        DailyGoal(id: "winddown-session", title: "Run tonight's wind-down", detail: "Started tonight’s wind-down session from the Wind Down tab.", icon: "sparkles", isKeystone: true),
        DailyGoal(id: "log-activities", title: "Log today’s activities", detail: "Logged caffeine, alcohol, workout, or naps to personalize insights.", icon: "list.clipboard", isKeystone: true)
    ]

    init() {
        refreshForCurrentDayIfNeeded()
    }

    func refreshForCurrentDayIfNeeded(now: Date = Date()) {
        let key = currentDayKey(for: now)
        let storedKey = defaults.string(forKey: dayKeyStorage)

        // When a new day starts, finalize the previous day's outcome
        if let storedKey, storedKey != key {
            finalizePreviousDay(withKey: storedKey)
        }

        if storedKey == key,
           let storedIDs = defaults.array(forKey: goalsStorage) as? [String],
           !storedIDs.isEmpty {
            todayGoals = storedIDs.compactMap { id in
                pool.first(where: { $0.id == id })
            }
            let storedCompleted = Set(defaults.array(forKey: completedStorage) as? [String] ?? [])
            completed = storedCompleted.intersection(storedIDs)
            updateWeeklyStatuses(referenceDate: now)
        } else {
            assignNewGoals(for: key)
        }
    }

    func toggle(_ goal: DailyGoal) {
        // Ensure we are on the correct day before toggling
        refreshForCurrentDayIfNeeded()

        var newCompleted = completed
        if newCompleted.contains(goal.id) {
            newCompleted.remove(goal.id)
        } else {
            newCompleted.insert(goal.id)
        }
        completed = newCompleted
        persistState()

        HapticsManager.play(.medium)
        if isAllComplete {
            HapticsManager.play(.success)
        }

        updateWeeklyStatuses()
    }

    var progress: Double {
        guard !todayGoals.isEmpty else { return 0 }
        return Double(completed.count) / Double(todayGoals.count)
    }

    var isAllComplete: Bool {
        !todayGoals.isEmpty && completed.count == todayGoals.count
    }

    private func assignNewGoals(for dayKey: String) {
        let keystones = pool.filter { $0.isKeystone }
        let nonKeystones = pool.filter { !$0.isKeystone }

        var selection: [DailyGoal] = []
        if let keystone = keystones.randomElement() {
            selection.append(keystone)
        }

        let remainingNeeded = max(0, 3 - selection.count)
        let fillers = nonKeystones
            .shuffled()
            .filter { !selection.contains($0) }
            .prefix(remainingNeeded)

        selection.append(contentsOf: fillers)

        // Fallback in case something went wrong
        if selection.count < 3 {
            selection.append(contentsOf: pool.shuffled().prefix(3 - selection.count))
        }

        todayGoals = selection
        completed = []
        defaults.set(dayKey, forKey: dayKeyStorage)
        defaults.set(selection.map { $0.id }, forKey: goalsStorage)
        defaults.set([], forKey: completedStorage)
        updateWeeklyStatuses()
    }

    private func finalizePreviousDay(withKey previousKey: String) {
        let storedIDs = defaults.array(forKey: goalsStorage) as? [String] ?? []
        let storedCompleted = Set(defaults.array(forKey: completedStorage) as? [String] ?? [])

        let status: DayStatusState
        if storedIDs.isEmpty {
            status = .missed
        } else if storedCompleted.count == storedIDs.count {
            status = .complete
        } else if storedCompleted.isEmpty {
            status = .missed
        } else {
            status = .partial
        }

        var history = defaults.dictionary(forKey: historyStorage) as? [String: String] ?? [:]
        history[previousKey] = status.rawValue
        defaults.set(history, forKey: historyStorage)
    }

    private func persistState() {
        defaults.set(Array(completed), forKey: completedStorage)
        defaults.synchronize()
    }

    /// Returns a stable day identifier that resets at 2pm local time.
    private func currentDayKey(for date: Date) -> String {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 14
        components.minute = 0
        components.second = 0

        guard let twoPMToday = calendar.date(from: components) else {
            return ISO8601DateFormatter().string(from: calendar.startOfDay(for: date))
        }

        let effectiveDate: Date
        if date < twoPMToday {
            effectiveDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        } else {
            effectiveDate = date
        }

        let start = calendar.startOfDay(for: effectiveDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: start)
    }

    private func updateWeeklyStatuses(referenceDate: Date = Date()) {
        let calendar = Calendar.current
        let history = defaults.dictionary(forKey: historyStorage) as? [String: String] ?? [:]
        let currentKey = currentDayKey(for: referenceDate)

        var items: [DayStatusItem] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: referenceDate),
                  let normalized = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: day) else { continue }

            let key = currentDayKey(for: normalized)
            let letter = weekdayLetter(for: normalized)

            let status: DayStatusState
            if key == currentKey {
                if isAllComplete {
                    status = .complete
                } else if completed.isEmpty {
                    status = .upcoming
                } else {
                    status = .partial
                }
            } else if let raw = history[key], let stored = DayStatusState(rawValue: raw) {
                status = stored
            } else {
                status = .missed
            }

            items.append(DayStatusItem(dateKey: key, letter: letter, status: status))
        }

        weeklyStatuses = items
    }

    private func weekdayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
