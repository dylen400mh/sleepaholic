//
//  WindDownView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI
import FamilyControls

struct WindDownView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    
    @State private var showPicker = false
    @State private var requestingAuth = false
    @State private var authError: String?
    
    @State private var showBedtimePicker = false
    @State private var showWakeupPicker = false
    
    let sounds = ["White Noise", "Fan", "Ocean Waves", "Rain", "Crickets", "Campfire", "Birds", "Theta Waves"]
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 48) {
                    HStack {
                        BackButtonView(previous: { dismiss() })
                        Spacer()
                        Text("Wind Down")
                            .font(.h2Semi)
                            .foregroundColor(Color.white100)
                            .multilineTextAlignment(.center)
                        Spacer()
                        // preserve layout balance
                        Color.clear.frame(width: 40, height: 40)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            TimeInputField(
                                label: "Target Bedtime",
                                date: $windDown.targetBedtime,
                                onTap: { showBedtimePicker = true }
                            )
                            TimeInputField(
                                label: "Target Wake-Up",
                                date: $windDown.targetWakeup,
                                onTap: { showWakeupPicker = true }
                            )
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

                            Toggle("", isOn: $windDown.trackSleep)
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
                                            get: { windDown.restrictApps },
                                            set: { newValue in
                                                if newValue {
                                                    Task { await handleRestrictAppsOn() }
                                                } else {
                                                    showPicker = false
                                                    windDown.restrictApps = false
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
                                    isDisabled: !windDown.restrictApps
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!windDown.restrictApps)

                            if let authError {
                                Text(authError)
                                    .font(.body3)
                                    .foregroundColor(Color.appRed)
                            }
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
                
                NavigationLink {
                    BedtimeView()
                } label: {
                    PrimaryButton(
                        title: "Start Bedtime",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    Task {
                        await sleepLogViewModel.startBedtime()
                    }
                })
                
                Button {
                    windDown.reset()
                    dismiss()
                } label: {
                    SecondaryButton(
                        title: "Cancel Wind Down",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .familyActivityPicker(isPresented: $showPicker, selection: $windDown.restrictedApps)
        .sheet(isPresented: $showBedtimePicker) {
            TimePickerSheet(
                title: "Select Target Bedtime",
                date: $windDown.targetBedtime
            )
            .presentationDetents([.height(300), .medium])
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showWakeupPicker) {
            TimePickerSheet(
                title: "Select Target Wake-Up Time",
                date: $windDown.targetWakeup
            )
            .presentationDetents([.height(300), .medium])
            .presentationCornerRadius(24)
        }
        .appBackground()
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
        authError = nil
        do {
            let status = AuthorizationCenter.shared.authorizationStatus
            if status != .approved {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            }
            // Mark enabled and prompt for the selection (first-time or to edit)
            windDown.restrictApps = true
            showPicker = true
        } catch {
            authError = "Screen Time permission was not granted."
            windDown.restrictApps = false
        }
        requestingAuth = false
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


