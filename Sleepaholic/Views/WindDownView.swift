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
    
    @State private var showPicker = false
    @State private var requestingAuth = false
    @State private var authError: String?

    
    let sounds = ["White Noise", "Fan", "Ocean Waves", "Rain", "Crickets", "Campfire", "Birds", "Theta Waves"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(8)
                }
                Spacer()
                Text("Wind Down")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Spacer().frame(width: 32)
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Time pickers
                    Section {
                        DatePicker("Target Bedtime", selection: $windDown.targetBedtime, displayedComponents: .hourAndMinute)
                        DatePicker("Target Wake-Up Time", selection: $windDown.targetWakeup, displayedComponents: .hourAndMinute)
                    }
                    
                    // Sounds
                    Section {
                        Text("Sounds")
                            .font(.headline)
                        ForEach(sounds, id: \.self) { sound in
                            Button(action: {
                                windDown.toggleSound(sound)
                            }) {
                                HStack {
                                    Text(sound)
                                    Spacer()
                                    if windDown.selectedSounds.contains(sound) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Meditation
                    Section {
                        Text("Meditation")
                            .font(.headline)
                        NavigationLink {
                            MeditationView()
                        } label: {
                            Text("Start Meditation")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Sleep Tracking
                    Section {
                        Text("Sleep Tracking")
                            .font(.headline)
                        Toggle("Track Sleep with Microphone", isOn: $windDown.trackSleep)
                    }
                    
                    // MARK: - Restrictions (Screen Time)
                    Section {
                        Text("Restrictions").font(.headline)

                        Toggle("Restrict Apps", isOn: Binding(
                            get: { windDown.restrictApps },
                            set: { newValue in
                                if newValue {
                                    // Request auth (if needed) then show picker
                                    Task { await handleRestrictAppsOn() }
                                } else {
                                    showPicker = false
                                    windDown.restrictApps = false
                                }
                            }
                        ))

                        if windDown.restrictApps {
                            Button("Modify Restricted Apps") { showPicker = true }
                                .foregroundColor(.blue)

                            // Simple summary for MVP
                            Text(summaryText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        if let authError {
                            Text(authError)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 120) // leave space for bottom bar
            }
            
            // Bottom anchored bar
            VStack(spacing: 12) {
                if !windDown.selectedSounds.isEmpty {
                    HStack {
                        Text("Now Playing: \(windDown.selectedSounds.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        
                        Button(action: {
                            if windDown.isPlaying {
                                windDown.pauseAllSounds()
                            } else {
                                windDown.resumeAllSounds()
                            }
                        }) {
                            Image(systemName: windDown.isPlaying ? "pause.fill" : "play.fill")
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: {
                            windDown.stopAllSounds()
                            windDown.selectedSounds.removeAll()
                        }) {
                            Image(systemName: "xmark")
                        }
                    }
                    .padding(.horizontal)
                }
                
                NavigationLink {
                    BedtimeView()
                } label: {
                    Text("Start Bedtime")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    Task {
                        await sleepLogViewModel.startBedtime()
                    }
                })
                
                Button("Cancel Wind Down") {
                    windDown.reset()
                    dismiss()
                }
                .foregroundColor(.red)
                .font(.footnote)
                .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
        }
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
}


