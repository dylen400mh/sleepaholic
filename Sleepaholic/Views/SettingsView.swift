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
    
    @AppStorage("useAppleHealthSleep") private var useAppleHealthSleep = false
    @State private var appleHealthToggle = false

    @State private var trackSleepWithMic = false
    @State private var showHealthAlert = false
    
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
                            iconName: "bed",
                            title: "Use Apple Health Sleep Data",
                            hasArrow: false,
                            toggleBinding: $appleHealthToggle
                        )
                        .onChange(of: appleHealthToggle) { _, newValue in
                            Task { await handleAppleHealthToggleChange(newValue) }
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
            appleHealthToggle = useAppleHealthSleep
        }
        .alert("Health Access Required", isPresented: $showHealthAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("""
                To use Apple Health sleep data, Sleepaholic needs access to your Sleep Analysis data.

                Please enable it by following this path:

                Health App → Browse → Sleep → Data Sources & Access

                Make sure Sleepaholic can read data and is selected as a data source.
                """)
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
    
    private func handleAppleHealthToggleChange(_ newValue: Bool) async {
        if newValue == true {
            await HealthKitManager.shared.requestAuthorization()
            
            let authorized = HealthKitManager.shared.isAuthorized()
            
            if authorized {
                useAppleHealthSleep = true
                appleHealthToggle = true
            } else {
                // Revert toggle
                useAppleHealthSleep = false
                appleHealthToggle = false
                showHealthAlert = true
            }
        } else {
            // User manually disabled Apple Health integration
            useAppleHealthSleep = false
            appleHealthToggle = false
        }
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
