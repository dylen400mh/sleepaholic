//
//  RootView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-12.
//

//
//  SubRootView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-12.
//

import SwiftUI
import SuperwallKit

struct RootView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel

    @StateObject private var authService = AuthService.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("bedtimeActive") private var bedtimeActive = false
    
    private let isDemoMode = ProcessInfo.processInfo.environment["DEMO_MODE"] == "1"

    var body: some View {
        Group {
            if isDemoMode {
                if !hasOnboarded {
                    OnboardingView()
                } else if authService.currentUser != nil {
                    // Onboarded + logged in
                    if bedtimeActive {
                        BedtimeView()
                    } else {
                        ContentView()
                    }
                } else {
                    // Onboarded but not signed in → ask to sign in
                    AuthView(
                        next: { Task { await userProfileViewModel.loadProfile() } },
                        previous: nil,
                        showSkipButton: false
                    )
                }
            } else {
                if Superwall.shared.subscriptionStatus.isActive {
                    if authService.currentUser != nil {
                        // Logged in
                        if bedtimeActive {
                            BedtimeView()
                        } else {
                            ContentView()
                        }
                    } else {
                        // Subscribed but not signed in — now must sign in
                        AuthView(
                            next: {
                                Task { await userProfileViewModel.loadProfile() }
                            },
                            previous: nil,
                            showSkipButton: false // no skip allowed post-paywall
                        )
                    }
                } else if hasOnboarded {
                    PaywallView()
                } else {
                    OnboardingView()
                }
            }
        }
        .onReceive(authService.$currentUser) { user in
            if user == nil {
                userProfileViewModel.profile = nil
            } else {
                Task { await userProfileViewModel.loadProfile() }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(UserProfileViewModel())
}
