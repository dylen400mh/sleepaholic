//
//  SymptomsViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import Foundation
import SwiftUI

@MainActor
final class SymptomsViewModel: ObservableObject {
    @Published var selectedSymptoms: [String: Set<String>] = [
        "Mental": [],
        "Physical": [],
        "Social/Emotional": []
    ]

    func toggleSymptom(category: String, symptom: String) {
        if selectedSymptoms[category]?.contains(symptom) == true {
            selectedSymptoms[category]?.remove(symptom)
        } else {
            selectedSymptoms[category]?.insert(symptom)
        }
    }
}
