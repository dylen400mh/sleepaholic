//
//  ReferralView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-09.
//

import SwiftUI

struct ReferralView: View {
    @EnvironmentObject private var viewModel: ReferralViewModel
    let next: () -> Void
    let previous: () -> Void

    var body: some View {
        VStack {
            VStack(spacing: 48) {
                OnboardingHeader(previous: previous)
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("Do you have a referral code?")
                            .font(.h2Semi)
                            .foregroundColor(.white100)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Skip this step if you don’t have a referral code.")
                            .font(.body2)
                            .foregroundColor(.white80)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    InputField(
                        label: "Referral Code",
                        text: $viewModel.referralCode
                    )
                }
            }
            
            Spacer()
            
            PrimaryButton(
                title: viewModel.referralCode.isEmpty ? "Skip" : "Next",
                icon: nil,
                size: .regular,
                isDisabled: false
            ) {
                HapticsManager.play(.medium)
                next()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "referral_viewed")
        }
        .animation(.easeInOut, value: viewModel.referralCode)
    }
}

#Preview {
    ReferralView(next: {}, previous: {})
        .environmentObject(ReferralViewModel())
}

