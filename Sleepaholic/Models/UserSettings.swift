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
    
    // store as minutes since midnight
    var bedtime: Int
    var wakeUpTime: Int
    
    var trackSleep: Bool
    var restrictApps: Bool
}
