//
//  SleepLog.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation

struct SleepLog: Identifiable, Codable {
    var id: String
    var start: Date
    var end: Date
}
