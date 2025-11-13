//
//  BedtimeView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct BedtimeView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    
    @State private var now = Date()
    @State private var showFeatures = false
    @State private var showQuitAlert = false
    @State private var showTooShortAlert = false
    @State private var navigateToWakeup = false
    
    private var sleptLongEnough: Bool {
        guard let start = sleepLogViewModel.activeLog?.start else {
            return true
        }
        let diff = Date().timeIntervalSince(start)
        return diff >= 30 * 60  // 30 min in seconds
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Text(now.formatted(date: .abbreviated, time: .omitted))
                    .font(.body3)
                    .foregroundColor(.white80)
                
                Text(now.formatted(date: .omitted, time: .shortened))
                    .font(.custom("Nunito-Regular", size: 64))
                    .foregroundColor(.white100)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image("moon_sleep")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.white)
                    
                    Text("Bedtime in Progress")
                        .font(.h2Semi)
                        .foregroundColor(.white100)
                }
                
                if let settings = userSettingsViewModel.settings {
                    let wakeupDate = WindDownManager.dateFromMinutes(settings.wakeUpTime)
                    Text("Target Wake-Up Time: \(wakeupDate.formatted(date: .omitted, time: .shortened))")
                        .font(.body3)
                        .foregroundColor(.white80)
                }
            }
            
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
                    onStop: nil
                )
            }
            if (userSettingsViewModel.settings?.trackSleep == true || userSettingsViewModel.settings?.restrictApps == true) {
                VStack(spacing: 8) {
                    Button {
                        showFeatures.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Features Enabled")
                                .font(.body3)
                                .foregroundColor(.white80)
                            Image(showFeatures ? "up" : "down")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color.white100)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if showFeatures {
                        VStack(spacing: 12) {
                            // Track sleep indicator
                            if userSettingsViewModel.settings?.trackSleep == true {
                                HStack(spacing: 8) {
                                    Image("microphone")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.white70)
                                    
                                    Text("Tracking Sleep Sounds")
                                        .font(.body3)
                                        .foregroundColor(.white70)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white5)
                                )
                            }
                            
                            // Apps disabled card (only restriction feature)
                            if userSettingsViewModel.settings?.restrictApps == true {
                                HStack(spacing: 8) {
                                    Image("apps")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.white70)
                                    
                                    Text("Apps Restricted")
                                        .font(.body3)
                                        .foregroundColor(.white70)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white5)
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    if sleptLongEnough {
                        navigateToWakeup = true
                    } else {
                        showTooShortAlert = true
                    }
                } label: {
                    SecondaryButton(
                        title: "Log Wake-Up",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
                .alert("Too Early to Log Wake-Up", isPresented: $showTooShortAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("You must sleep at least 30 minutes before logging a wake-up.")
                }


                Button("Quit") {
                    showQuitAlert = true
                }
                .font(.body1Semi)
                .foregroundColor(.white100)
                .alert("Are you sure you want to quit your bedtime?", isPresented: $showQuitAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Quit", role: .destructive) {
                        windDown.reset()
                        Task {
                            await sleepLogViewModel.cancelBedtime()
                        }
                    }
                } message: {
                    Text("Your bedtime session will end and sleep tracking will stop.")
                }
            }
        }
        .padding(.vertical, adaptivePadding)
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now = $0 }
        .appBackground()
        .navigationDestination(isPresented: $navigateToWakeup) {
            WakeupView()
        }
    }
}

#Preview {
    NavigationStack {
        BedtimeView()
    }
    .environmentObject(WindDownManager())
    .environmentObject(SleepLogViewModel())
    .environmentObject(UserSettingsViewModel())
}




