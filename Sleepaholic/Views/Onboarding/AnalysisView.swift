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
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Analysis Complete")
                            .font(.h2Semi)
                            .foregroundColor(.white100)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("We've got some news to break to you...")
                            .font(.body2)
                            .foregroundColor(.white80)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Your responses indicate that you're struggling with poor sleep patterns that may be impacting your daily life*")
                            .font(.body2)
                            .foregroundColor(.white80)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: - Sleep Risk Chart
                    VStack(spacing: 24) {
                        VStack {
                            Image("AnalysisChart")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        }
                        .padding(24)
                        .background(Color.main)
                        .cornerRadius(16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("72% higher risk of unhealthy sleep habits")
                                .font(.body1)
                                .foregroundColor(.white100)
                            Text("* This result is an indication only, not a medical diagnosis")
                                .font(.body2)
                                .foregroundColor(.white80)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
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
    AnalysisView(next: {}, previous: {})
}
