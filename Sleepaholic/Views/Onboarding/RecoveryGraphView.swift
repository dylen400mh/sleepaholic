//
//  RecoveryGraphView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import SwiftUI

struct RecoveryGraphView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    let next: () -> Void
    let previous: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            OnboardingHeader(previous: previous)

            VStack(spacing: 32) {
                // Title
                Text("Recovery Benefits")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Graph card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sleep Progress")
                        .font(.h3Semi)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image("RecoveryBenefitsGraph")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.main)
                .cornerRadius(16)
                
                Text("Sleepaholic helps improve your sleep 68% faster than trying on your own. 📈")
                    .font(.body2)
                    .foregroundColor(.white80)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            
            // Continue Button
            Button {
                HapticsManager.play(.medium)
                next()
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
            AnalyticsService.shared.trackEvent(eventName: "recovery_graph_viewed")
        }
    }
}

#Preview {
    RecoveryGraphView(next: {}, previous: {})
}
