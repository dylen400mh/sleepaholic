//
//  UserProfile.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    @DocumentID var documentId: String?
    var id: String { documentId ?? UUID().uuidString }
    var name: String
    var age: Int
    var gender: String
    var createdAt: Date
}
