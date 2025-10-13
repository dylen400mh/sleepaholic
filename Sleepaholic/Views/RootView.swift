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

    var body: some View {
        Group {
            if Superwall.shared.subscriptionStatus.isActive {
                ContentView()
            } else if userProfileViewModel.profile?.onboarded == true {
                PaywallView()
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(UserProfileViewModel())
}
