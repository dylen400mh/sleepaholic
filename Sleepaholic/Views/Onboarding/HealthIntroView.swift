//
//  HealthIntroView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-11-16.
//

import SwiftUI

struct HealthIntroView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding
    
    @AppStorage("useAppleHealthSleep") private var useAppleHealthSleep = false
    
    let next: () -> Void
    let previous: () -> Void
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            OnboardingHeader(previous: previous)
            
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Track with Apple Health")
                        .font(.h2Semi)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Sleepaholic can automatically read your bedtime, wake-up times, and sleep stages from Apple Health to give you deeper accuracy and insights.")
                        .font(.body2)
                        .foregroundColor(.white80)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Illustration
                Image("insights")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
            }
            
            // MARK: - Continue button
            Button {
                HapticsManager.play(.medium)
                requestPermissions()
            } label: {
                PrimaryButton(
                    title: "Continue",
                    icon: nil,
                    size: .regular,
                    isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, adaptivePadding)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "health_intro_viewed")
        }
    }
    
    // MARK: - Use your existing manager
    private func requestPermissions() {
        Task {
            await HealthKitManager.shared.requestAuthorization()
            useAppleHealthSleep = HealthKitManager.shared.isAuthorized()
            
            // Regardless of allow/deny, continue
            next()
        }
    }
}

#Preview {
    HealthIntroView(next: {}, previous: {})
        .appBackground()
}
