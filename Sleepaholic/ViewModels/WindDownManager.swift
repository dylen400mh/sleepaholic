//
//  WindDownManager.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI

class WindDownManager: ObservableObject {
    @Published var isActive: Bool = false

    // Settings applied during wind down
    @Published var targetBedtime: Date
    @Published var targetWakeup: Date
    @Published var selectedSounds: Set<String> = []
    @Published var isPlaying: Bool = true
    @Published var trackSleep: Bool

    @Published var doNotDisturb: Bool
    @Published var grayscale: Bool
    @Published var lowBrightness: Bool
    @Published var restrictApps: Bool
    @Published var restrictedApps: [String]


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
}


