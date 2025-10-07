//
//  AnalysisView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-07.
//

import SwiftUI
import CoreHaptics

struct AnalysisView: View {
    @State private var progress: Double = 0
    @State private var engine: CHHapticEngine?
    @State private var showResults = false
    let next: () -> Void
    let previous: () -> Void

    // Timer for progress animation
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                // MARK: - Back Button
                if showResults {
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
                }

                Spacer()

                if !showResults {
                    // MARK: - Loading State
                    VStack(spacing: 30) {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray6).opacity(0.6), lineWidth: 15)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    AngularGradient(gradient: Gradient(colors: [
                                        Color.accentColor,
                                        Color.green.opacity(0.8)
                                    ]), center: .center),
                                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.05), value: progress)

                            Text("\(Int(progress * 100))%")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .contentTransition(.numericText())
                        }
                        .frame(width: 200, height: 200)

                        Text("Analyzing your responses...")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(subtitle(for: progress))
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .onReceive(timer) { _ in
                        guard !showResults else { return }
                        if progress < 1.0 {
                            progress += 0.01
                            vibrate()
                        } else {
                            completeAnalysis()
                        }
                    }
                    .onAppear(perform: prepareHaptics)
                } else {
                    // MARK: - Results State
                    VStack(spacing: 30) {
                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Analysis Complete")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }

                            Text("Your responses indicate that you may be struggling with poor sleep patterns that could impact your daily life.")
                                .multilineTextAlignment(.center)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }

                        // MARK: - Sleep Risk Chart
                        VStack(spacing: 10) {
                            Text("Sleep Health Score")
                                .font(.headline)
                                .padding(.bottom, 4)

                            HStack(spacing: 12) {
                                VStack {
                                    Text("You")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: 60, height: 150 * 0.72)
                                    Text("72%")
                                        .font(.headline)
                                }

                                VStack {
                                    Text("Average")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.4))
                                        .frame(width: 60, height: 150 * 0.46)
                                    Text("46%")
                                        .font(.headline)
                                }
                            }
                            .frame(height: 160)
                        }

                        Text("*This result is an indication only and not a medical diagnosis.*")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer()

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            next()
                        }) {
                            Text("Check Your Symptoms")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                    }
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.6), value: showResults)
                }

                Spacer()
            }
        }
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
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        withAnimation(.easeInOut(duration: 0.6)) {
            showResults = true
        }
    }
}

#Preview {
    AnalysisView(next: {}, previous: {})
}
