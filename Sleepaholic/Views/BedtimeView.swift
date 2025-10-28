//
//  BedtimeView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct BedtimeView: View {
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @State private var goHome = false
    
    @State private var now = Date()
    @State private var showFeatures = false
    @State private var showQuitAlert = false


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
                
                Text("Target Wake-Up Time: \(windDown.targetWakeup.formatted(date: .omitted, time: .shortened))")
                    .font(.body3)
                    .foregroundColor(.white80)
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
            if (windDown.trackSleep || windDown.restrictApps) {
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
                            if windDown.trackSleep {
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
                            if windDown.restrictApps {
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
                NavigationLink {
                    WakeupView()
                } label: {
                    SecondaryButton(
                        title: "Log Wake-Up",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)

                Button("Quit") {
                    showQuitAlert = true
                }
                .font(.body1Semi)
                .foregroundColor(.white100)
                .alert("Are you sure you want to quit your bedtime?", isPresented: $showQuitAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Quit", role: .destructive) {
                        windDown.reset()
                        sleepLogViewModel.stopBedtime()
                        goHome = true
                    }
                } message: {
                    Text("Your bedtime session will end and sleep tracking will stop.")
                }
            }
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
        }
        .task {
            if windDown.trackSleep, let log = sleepLogViewModel.activeLog {
                if let id = log.id {
                    windDown.startMonitoringSleep(logId: id)
                }
            }
        }
        .onDisappear {
            if let logId = sleepLogViewModel.activeLog?.id {
                windDown.stopMonitoringSleep(logId: logId)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now = $0 }
        .appBackground()
    }
}

#Preview {
    NavigationStack {
        BedtimeView()
    }
    .environmentObject(WindDownManager())
    .environmentObject(SleepLogViewModel())
}




