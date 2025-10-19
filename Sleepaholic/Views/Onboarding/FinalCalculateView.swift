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
    @State private var showProfileCard = false
    
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
        VStack(spacing: 48) {
            OnboardingHeader(previous: nil)
            
            VStack(spacing: 32) {
                // Typing text
                Text(currentText)
                    .font(.h2Semi)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.white100)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140, alignment: .center)

                // Profile card after message 2
                if showProfileCard {
                    ProfileCardView(
                        name: userProfileViewModel.profile?.name ?? "",
                        streakDays: 0,
                        lastSleep: "0h 0min",
                        sleepDebt: "0h 0min"
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.easeOut(duration: 0.5), value: showProfileCard)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "final_calculate_viewed")
            
            Task {
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
                    
                    if messageIndex == 2 {
                        withAnimation(.easeOut(duration: 0.6)) {
                            showProfileCard = true
                        }
                    }
                    
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


