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
            name: "Dylen",
            description: "I was starting to believe that feeling exhausted, unmotivated, and disconnected was just a normal part of life. Fixing my sleep completely shifted how I experience my days. I finally feel present again.",
            imageName: "dylen"
        ),
        .init(
            name: "Anonymous",
            description: "I used to think sleeping 4–5 hours a night was normal. I didn’t realize how much it was affecting my mental clarity and mood until I fixed it. I feel sharper and more in control now.",
            imageName: "anonymous1"
        ),
        .init(
            name: "Anonymous",
            description: "I kept waking up tired no matter how many hours I slept. Sleepaholic made me realize I simply needed better sleep. After closely monitoring my sleep debt I finally feel rested when I wake up.",
            imageName: "anonymous2"
        )
    ]

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Header
            BackButtonView(previous: previous)

            Text("Recovery Benefits")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(benefits) { benefit in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 12) {
                                    Image(benefit.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 45, height: 45)
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(benefit.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                }

                                Spacer()

                                // Checkmark circle
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }

                            Text(benefit.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 80)
            }

            Spacer()

            // MARK: - Continue Button
            Button(action: {
                HapticsManager.play(.medium)
                next()
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "recovery_benefits_viewed")
        }
    }
}

#Preview {
    RecoveryBenefitsView(next: {}, previous: {})
}
