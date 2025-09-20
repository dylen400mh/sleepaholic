//
//  MeditationView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI
import Combine

struct MeditationView: View {
    @Environment(\.dismiss) private var dismiss

    // Box-breathing phases: up, right, down, left
    enum Phase { case inhale, hold1, exhale, hold2 }

    @State private var breathsLeft: Int = 10
    @State private var phase: Phase = .inhale

    // 0.00 = bottom-left corner … 1.00 wraps back to bottom-left
    @State private var circleProgress: CGFloat = 0.0

    // Driving tick (every 4 seconds we advance to the next edge/phase)
    @State private var isRunning = true
    @State private var timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    // Completion banner
    @State private var isMeditationComplete = false

    private let squareSize: CGFloat = 220
    private let dotSize: CGFloat = 16

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Meditation")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            // Breaths left (or completion)
            if isMeditationComplete {
                Text("Meditation complete — you’re ready for bed 🌙")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("\(breathsLeft) breaths left")
                    .font(.headline)
            }

            // Instruction text aligned to phase
            Text(instructionText(for: phase))
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 4)

            // Square + moving circle + label
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 2)
                    .frame(width: squareSize, height: squareSize)

                Text("Sleepaholic")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Circle()
                    .frame(width: dotSize, height: dotSize)
                    .offset(circleOffset(for: circleProgress, square: squareSize))
                    // Animate each segment in 4 seconds
                    .animation(.linear(duration: 4), value: circleProgress)
            }
            .padding(.vertical, 12)

            Spacer(minLength: 12)

            // End button (hide while auto-finishing)
            if !isMeditationComplete {
                Button(action: endMeditationNow) {
                    Text("End Meditation")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Start at bottom-left, begin first INHALE segment animating to 0.25
            startPhase(.inhale)
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            advancePhase()
        }
    }

    // MARK: - Phase machine

    private func startPhase(_ p: Phase) {
        phase = p
        switch p {
        case .inhale:
            // bottom-left -> top-left
            animateProgress(to: 0.25)
        case .hold1:
            // top-left -> top-right
            animateProgress(to: 0.50)
        case .exhale:
            // top-right -> bottom-right
            animateProgress(to: 0.75)
        case .hold2:
            // bottom-right -> bottom-left
            animateProgress(to: 1.00)
        }
    }

    private func advancePhase() {
        switch phase {
        case .inhale:
            startPhase(.hold1)

        case .hold1:
            startPhase(.exhale)

        case .exhale:
            // Completed a full breath on finishing EXHALE
            breathsLeft -= 1
            if breathsLeft == 0 {
                finishMeditation()
                return
            }
            startPhase(.hold2)

        case .hold2:
            // Wrap around cleanly: jump to 0.0 without animation, then start inhale animation to 0.25
            withAnimation(.none) { circleProgress = 0.0 }
            startPhase(.inhale)
        }
    }

    private func finishMeditation() {
        isRunning = false
        isMeditationComplete = true
        // Let them see the “complete” message briefly, then go back
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }

    private func endMeditationNow() {
        isRunning = false
        dismiss()
    }

    // MARK: - Animation helpers

    private func animateProgress(to target: CGFloat) {
        circleProgress = target
    }

    private func circleOffset(for progress: CGFloat, square: CGFloat) -> CGSize {
        // progress 0.00...1.00 around the square (clockwise), starting at bottom-left
        let step = progress * 4.0
        let half = square / 2.0

        let point: CGPoint
        switch step {
        case 0..<1:   // bottom-left -> top-left (INHALE, up)
            point = CGPoint(x: -half, y:  half - CGFloat(step) * square)
        case 1..<2:   // top-left -> top-right (HOLD, right)
            point = CGPoint(x: -half + CGFloat(step - 1) * square, y: -half)
        case 2..<3:   // top-right -> bottom-right (EXHALE, down)
            point = CGPoint(x:  half, y: -half + CGFloat(step - 2) * square)
        case 3..<4:   // bottom-right -> bottom-left (HOLD, left)
            point = CGPoint(x:  half - CGFloat(step - 3) * square, y:  half)
        default:
            point = CGPoint(x: -half, y: half) // exact start
        }
        return CGSize(width: point.x, height: point.y)
    }

    private func instructionText(for phase: Phase) -> String {
        switch phase {
        case .inhale: return "Breathe in…"
        case .hold1, .hold2: return "Hold…"
        case .exhale: return "Breathe out…"
        }
    }
}



#Preview {
    MeditationView()
}
