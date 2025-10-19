//
//  SleepClip.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-27.
//

import Foundation
import FirebaseFirestore

struct SleepClip: Identifiable, Codable {
    @DocumentID var id: String?
    var storagePath: String
}
