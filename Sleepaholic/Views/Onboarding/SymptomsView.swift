//
//  SymptomsView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-07.
//

import SwiftUI
import CoreHaptics

struct SymptomsView: View {
    @EnvironmentObject private var viewModel: SymptomsViewModel

    let next: () -> Void
    let previous: () -> Void

    private let symptoms: [String: [String]] = [
        "Mental": [
            "Feeling unmotivated",
            "Difficulty concentrating",
            "Poor memory or 'brain fog'",
            "General anxiety"
        ],
        "Physical": [
            "Tiredness and low energy",
            "Frequent headaches or muscle tension",
            "Reliance on caffeine",
            "Difficulty waking up"
        ],
        "Social/Emotional": [
            "Low self-confidence",
            "Trouble communicating clearly",
            "Mood swings or irritability",
            "Feeling disconnected or emotionally numb"
        ]
    ]

    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            OnboardingHeader(previous: previous)

            VStack(alignment: .leading, spacing: 12) {
                Text("Symptoms")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Poor sleep can have negative effects on your life. Select any symptoms below:")
                    .font(.body2)
                    .foregroundColor(.white80)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(symptoms.keys.sorted(), id: \.self) { category in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(category)
                                .font(.h3Semi)
                                .foregroundColor(.white100)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 16) {
                                ForEach(symptoms[category]!, id: \.self) { symptom in
                                    MultipleChoiceOption(
                                        text: symptom,
                                        isSelected: viewModel.selectedSymptoms[category]?.contains(symptom) == true,
                                        icon: nil
                                    ) {
                                        HapticsManager.play(.light)
                                        viewModel.toggleSymptom(category: category, symptom: symptom)
                                    }
                                }
                            }
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
                    title: "Fix my sleep",
                    icon: nil,
                    size: .regular,
                    isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "symptoms_viewed")
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SymptomsView(next: {}, previous: {})
}

