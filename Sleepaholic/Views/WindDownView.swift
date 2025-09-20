//
//  WindDownView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI

struct WindDownView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var windDown: WindDownManager
    
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
                                if windDown.selectedSounds.contains(sound) {
                                    windDown.selectedSounds.remove(sound)
                                } else {
                                    windDown.selectedSounds.insert(sound)
                                }
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
                    
                    // Restrictions
                    Section {
                        Text("Restrictions")
                            .font(.headline)
                        Toggle("Do Not Disturb", isOn: $windDown.doNotDisturb)
                        Toggle("Grayscale", isOn: $windDown.grayscale)
                        Toggle("Low Brightness", isOn: $windDown.lowBrightness)
                        Toggle("Restrict Apps", isOn: $windDown.restrictApps)
                        
                        if windDown.restrictApps {
                            Button("Modify Restricted Apps") {
                                // action
                            }
                            .foregroundColor(.blue)
                            
                            Text("Currently Restricted:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            ForEach(windDown.restrictedApps, id: \.self) { app in
                                Text("• \(app)")
                                    .foregroundColor(.secondary)
                            }
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
                        
                        Button(action: { windDown.isPlaying.toggle() }) {
                            Image(systemName: windDown.isPlaying ? "pause.fill" : "play.fill")
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: { windDown.selectedSounds.removeAll() }) {
                            Image(systemName: "xmark")
                        }
                    }
                    .padding(.horizontal)
                }
                
                NavigationLink {
                    BedtimeView()
                        .environmentObject(WindDownManager())
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
                
                Button("Cancel Wind Down") {
                    dismiss()
                }
                .foregroundColor(.red)
                .font(.footnote)
                .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        WindDownView()
    }
    .environmentObject(WindDownManager())
}


