//
//  WindDownView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI

struct WindDownView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    
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
                }
                .padding(.bottom, adaptivePadding)
            }
            
            // Bottom anchored bar
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
        .navigationBarBackButtonHidden(true)
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
