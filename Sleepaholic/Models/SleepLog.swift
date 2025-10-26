//
//  SleepLog.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation
import FirebaseFirestore

struct SleepLog: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var start: Date
    var end: Date
    
    var sleepQuality: Int?
    var recommendations: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, start, end, sleepQuality, recommendations
    }
}
