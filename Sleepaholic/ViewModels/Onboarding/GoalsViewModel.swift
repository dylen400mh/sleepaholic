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
        Goal(title: "Feel refreshed and energized", icon: "bolt.heart.fill"),
        Goal(title: "Fall asleep faster", icon: "moon.zzz.fill"),
        Goal(title: "Stay asleep longer", icon: "bed.double.fill"),
        Goal(title: "Eliminate grogginess and brain fog", icon: "brain.head.profile"),
        Goal(title: "Build consistent sleep habits", icon: "calendar"),
        Goal(title: "Improve mood and emotional stability", icon: "smiley.fill"),
        Goal(title: "Strengthen self-discipline", icon: "figure.run"),
        Goal(title: "Reduce distractions before bed", icon: "moon.stars")
    ]

    func toggle(_ goal: Goal) {
        if selected.contains(goal.id) {
            selected.remove(goal.id)
        } else {
            selected.insert(goal.id)
        }
    }

    func isSelected(_ goal: Goal) -> Bool {
        selected.contains(goal.id)
    }
}
