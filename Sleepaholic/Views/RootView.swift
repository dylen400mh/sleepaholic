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
    @StateObject private var authService = AuthService.shared
    
    private let isDemoMode = ProcessInfo.processInfo.environment["DEMO_MODE"] == "1"

    var body: some View {
        Group {
            if authService.currentUser != nil && (isDemoMode || Superwall.shared.subscriptionStatus.isActive) {
                ContentView()
            } else if userProfileViewModel.profile?.onboarded == true {
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
    }
}

#Preview {
    RootView()
        .environmentObject(UserProfileViewModel())
}
