//
//  FinalCalculateView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-09.
//

import SwiftUI
import CoreHaptics

struct FinalCalculateView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel

    @State private var currentText = ""
    @State private var currentIndex = 0
    @State private var messageIndex = 0
    @State private var engine: CHHapticEngine?
    @State private var userName: String = ""
    @State private var isAnimating = false
    
    let next: () -> Void

    private var messages: [String] {
        [
            userName.isEmpty ? "Hey," : "Hey, \(userName)",
            "Welcome to Sleepaholic, your path to better sleep.",
            "Based on your answers, we've built a plan just for you.",
            "It's designed to help you wake up refreshed in 7 days.",
            "Now, it's time to invest in yourself."
        ]
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Typing text
                Text(currentText)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 30)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)

                // Profile card after message 2
                if messageIndex >= 2 {
                    ProfileCardView(
                        name: userProfileViewModel.profile?.name ?? "",
                        streakDays: 0,
                        lastSleep: "—",
                        sleepDebt: "0h"
                    )
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await userProfileViewModel.loadProfile()
                if let name = userProfileViewModel.profile?.name,
                   !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    userName = name.components(separatedBy: " ").first ?? ""
                }
                if !isAnimating {
                    isAnimating = true
                    startAnimation()
                    prepareHaptics()
                }
            }
        }
    }

    // MARK: - Typing animation
    private func startAnimation() {
        guard messageIndex < messages.count else { return }

        let text = messages[messageIndex]
        currentText = ""
        currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < text.count {
                let nextCharacter = String(text[text.index(text.startIndex, offsetBy: currentIndex)])
                currentText += nextCharacter
                currentIndex += 1
                triggerHapticFeedback()
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    messageIndex += 1
                    if messageIndex < messages.count {
                        startAnimation()
                    } else {
                        HapticsManager.play(.heavy)
                        next()
                    }
                }
            }
        }
    }

    // MARK: - Haptics
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics engine error: \(error.localizedDescription)")
        }
    }

    private func triggerHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
}

#Preview {
    FinalCalculateView(next: {})
        .environmentObject(UserProfileViewModel())
}


