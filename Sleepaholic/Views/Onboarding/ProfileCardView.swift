//
//  ProfileCardView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct ProfileCardView: View {
    let name: String
    let streakDays: Int
    let lastSleep: String
    let sleepDebt: String

    var body: some View {
        VStack(spacing: 12) {
            Text(name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            HStack(spacing: 24) {
                ProfileStat(title: "Streak", value: "\(streakDays)d")
                ProfileStat(title: "Last Sleep", value: lastSleep)
                ProfileStat(title: "Sleep Debt", value: sleepDebt)
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct ProfileStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileCardView(name: "Dylen", streakDays: 0, lastSleep: "8h 0m", sleepDebt: "0h")
}
