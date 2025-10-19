//
//  RecoveryBenefitsView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import SwiftUI

struct RecoveryBenefitsView: View {
    let next: () -> Void
    let previous: () -> Void

    struct Benefit: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let imageName: String
    }

    private let benefits: [Benefit] = [
        .init(
            name: "Andrew Huberman, Ph.D.",
            description: "Sleep is a cornerstone of both mental health and physical health. Getting better sleep is one of, if not the most powerful tool for your well-being.",
            imageName: "huberman"
        ),
        .init(
            name: "Matthew Walker, Why We Sleep",
            description: "Sleep is the single most effective thing we can do to reset our brain and body health each day — Mother Nature's best effort yet at contra-death.",
            imageName: "walker"
        ),
        .init(
            name: "Dr. Rangan Chatterjee",
            description: "Around 40% of adults in Western countries struggle with sleep — and the consequences go way beyond just feeling tired. Poor sleep impacts everything from mood and appetite to creativity and relationships. Yet, so many of us don’t know how to fix it.",
            imageName: "chatterjee"
        ),
        .init(
            name: "Anonymous",
            description: "I was starting to believe that feeling exhausted, unmotivated, and disconnected was just a normal part of life. Fixing my sleep completely shifted how I experience my days. I finally feel present again.",
            imageName: "profile_logo"
        ),
        .init(
            name: "Anonymous",
            description: "I used to think sleeping 4–5 hours a night was normal. I didn’t realize how much it was affecting my mental clarity and mood until I fixed it. I feel sharper and more in control now.",
            imageName: "profile_logo"
        ),
        .init(
            name: "Anonymous",
            description: "I kept waking up tired no matter how many hours I slept. Sleepaholic made me realize I simply needed better sleep. After closely monitoring my sleep debt I finally feel rested when I wake up.",
            imageName: "profile_logo"
        )
    ]

    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            OnboardingHeader(previous: previous)

            VStack(spacing: 32) {
                Text("Recovery Benefits")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    VStack(spacing: 32) {
                        ForEach(benefits) { benefit in
                            TestimonialCard(
                                name: benefit.name,
                                profileImage: Image(benefit.imageName),
                                review: benefit.description,
                                showCheckmark: true,
                                showStars: false)
                        }
                    }
                }
            }

            // MARK: - Continue Button
            Button {
                HapticsManager.play(.medium)
                next()
            } label: {
                PrimaryButton(
                    title: "Continue",
                    icon: nil,
                    size: .regular,
                    isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "recovery_benefits_viewed")
        }
    }
}

#Preview {
    RecoveryBenefitsView(next: {}, previous: {})
}
