//
//  Activity.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import Foundation

struct Activity: Identifiable {
    let id = UUID()
    var type: ActivityType
    var loggedAt: Date
}

enum ActivityType {
    case caffeine(kind: String, amount: String)
    case workout(kind: String, otherDescription: String?, duration: TimeInterval)
    case alcohol(drinks: Int)
    case medication(name: String, dosage: String)
    case nap(start: Date, end: Date)
}
