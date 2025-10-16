//
//  BackgroundView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-15.
//

import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()
            
            // Stars & clouds image overlay
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .colorMultiply(Color.starsCloudsBackground)
                .opacity(0.3)
        }
    }
}

