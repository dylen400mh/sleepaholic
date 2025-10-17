//
//  WelcomeView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct WelcomeView: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            OnboardingHeader(previous: nil)
            
            Spacer()

            VStack(spacing: 8) {
                Text("Welcome!")
                    .font(.h1Black)
                    .foregroundColor(.white100)

                Text("Let's start by finding out if you have a problem with sleep.")
                    .font(.body2)
                    .foregroundColor(.white80)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 284)
            }
            
            Spacer()

            PrimaryButton(
                title: "Start Quiz",
                icon: nil,
                size: .regular,
                isDisabled: false
            ) {
                HapticsManager.play(.medium)
                next()
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "welcome_viewed")
        }
    }
}

#Preview {
    WelcomeView(next: {})
}
