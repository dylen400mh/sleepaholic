//
//  OnboardingView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep: Int = 1
    @State private var quizStartIndex = 0

    var body: some View {
        ZStack {
            switch currentStep {
            case 1:
                WelcomeView(next: goToNext)
            case 2:
                AuthView(next: goToNext, previous: goToPrevious)
            case 3:
                ProfileIntroView(
                    next: {
                        quizStartIndex = 0
                        goToNext()
                    },
                    previous: goToPrevious
                )
            case 4:
                QuizView(next: goToNext, previous: goToPrevious, startAt: quizStartIndex)
            case 5:
                AnalysisView(
                    next: goToNext,
                    previous: {
                        quizStartIndex = 12
                        goToPrevious()
                    }
                )
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
    
    private func goToPrevious() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
}

#Preview {
    OnboardingView()
}
