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
    @State private var skipAnalysisAnimation = false
    @State private var recoveryStartIndex = 0
    
    @StateObject private var quizViewModel = QuizViewModel()
    @StateObject private var symptomsViewModel = SymptomsViewModel()
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var referralViewModel = ReferralViewModel()

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
                QuizView(
                    next: {
                        skipAnalysisAnimation = false
                        goToNext()
                    },
                    previous: goToPrevious,
                    startAt: quizStartIndex
                )
                .environmentObject(quizViewModel)
            case 5:
                AnalysisView(
                    next: goToNext,
                    previous: {
                        quizStartIndex = 12
                        goToPrevious()
                    },
                    skipAnimation: skipAnalysisAnimation
                )
            case 6:
                SymptomsView(
                    next: {
                        recoveryStartIndex = 0
                        goToNext()
                    },
                    previous: {
                        skipAnalysisAnimation = true
                        goToPrevious()
                    }
                )
                .environmentObject(symptomsViewModel)
            case 7:
                RecoveryView(
                    next: goToNext,
                    previous: goToPrevious,
                    startIndex: recoveryStartIndex
                )
            case 8:
                RecoveryBenefitsView(
                    next: goToNext,
                    previous: {
                        recoveryStartIndex = 10
                        goToPrevious()
                    }
                )
            case 9:
                RecoveryGraphView(next: goToNext, previous: goToPrevious)
            case 10:
                GoalsView(next: goToNext, previous: goToPrevious)
                    .environmentObject(goalsViewModel)
            case 11:
                ReferralView(next: goToNext, previous: goToPrevious)
                    .environmentObject(referralViewModel)
            case 12:
                TestimonialsView(next: goToNext, previous: goToPrevious)

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
