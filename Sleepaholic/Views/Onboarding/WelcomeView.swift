//
//  WelcomeView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding
    
    let next: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            OnboardingHeader(previous: nil)
            
            Spacer()

            VStack(spacing: 8) {
                Text("Welcome!")
                    .font(.h1Black)
                    .foregroundColor(Color.white100)

                Text("Let's start by finding out if you have a problem with sleep.")
                    .font(.body2)
                    .foregroundColor(Color.white80)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()

            Button {
                HapticsManager.play(.medium)
                next()
            } label: {
                PrimaryButton(
                    title: "Start Quiz",
                    icon: nil,
                    size: .regular,
                    isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, adaptivePadding)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "welcome_viewed")
        }
    }
}

#Preview {
    WelcomeView(next: {})
}
