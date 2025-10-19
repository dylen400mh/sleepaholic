//
//  Activity.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import Foundation
import FirebaseFirestore

struct Activity: Identifiable, Codable {
    @DocumentID var id: String?
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
    
    enum CodingKeys: String, CodingKey {
        case id, type, loggedAt, kind, otherDescription, amountMg, durationMin, drinks, medication, start, end
    }
}
