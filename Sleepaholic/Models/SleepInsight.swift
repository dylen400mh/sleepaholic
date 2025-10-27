//
//  SleepInsight.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-04.
//

import Foundation

struct SanitizedActivity: Codable {
    var type: String
    var loggedAt: Date
    var kind: String?
    var otherDescription: String?
    var amountMg: Int?
    var durationMin: Int?
    var drinks: Int?
    var medication: String?
    var start: Date?
    var end: Date?
}

struct SanitizedSleepLog: Codable {
    var start: Date
    var end: Date
    var sleepQuality: Int?
    var recommendations: [String]?
}

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
    var activities: [SanitizedActivity]
    var audioClipsCount: Int
    
    // Recent sleeps
    var recentSleeps: [SanitizedSleepLog]?
}

struct SleepInsightOutput: Codable {
    var quality: Int
    var recommendations: [String]
}
