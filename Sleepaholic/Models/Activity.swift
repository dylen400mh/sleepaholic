//
//  Activity.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import Foundation

struct Activity: Identifiable, Codable {
    var id: String = UUID().uuidString
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
