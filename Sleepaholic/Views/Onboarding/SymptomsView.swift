//
//  SymptomsView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-07.
//

import SwiftUI
import CoreHaptics

struct SymptomsView: View {
    @State private var engine: CHHapticEngine?
    @State private var selectedSymptoms: [String: Set<String>] = [
        "Mental": [],
        "Physical": [],
        "Social/Emotional": []
    ]

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
            HStack {
                Button(action: previous) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(8)
                }
                Spacer()
            }
            .padding(.horizontal)

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
                                        toggleSymptom(category: category, symptom: symptom)
                                    } label: {
                                        Text(symptom)
                                            .multilineTextAlignment(.center)
                                            .font(.subheadline)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                selectedSymptoms[category]?.contains(symptom) == true
                                                ? Color.accentColor.opacity(0.2)
                                                : Color(.secondarySystemBackground)
                                            )
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedSymptoms[category]?.contains(symptom) == true
                                                            ? Color.accentColor
                                                            : Color.clear, lineWidth: 2)
                                            )
                                            .animation(.easeInOut(duration: 0.15), value: selectedSymptoms)
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                next()
            }) {
                Text("Fix My Sleep")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .disabled(!canContinue)

            Spacer(minLength: 30)
        }
        .onAppear(perform: prepareHaptics)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers
    private var canContinue: Bool {
        !selectedSymptoms.values.allSatisfy { $0.isEmpty }
    }

    private func toggleSymptom(category: String, symptom: String) {
        if selectedSymptoms[category]?.contains(symptom) == true {
            selectedSymptoms[category]?.remove(symptom)
        } else {
            selectedSymptoms[category]?.insert(symptom)
        }

        // Light haptic on toggle
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SymptomsView(next: {}, previous: {})
}

