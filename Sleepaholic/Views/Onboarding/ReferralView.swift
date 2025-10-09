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
        VStack(spacing: 24) {
            // Back button
            BackButtonView(previous: previous)
                .padding(.top)

            // Header
            VStack(spacing: 8) {
                Text("Do you have a referral code?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Skip this step if you don’t have a referral code.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Input field
            VStack(spacing: 16) {
                TextField("Referral Code", text: $viewModel.referralCode)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 32)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
            }
            .padding(.top, 20)

            Spacer()

            // Next button
            Button {
                HapticsManager.play(.medium)
                next()
            } label: {
                Text(viewModel.referralCode.isEmpty ? "Skip" : "Next")
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
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut, value: viewModel.referralCode)
    }
}

#Preview {
    ReferralView(next: {}, previous: {})
        .environmentObject(ReferralViewModel())
}

