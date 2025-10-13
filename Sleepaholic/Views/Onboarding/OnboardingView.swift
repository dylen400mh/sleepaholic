//
//  OnboardingView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 1
    case auth
    case profileIntro
    case quiz
    case analysis
    case symptoms
    case recovery
    case recoveryBenefits
    case recoveryGraph
    case goals
    case referral
    case testimonials
    case finalCalculate
    case paywall
}


struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var quizStartIndex = 0
    @State private var didSkipQuiz = false
    @State private var skipAnalysisAnimation = false
    @State private var recoveryStartIndex = 0
    
    @StateObject private var quizViewModel = QuizViewModel()
    @StateObject private var symptomsViewModel = SymptomsViewModel()
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var referralViewModel = ReferralViewModel()

    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                WelcomeView(next: goToNext)
            case .auth:
                AuthView(next: goToNext, previous: goToPrevious)
            case .profileIntro:
                ProfileIntroView(
                    next: {
                        didSkipQuiz = false
                        quizStartIndex = 0
                        goToNext()
                    },
                    previous: goToPrevious
                )
            case .quiz:
                QuizView(
                    next: {
                        skipAnalysisAnimation = false
                        goToNext()
                    },
                    previous: goToPrevious,
                    startAt: quizStartIndex,
                    didSkipQuiz: $didSkipQuiz
                )
                .environmentObject(quizViewModel)
            case .analysis:
                AnalysisView(
                    next: goToNext,
                    previous: {
                        quizStartIndex = 12
                        goToPrevious()
                    },
                    skipAnimation: skipAnalysisAnimation
                )
            case .symptoms:
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
            case .recovery:
                RecoveryView(
                    next: goToNext,
                    previous: goToPrevious,
                    startIndex: recoveryStartIndex
                )
            case .recoveryBenefits:
                RecoveryBenefitsView(
                    next: goToNext,
                    previous: {
                        recoveryStartIndex = 10
                        goToPrevious()
                    }
                )
            case .recoveryGraph:
                RecoveryGraphView(next: goToNext, previous: goToPrevious)
            case .goals:
                GoalsView(next: goToNext, previous: goToPrevious)
                    .environmentObject(goalsViewModel)
            case .referral:
                ReferralView(next: goToNext, previous: goToPrevious)
                    .environmentObject(referralViewModel)
            case .testimonials:
                TestimonialsView(next: goToNext, previous: goToPrevious)
            case .finalCalculate:
                FinalCalculateView(next: goToNext)
            default:
                PaywallView()
            }
        }
        .animation(.easeInOut, value: currentStep)
    }

    private func goToNext() {
        switch currentStep {
        case .quiz where didSkipQuiz:
            currentStep = .symptoms
            break
        case .paywall:
            break
        default:
            if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
            break
        }
    }
    
    private func goToPrevious() {
        switch currentStep {
        case .symptoms where didSkipQuiz:
            currentStep = .quiz
            break
        case .welcome:
            break
        default:
            if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = previousStep
            }
            break
        }
    }
}

#Preview {
    OnboardingView()
}
