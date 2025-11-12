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
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel

    @StateObject private var authService = AuthService.shared
    @StateObject private var superwallService = SuperwallService.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("bedtimeActive") private var bedtimeActive = false

    var body: some View {
        Group {
            if superwallService.isSubscribed {
                if authService.currentUser != nil {
                    // Logged in
                    if bedtimeActive {
                        NavigationStack {
                            BedtimeView()
                        }
                    } else {
                        MainTabView()
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
        .onReceive(authService.$currentUser) { user in
            if user == nil {
                userProfileViewModel.profile = nil
            } else {
                Task { await userProfileViewModel.loadProfile() }
            }
        }
        .task {
            windDown.userSettingsViewModel = userSettingsViewModel
        }
    }
}

#Preview {
    RootView()
        .environmentObject(UserProfileViewModel())
}
