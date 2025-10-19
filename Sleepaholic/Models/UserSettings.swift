//
//  UserSettings.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation
import FirebaseFirestore

struct UserSettings: Identifiable, Codable {
    @DocumentID var id: String?
    
    // store as minutes since midnight
    var bedtime: Int
    var wakeUpTime: Int
    
    var trackSleep: Bool
    var restrictApps: Bool
}
