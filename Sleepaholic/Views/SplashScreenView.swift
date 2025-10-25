//
//  SplashScreenView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-12.
//

import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @State private var isActive = false
    @State private var showStars = false
    @State private var offset: CGFloat = 200
    @State private var rotation: Double = 30
    @State private var opacity: Double = 0
    
    private static var hasShownSplash = false

    var body: some View {
        ZStack {
            if isActive || SplashScreenView.hasShownSplash {
                RootView()
                    .transition(.opacity.animation(.easeOut(duration: 0.5)))
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo
                    Image("SleepaholicLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 268, height: 48)
                        .padding(.bottom, 16)
                    
                    // Stars animation
                    if showStars {
                        Image("stars")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .transition(.scale.combined(with: .opacity))
                            .shadow(color: Color.white70, radius: 10)
                    }
                    
                    Spacer()
                }
                .offset(y: offset)
                .opacity(opacity)
                .onAppear {
                    guard !SplashScreenView.hasShownSplash else {
                        isActive = true
                        return
                    }
                    // Entry animation (move + fade in)
                    withAnimation(.easeOut(duration: 0.8)) {
                        offset = 0
                        opacity = 1
                    }
                    
                    // Rotate slightly then settle flat
                    withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                        rotation = 0
                    }
                    
                    // Show stars image after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            showStars = true
                        }
                    }
                    
                    // Transition to RootView
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isActive = true
                            SplashScreenView.hasShownSplash = true
                        }
                    }
                }
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    perspective: 0.3
                )
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(UserProfileViewModel())
}
