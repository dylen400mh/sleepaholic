//
//  UserSettings.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation
import FirebaseFirestore

struct UserSettings: Identifiable, Codable {
    @DocumentID var documentId: String?
    var id: String { documentId ?? UUID().uuidString }
    var bedtime: Date
    var wakeUpTime: Date
    var trackSleep: Bool
    var doNotDisturb: Bool
    var grayscale: Bool
    var lowBrightness: Bool
    var restrictApps: Bool
}
