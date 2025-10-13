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
        
        // Flatten selected symptoms
        let selected = selectedSymptoms
            .flatMap { category, symptoms in
                symptoms.map { "\(category): \($0)" }
            }

        // Save to user attributes
        AnalyticsService.shared.updateUserAttributes(
            attributes: ["selected_symptoms": selected]
        )
    }
}
