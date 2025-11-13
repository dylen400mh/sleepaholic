//
//  WindDownView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI
import FamilyControls

struct WindDownView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    
    @State private var showPicker = false
    @State private var requestingAuth = false
    
    let sounds = ["White Noise", "Fan", "Ocean Waves", "Rain", "Crickets", "Campfire", "Birds", "Theta Waves"]
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 48) {
                    HStack {
                        Spacer()
                        Text("Wind Down")
                            .font(.h2Semi)
                            .foregroundColor(Color.white100)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            if let settings = userSettingsViewModel.settings {
                                StyledDatePicker(
                                    label: "Target Bedtime",
                                    date: Binding(
                                        get: { WindDownManager.dateFromMinutes(settings.bedtime) },
                                        set: { newDate in
                                            Task { await saveSettingChange(\.bedtime, newValue: WindDownManager.minutesFromDate(newDate)) }
                                        }
                                    )
                                )
                                StyledDatePicker(
                                    label: "Target Wake-Up",
                                    date: Binding(
                                        get: { WindDownManager.dateFromMinutes(settings.wakeUpTime) },
                                        set: { newDate in
                                            Task { await saveSettingChange(\.wakeUpTime, newValue: WindDownManager.minutesFromDate(newDate)) }
                                        }
                                    )
                                )
                            }
                        }
                        
                        let targetHours = sleepLogViewModel.ageBasedTargetHours(for: userProfileViewModel.profile?.age)
                        HStack(spacing: 8) {
                            Image("clock")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(Color.white80)
                            Text("Based on your age, we recommend at least \(Int(targetHours)) hours of sleep per night. Sleep debt will be calculated accordingly.")
                                .font(.body3)
                                .foregroundColor(Color.white80)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        HeaderWithSeparator(title: "Sounds")
                        
                        let topRow = Array(sounds.prefix(4))
                        let bottomRow = Array(sounds.suffix(4))

                        SoundRow(items: topRow)
                        SoundRow(items: bottomRow)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Meditation")
                            .font(.h3Semi)
                            .foregroundColor(Color.white100)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        NavigationLink {
                            MeditationView()
                        } label: {
                            SecondaryButton(
                                title: "Start Meditation",
                                icon: nil,
                                size: .regular,
                                isDisabled: false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 16) {
                            Image("microphone")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.white100)

                            Text("Track sleep with microphone")
                                .font(.body1Semi)
                                .foregroundColor(Color.white100)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Toggle("", isOn:
                                    Binding(
                                        get: { userSettingsViewModel.settings?.trackSleep ?? false },
                                        set: { newValue in
                                            Task { await saveSettingChange(\.trackSleep, newValue: newValue) }
                                        }
                                    )
                            )
                            .toggleStyle(ToggleButton())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        HeaderWithSeparator(title: "Restrictions")

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 16) {
                                Image("apps") // your icon; otherwise "lock.iphone" SF Symbol
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white100)

                                Text("Restrict Apps")
                                    .font(.body1Semi)
                                    .foregroundColor(.white100)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Toggle("", isOn:
                                        Binding(
                                            get: { userSettingsViewModel.settings?.restrictApps ?? false },
                                            set: { newValue in
                                                if newValue {
                                                    Task { await handleRestrictAppsOn() }
                                                } else {
                                                    showPicker = false
                                                    Task { await saveSettingChange(\.restrictApps, newValue: false) }
                                                }
                                            }
                                        )
                                )
                                .toggleStyle(ToggleButton())
                            }

                            Text(summaryText)
                                .font(.body2)
                                .foregroundColor(.white70)

                            Button {
                                showPicker = true
                            } label: {
                                SecondaryButton(
                                    title: "Modify Restricted Apps",
                                    icon: nil,
                                    size: .small,
                                    isDisabled: !(userSettingsViewModel.settings?.restrictApps ?? false)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!(userSettingsViewModel.settings?.restrictApps ?? false))
                        }
                    }
                }
            }
            
            // Bottom anchored bar
            VStack(spacing: 16) {
                if !windDown.selectedSounds.isEmpty {
                    MixCard(
                        sounds: windDown.selectedSounds,
                        isPlaying: windDown.isPlaying,
                        onPlayPause: {
                            if windDown.isPlaying {
                                windDown.pauseAllSounds()
                            } else {
                                windDown.resumeAllSounds()
                            }
                        },
                        onStop: {
                            windDown.stopAllSounds()
                            windDown.selectedSounds.removeAll()
                        }
                    )
                }
            }
        }
        .padding(.vertical, adaptivePadding)
        .navigationBarBackButtonHidden(true)
        .familyActivityPicker(isPresented: $showPicker, selection: $windDown.restrictedApps)
    }
    
    private var summaryText: String {
        let a = windDown.restrictedApps.applicationTokens.count
        let c = windDown.restrictedApps.categoryTokens.count
        let w = windDown.restrictedApps.webDomainTokens.count
        return "Selected \(a) apps, \(c) categories, \(w) websites"
    }

    // MARK: - Auth + Picker flow
    private func handleRestrictAppsOn() async {
        requestingAuth = true
        do {
            let status = AuthorizationCenter.shared.authorizationStatus
            if status != .approved {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            }
            // Mark enabled and prompt for the selection (first-time or to edit)
            await saveSettingChange(\.restrictApps, newValue: true)
            showPicker = true
        } catch {
            await saveSettingChange(\.restrictApps, newValue: false)
        }
        requestingAuth = false
    }
    
    private func saveSettingChange<T>(_ keyPath: WritableKeyPath<UserSettings, T>, newValue: T) async {
        guard var settings = userSettingsViewModel.settings else { return }
        settings[keyPath: keyPath] = newValue
        await userSettingsViewModel.saveSettings(settings)
    }
}

#Preview {
    NavigationStack {
        WindDownView()
    }
    .environmentObject(WindDownManager())
    .environmentObject(SleepLogViewModel())
    .environmentObject(UserProfileViewModel())
}
