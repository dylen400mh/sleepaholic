//
//  AnalysisView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-07.
//

import SwiftUI
import CoreHaptics

struct AnalysisView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @State private var progress: Double = 0
    @State private var engine: CHHapticEngine?
    @State private var showResults = false
    let next: () -> Void
    let previous: () -> Void
    var skipAnimation: Bool = false
    let score: Int
    
    var severityTitle: String {
        switch score {
        case 0...4: "You have little to no issues with your sleep"
        case 5...12: "You are showing some signs of sleep issues"
        default: "Your sleep needs some serious attention"
        }
    }
    
    var severitySubtitle: String {
        switch score {
        case 0...4:
            return "Your habits look good overall, but there’s still room to optimize."
        case 5...12:
            return "Some sleep disruptions are showing up. A few small changes can make a big difference."
        default:
            return "Your responses suggest your sleep is being heavily affected. Here are some things you can do starting tonight."
        }
    }
    
    let tips = [
        "Put your phone away 30 minutes before bed.",
        "Avoid caffeine within 8 hours of bedtime.",
        "Keep a consistent wake-up time — even on weekends.",
        "Dim lights and avoid bright screens during your wind-down.",
        "Get 5–10 minutes of morning sunlight to regulate your rhythm."
    ]

    // Timer for progress animation
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            // MARK: - Back Button
            if showResults {
                OnboardingHeader(previous: previous)
            }

            if !showResults {
                // MARK: - Loading State
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.white10, lineWidth: 15)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                Gradients.main,
                                style: StrokeStyle(lineWidth: 15, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.05), value: progress)
                            .frame(width: 120, height: 120)

                        Text("\(Int(progress * 100))%")
                            .font(.h3Semi)
                            .foregroundColor(.white100)
                            .contentTransition(.numericText())
                    }
                    
                    VStack(spacing: 12) {
                        Text("Calculating")
                            .font(.h2Semi)
                            .foregroundColor(.white100)
                            .multilineTextAlignment(.center)
                        
                        Text(subtitle(for: progress))
                            .font(.body2)
                            .foregroundColor(.white80)
                            .multilineTextAlignment(.center)
                    }
                }
                .onReceive(timer) { _ in
                    guard !showResults && !skipAnimation else { return }
                    if progress < 1.0 {
                        progress += 0.01
                        vibrate()
                    } else {
                        completeAnalysis()
                    }
                }
                .onAppear {
                    AnalyticsService.shared.trackEvent(eventName: "analysis_viewed")
                    
                    if skipAnimation {
                        // Skip calculation and show results directly
                        showResults = true
                        progress = 1.0
                    } else {
                        prepareHaptics()
                    }
                }

            } else {
                // MARK: - Results State
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Analysis Complete")
                            .font(.h2Semi)
                            .foregroundColor(.white100)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(severityTitle)
                            .font(.body1Semi)
                            .foregroundColor(.white100)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(severitySubtitle)
                            .font(.body2)
                            .foregroundColor(.white80)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: - Sleep Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("5 ways to sleep better tonight:")
                            .font(.body1Semi)
                            .foregroundColor(.white100)

                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white100)
                                    .font(.body1)

                                Text(tip)
                                    .font(.body2)
                                    .foregroundColor(.white80)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()

                    Button {
                        HapticsManager.play(.medium)
                        next()
                    } label: {
                        PrimaryButton(
                            title: "Check your symptoms",
                            icon: nil,
                            size: .regular,
                            isDisabled: false
                        )
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.6), value: showResults)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, adaptivePadding)
    }

    // MARK: - Helpers
    func subtitle(for progress: Double) -> String {
        switch progress {
        case 0..<0.3:
            return "Understanding your sleep habits..."
        case 0.3..<0.6:
            return "Analyzing nighttime behaviors..."
        case 0.6..<0.9:
            return "Personalizing your sleep plan..."
        default:
            return "Finalizing your results..."
        }
    }

    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("❌ Haptics error: \(error.localizedDescription)")
        }
    }

    func vibrate() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(progress))
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(progress))
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("❌ Haptic pattern error: \(error.localizedDescription)")
        }
    }

    func completeAnalysis() {
        HapticsManager.play(.success)
        withAnimation(.easeInOut(duration: 0.6)) {
            showResults = true
        }
    }
}

#Preview {
    AnalysisView(next: {}, previous: {}, score: 0)
}
