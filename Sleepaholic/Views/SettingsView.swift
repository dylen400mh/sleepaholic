//
//  SettingsView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-25.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    var showsBackButton: Bool = true

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    @EnvironmentObject var guidedTourManager: GuidedTourManager
    
    @State private var trackSleepWithMic = false
    @State private var replayGuidedTour = false
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                if showsBackButton {
                    BackButtonView(previous: { dismiss() })
                } else {
                    Color.clear.frame(width: 40, height: 40)
                }
                Spacer()
                Text("Settings")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            // MARK: - Settings List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Group {
                        NavigationLink(destination: ProfileView()) {
                            SettingsRow(iconName: "profile", title: "Profile")
                        }
                        .buttonStyle(.plain)
                        SettingsSeparator()
                        
                        NavigationLink(destination: SleepScheduleView()) {
                            SettingsRow(iconName: "bed", title: "Sleep Schedule")
                        }
                        SettingsSeparator()
                        
                        NavigationLink(destination: RestrictionsView()) {
                            SettingsRow(iconName: "block", title: "Restrictions")
                        }
                        SettingsSeparator()
                        
                        SettingsRow(
                            iconName: "microphone",
                            title: "Track Sleep With Microphone",
                            hasArrow: false,
                            toggleBinding: $trackSleepWithMic
                        )
                        .onChange(of: trackSleepWithMic) { _, newValue in
                            Task {
                                await saveSettingChange(newValue)
                            }
                        }
                        SettingsSeparator()
                        
                        SettingsRow(
                            iconName: "moon_sleep",
                            title: "Replay Guided Tour",
                            hasArrow: false,
                            toggleBinding: $replayGuidedTour
                        )
                        .onChange(of: replayGuidedTour) { _, newValue in
                            if newValue {
                                guidedTourManager.requestReplayFromSettings()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    replayGuidedTour = false
                                }
                            }
                        }
                        SettingsSeparator()
                        
                        NavigationLink(destination: SupportView()) {
                            SettingsRow(iconName: "support", title: "Support")
                        }
                        SettingsSeparator()
                        
                        Button {
                           openSubscriptionSettings()
                       } label: {
                           SettingsRow(iconName: "subscription", title: "Manage Subscription")
                       }
                       .buttonStyle(.plain)
                        SettingsSeparator()
                        
                        NavigationLink(destination: MoreView()) {
                            SettingsRow(iconName: "more", title: "More")
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await userSettingsViewModel.loadSettings()
            if let settings = userSettingsViewModel.settings {
                trackSleepWithMic = settings.trackSleep
            }
        }
    }
    
    // MARK: - Save Toggle Change
    private func saveSettingChange(_ newValue: Bool) async {
        guard var updated = userSettingsViewModel.settings else {
            return
        }
        updated.trackSleep = newValue
        await userSettingsViewModel.saveSettings(updated)
    }
    
    // MARK: - Manage Subscription
    private func openSubscriptionSettings() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
