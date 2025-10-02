//
//  SleepLog.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation
import FirebaseFirestore

struct SleepLog: Identifiable, Codable, Equatable {
    @DocumentID var documentId: String?
    var id: String { documentId ?? UUID().uuidString }
    var start: Date
    var end: Date
}
