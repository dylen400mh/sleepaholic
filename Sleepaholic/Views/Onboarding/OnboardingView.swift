//
//  OnboardingView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep: Int = 1

    var body: some View {
        ZStack {
            switch currentStep {
            case 1:
                WelcomeView(next: goToNext)
            case 2:
                AuthView(next: goToNext)
            case 3:
                ProfileIntroView(next: goToNext)
            default:
                Text("Onboarding complete!") // placeholder for next step
            }
        }
        .animation(.easeInOut, value: currentStep)
        .transition(.slide)
    }

    private func goToNext() {
        currentStep += 1
    }
}

#Preview {
    OnboardingView()
}
