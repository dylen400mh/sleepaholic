//
//  WelcomeView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct WelcomeView: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Welcome!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            Text("Let's start by finding out if you have a problem with sleep.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                HapticsManager.play(.medium)
                next()
            }) {
                Text("Start Quiz")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeView(next: {})
}
