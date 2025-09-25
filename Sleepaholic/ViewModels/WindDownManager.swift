//
//  WindDownManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI
import Foundation
import Combine

class WindDownManager: ObservableObject, Codable {
    enum CodingKeys: String, CodingKey {
        case isActive, targetBedtime, targetWakeup, trackSleep,
             doNotDisturb, grayscale, lowBrightness, restrictApps,
             restrictedApps, selectedSounds, isPlaying
    }
    
    // Settings applied during wind down
    @Published var isActive: Bool = false {
        didSet {
            saveState()
            scheduleNotifications()
        }
    }
    @Published var targetBedtime: Date = Date() {
        didSet {
            saveState()
            scheduleNotifications()
        }
    }
    @Published var targetWakeup: Date = Date() {
        didSet {
            saveState()
            scheduleNotifications()
        }
    }
    @Published var trackSleep: Bool = false { didSet { saveState() } }
    @Published var doNotDisturb: Bool = false { didSet { saveState() } }
    @Published var grayscale: Bool = false { didSet { saveState() } }
    @Published var lowBrightness: Bool = false { didSet { saveState() } }
    @Published var restrictApps: Bool = false { didSet { saveState() } }
    @Published var restrictedApps: [String] = [] { didSet { saveState() } }
    @Published var selectedSounds: Set<String> = [] { didSet { saveState() } }
    @Published var isPlaying: Bool = false { didSet { saveState() } }

    static private let storageKey = "windDownState"
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        isActive = try container.decode(Bool.self, forKey: .isActive)
        targetBedtime = try container.decode(Date.self, forKey: .targetBedtime)
        targetWakeup = try container.decode(Date.self, forKey: .targetWakeup)
        trackSleep = try container.decode(Bool.self, forKey: .trackSleep)
        doNotDisturb = try container.decode(Bool.self, forKey: .doNotDisturb)
        grayscale = try container.decode(Bool.self, forKey: .grayscale)
        lowBrightness = try container.decode(Bool.self, forKey: .lowBrightness)
        restrictApps = try container.decode(Bool.self, forKey: .restrictApps)
        restrictedApps = ["TikTok, Instagram, YouTube"]
        selectedSounds = try container.decode(Set<String>.self, forKey: .selectedSounds)
        isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(isActive, forKey: .isActive)
        try container.encode(targetBedtime, forKey: .targetBedtime)
        try container.encode(targetWakeup, forKey: .targetWakeup)
        try container.encode(trackSleep, forKey: .trackSleep)
        try container.encode(doNotDisturb, forKey: .doNotDisturb)
        try container.encode(grayscale, forKey: .grayscale)
        try container.encode(lowBrightness, forKey: .lowBrightness)
        try container.encode(restrictApps, forKey: .restrictApps)
        try container.encode(restrictedApps, forKey: .restrictedApps)
        try container.encode(selectedSounds, forKey: .selectedSounds)
        try container.encode(isPlaying, forKey: .isPlaying)
    }

    init(settings: UserSettings? = nil) {
        self.targetBedtime = settings != nil
            ? WindDownManager.dateFromMinutes(settings!.bedtime)
            : Date()
        self.targetWakeup = settings != nil
            ? WindDownManager.dateFromMinutes(settings!.wakeUpTime)
            : Date()
        self.trackSleep = settings?.trackSleep ?? false
        self.doNotDisturb = settings?.doNotDisturb ?? false
        self.grayscale = settings?.grayscale ?? false
        self.lowBrightness = settings?.lowBrightness ?? false
        self.restrictApps = settings?.restrictApps ?? false
        self.restrictedApps = ["TikTok", "Instagram", "YouTube"]
    }
    
    
    func saveState() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
        
    static func loadState() -> WindDownManager {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(WindDownManager.self, from: data) {
            return decoded
        }
        return WindDownManager()
    }

    // Reset everything back to defaults
    func reset() {
        isActive = false
        selectedSounds.removeAll()
        isPlaying = true
        trackSleep = false
        doNotDisturb = false
        grayscale = false
        lowBrightness = false
        restrictApps = false
        restrictedApps = []
    }
    
    // MARK: - Helpers
    static func dateFromMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    static func minutesFromDate(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
    
    func scheduleNotifications() {
        guard isActive else {
            cancelNotifications()
            return
        }
        
        // Cancel old ones before rescheduling
        cancelNotifications()
        
        // Schedule bedtime
        scheduleNotification(
            id: "bedtime",
            title: "Bedtime Reminder",
            body: "It’s time to go to bed.",
            date: targetBedtime
        )
        
        // Schedule wakeup
        scheduleNotification(
            id: "wakeup",
            title: "Wake Up",
            body: "Good morning! Time to start your day.",
            date: targetWakeup
        )
    }
    
    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true) // repeats daily
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling \(id): \(error)")
            } else {
                print("✅ Scheduled \(id) at \(comps.hour ?? 0):\(comps.minute ?? 0)")
            }
        }
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bedtime", "wakeup"])
    }
}


