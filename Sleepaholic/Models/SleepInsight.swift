//
//  SleepInsight.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-04.
//

import Foundation

struct SleepInsightInput: Codable {
    // User context
    var age: Int?
    var targetHours: Double
    var streakDays: Int

    // Sleep data
    var bedtime: Date
    var wakeup: Date
    var sleepDebtHours: Double

    // Behavior
    var activities: [Activity]
    var audioClipsCount: Int
    
    // Recent sleeps
    var recentSleeps: [SleepLog]?
}

struct SleepInsightOutput: Codable {
    var quality: Int
    var recommendations: [String]
}
