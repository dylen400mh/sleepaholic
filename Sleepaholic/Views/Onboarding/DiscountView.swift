//
//  DiscountView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-11.
//

import SwiftUI

struct DiscountView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showComponent = false
    @State private var remainingTime: Double = 0
    @State private var timer: Timer?
    
    private let key = "discountFireTime"

    var body: some View {
        VStack {
            if showComponent {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("🎁 Special Discount!")
                            .font(.body1Semi)
                            .foregroundColor(Color.white100)
                        
                        Text("Get 80% off on Sleepaholic Premium!")
                            .font(.body2)
                            .foregroundColor(.white80)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        HapticsManager.play(.medium)
                        SuperwallService.shared.presentPaywall(placement: "discount_offer")
                    } label: {
                        PrimaryButton(
                            title: "Claim Now",
                            icon: nil,
                            size: .small,
                            isDisabled: false
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.main)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white5, lineWidth: 1)
                )
                .transition(.scale)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                checkShouldShowImmediately()
            }
        }
    }

    // MARK: - Timer setup
    private func startTimer() {
        guard let fireTime = UserDefaults.standard.object(forKey: key) as? Date else {
            showComponent = false
            timer?.invalidate()
            return
        }

        let remaining = fireTime.timeIntervalSinceNow
        if remaining <= 0 {
            showComponent = true
            timer?.invalidate()
            return
        }

        remainingTime = remaining
        showComponent = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                remainingTime -= 1
                if remainingTime <= 0 {
                    showComponent = true
                    timer?.invalidate()
                }
            }
        }
    }

    
    // MARK: - Recheck logic (for resume or cold start)
    private func checkShouldShowImmediately() {
        if let fireTime = UserDefaults.standard.object(forKey: key) as? Date {
            let remaining = fireTime.timeIntervalSinceNow
            print("🕓 discountFireTime found: \(fireTime) (\(Int(remaining))s remaining)")
            if remaining <= 0 {
                showComponent = true
                timer?.invalidate()
                print("✅ Showing discount: time passed.")
            } else {
                remainingTime = remaining
            }
        } else {
            print("🚫 No discountFireTime found in UserDefaults yet.")
            showComponent = false
        }
    }
}


#Preview {
    DiscountView()
}
