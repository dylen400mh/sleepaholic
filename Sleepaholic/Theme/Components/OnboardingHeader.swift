//
//  OnboardingHeader.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-16.
//

import SwiftUI

struct OnboardingHeader: View {
    let previous: (() -> Void)?

    var body: some View {
        HStack {
            if let previous = previous {
                BackButtonView(previous: previous)
            } else {
                // keep layout balanced
                Color.clear.frame(width: 40, height: 40)
            }
            
            Spacer()
            
            Image("SleepaholicLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 157, height: 28)
            
            Spacer()
            // invisible spacer to balance layout
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, 60)
    }
}

