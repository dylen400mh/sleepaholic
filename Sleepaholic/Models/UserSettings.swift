//
//  UserSettings.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation

struct UserSettings: Identifiable, Codable {
    var id: String
    var bedtime: Date
    var wakeUpTime: Date
    var trackSleep: Bool
    var doNotDisturb: Bool
    var grayscale: Bool
    var lowBrightness: Bool
    var restrictApps: Bool
}
