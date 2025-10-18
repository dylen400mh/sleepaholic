//
//  GoalsViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-09.
//

import SwiftUI

struct Goal: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
}

final class GoalsViewModel: ObservableObject {
    @Published var selected: Set<UUID> = []

    let goals: [Goal] = [
        Goal(title: "Feel refreshed and energized", icon: "charge"),
        Goal(title: "Fall asleep faster", icon: "moon"),
        Goal(title: "Stay asleep longer", icon: "clock"),
        Goal(title: "Eliminate grogginess and brain fog", icon: "brain"),
        Goal(title: "Build consistent sleep habits", icon: "bed"),
        Goal(title: "Improve mood and emotional stability", icon: "face"),
        Goal(title: "Strengthen self-discipline", icon: "book"),
        Goal(title: "Reduce distractions before bed", icon: "device")
    ]

    func toggle(_ goal: Goal) {
        if selected.contains(goal.id) {
            selected.remove(goal.id)
        } else {
            selected.insert(goal.id)
        }
        
        let selectedGoals = goals
            .filter { selected.contains($0.id) }
            .map { $0.title }
        AnalyticsService.shared.updateUserAttributes(attributes: ["goals": selectedGoals])
    }

    func isSelected(_ goal: Goal) -> Bool {
        selected.contains(goal.id)
    }
}
