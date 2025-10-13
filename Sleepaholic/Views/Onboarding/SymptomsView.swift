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
        VStack(spacing: 24) {
            // MARK: - Header
            BackButtonView(previous: previous)

            VStack(spacing: 8) {
                Text("Symptoms")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Poor sleep can have negative effects on your life. Select any symptoms below:")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(symptoms.keys.sorted(), id: \.self) { category in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(category)
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(symptoms[category]!, id: \.self) { symptom in
                                    Button {
                                        viewModel.toggleSymptom(category: category, symptom: symptom)
                                        HapticsManager.play(.light)
                                    } label: {
                                        Text(symptom)
                                            .multilineTextAlignment(.center)
                                            .font(.subheadline)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                viewModel.selectedSymptoms[category]?.contains(symptom) == true
                                                ? Color.accentColor.opacity(0.2)
                                                : Color(.secondarySystemBackground)
                                            )
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(viewModel.selectedSymptoms[category]?.contains(symptom) == true
                                                            ? Color.accentColor
                                                            : Color.clear, lineWidth: 2)
                                            )
                                            .animation(.easeInOut(duration: 0.15), value: viewModel.selectedSymptoms)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 20)
            }

            Spacer()

            // MARK: - Continue Button
            Button(action: {
                HapticsManager.play(.medium)
                next()
            }) {
                Text("Fix My Sleep")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer(minLength: 30)
        }
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "symptoms_viewed")
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SymptomsView(next: {}, previous: {})
}

