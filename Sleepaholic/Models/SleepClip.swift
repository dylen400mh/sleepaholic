//
//  SleepClip.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-27.
//

import Foundation
import FirebaseFirestore

struct SleepClip: Identifiable, Codable {
    var id: String?
    var storagePath: String
    
    var recordedDate: Date? {
        guard let id,
              let ts = Double(id.replacingOccurrences(of: ".m4a", with: "")) else { return nil }
        return Date(timeIntervalSince1970: ts)
    }
}
