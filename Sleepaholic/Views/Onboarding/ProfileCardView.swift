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
        VStack(spacing: 0) {
            HStack {
                Image("SleepaholicLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 95, height: 17)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.main)
            
            VStack(spacing: 24) {
                // Last night’s sleep
                VStack(spacing: 4) {
                    Text("Last Night’s Sleep")
                        .font(.body3)
                        .foregroundColor(.white80)
                    Text(lastSleep)
                        .font(.h3Semi)
                        .foregroundColor(.white100)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

                HStack(spacing: 24) {
                    // Streak
                    HStack(spacing: 12) {
                        Gradients.main.mask(
                                Image(systemName: "flame.fill")
                                    .resizable()
                                    .scaledToFit()
                            )
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(streakDays) nights")
                                .font(.body1Semi)
                                .foregroundColor(.white100)
                            Text("Streak")
                                .font(.body3)
                                .foregroundColor(.white80)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(Color.white10)
                        .frame(width: 1, height: 44)

                    // Sleep debt
                    HStack(spacing: 12) {
                        Gradients.main.mask(
                                Image(systemName: "moon.zzz.fill")
                                    .resizable()
                                    .scaledToFit()
                            )
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sleepDebt)
                                .font(.body1Semi)
                                .foregroundColor(.white100)
                            Text("Sleep Debt")
                                .font(.body3)
                                .foregroundColor(.white80)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 44)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color.dark)
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white5, lineWidth: 1)
        )
    }
}

#Preview {
    ProfileCardView(name: "Dylen", streakDays: 0, lastSleep: "8h 0m", sleepDebt: "0h")
}
