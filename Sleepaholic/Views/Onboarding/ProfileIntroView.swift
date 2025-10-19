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
            VStack(spacing: 48) {
                OnboardingHeader(previous: previous)
                
                // MARK: - Welcome Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Let's go!")
                        .font(.h2Semi)
                        .foregroundColor(Color.white100)
                    
                    Text("Welcome to Sleepaholic. Here’s your tracked profile card.")
                        .font(.body2)
                        .foregroundColor(Color.white80)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // MARK: - Profile Card
                ProfileCardView(
                    name: userProfileViewModel.profile?.name ?? "",
                    streakDays: 0,
                    lastSleep: "0h 0min",
                    sleepDebt: "0h 0min"
                )
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Now, let's build the app around you.")
                    .font(.body2)
                    .foregroundColor(Color.white80)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 284)

                Button {
                    HapticsManager.play(.medium)
                    next()
                } label: {
                    PrimaryButton(
                        title: "Next",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
        .onAppear {
            Task {
                await userProfileViewModel.loadProfile()
            }
            
            AnalyticsService.shared.trackEvent(eventName: "profile_intro_viewed")
        }
    }
}

#Preview {
    ProfileIntroView(next: {}, previous: {})
        .environmentObject(UserProfileViewModel())
}

