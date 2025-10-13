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

    var body: some View {
        ZStack {
            if isActive {
                RootView()
                    .transition(.opacity.animation(.easeOut(duration: 0.5)))
            } else {
                ZStack {
                    Text("Sleepaholic")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(0.9)
                }
                .transition(.opacity)
            }
        }
        .task {
            await startLoading()
        }
    }

    private func startLoading() async {
        let startTime = Date()

        // Ensure splash shows at least 1 second
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(1.0 - elapsed, 0)
        try? await Task.sleep(for: .seconds(remaining))

        // Fade out splash
        withAnimation(.easeOut(duration: 0.5)) {
            isActive = true
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(UserProfileViewModel())
}
