//
//  ProfileIntroView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct ProfileIntroView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    let next: () -> Void
    let previous: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button(action: previous) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(8)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer(minLength: 20)

            // MARK: - Welcome Header
            VStack(spacing: 8) {
                Text("Let's go!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Welcome to Sleepaholic")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // MARK: - Profile Card
            VStack(spacing: 16) {
                Text("Here’s your tracked profile card")
                    .font(.headline)
                    .foregroundColor(.primary)

                ProfileCardView(
                    name: userProfileViewModel.profile?.name ?? "User",
                    streakDays: 0,
                    lastSleep: "—",
                    sleepDebt: "0h"
                )
                .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Now, let's build the app around you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: next) {
                    Text("Next")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 40)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
}

#Preview {
    ProfileIntroView(next: {}, previous: {})
        .environmentObject(UserProfileViewModel())
}

