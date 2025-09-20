//
//  ActivityRowView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch activity.type {
            case "caffeine":
                Text("☕️ Caffeine - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                    .fontWeight(.semibold)
                Text("\(activity.kind ?? ""), \(activity.amountMg ?? 0)mg")
                    .foregroundColor(.gray)
                    .font(.subheadline)

            case "workout":
                Text("🏋️‍♂️ Workout - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                    .fontWeight(.semibold)
                Text("\(activity.kind ?? "")\(activity.otherDescription != nil ? " (\(activity.otherDescription!))" : ""), \(activity.durationMin ?? 0) min")
                    .foregroundColor(.gray)
                    .font(.subheadline)

            case "alcohol":
                Text("🍷 Alcohol - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                    .fontWeight(.semibold)
                Text("\(activity.drinks ?? 0) drinks")
                    .foregroundColor(.gray)
                    .font(.subheadline)

            case "medication":
                Text("💊 Medication - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                    .fontWeight(.semibold)
                Text("\(activity.medication ?? ""), \(activity.amountMg ?? 0)mg")
                    .foregroundColor(.gray)
                    .font(.subheadline)

            case "nap":
                Text("😴 Nap")
                    .fontWeight(.semibold)
                Text("\(activity.start?.formatted(date: .omitted, time: .shortened) ?? "") → \(activity.end?.formatted(date: .omitted, time: .shortened) ?? "")")
                    .foregroundColor(.gray)
                    .font(.subheadline)

            default:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
    }
}

