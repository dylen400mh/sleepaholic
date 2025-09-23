//
//  BedtimeView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct BedtimeView: View {
    @EnvironmentObject var windDown: WindDownManager
    @State private var goHome = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Sleepaholic")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Spacer()
            
            VStack(spacing: 20) {
                Text("Bedtime in progress")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Target wake-up time: \(windDown.targetWakeup.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Your phone is in Sleep Mode")
                    .font(.body)
                    .foregroundColor(.gray)

                if windDown.trackSleep {
                    Text("Tracking sleep sounds…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if !windDown.selectedSounds.isEmpty {
                    HStack {
                        Text("Now Playing: \(windDown.selectedSounds.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: { windDown.isPlaying.toggle() }) {
                            Image(systemName: windDown.isPlaying ? "pause.fill" : "play.fill")
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("The following features have been enabled to support your sleep:")
                        .font(.headline)
                        .padding(.top)

                    if windDown.grayscale { Text("• Grayscale") }
                    if windDown.doNotDisturb { Text("• Do Not Disturb") }
                    if windDown.lowBrightness { Text("• Low Brightness") }
                    if windDown.restrictApps { Text("• Non-Essential Apps Disabled") }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Log wake up button
            NavigationLink {
                WakeupView()
            } label: {
                Text("Log Wake Up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            // Quit link
            Button("Quit") {
                windDown.reset()
                goHome = true
            }
            .foregroundColor(.red)
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        BedtimeView()
            .environmentObject(WindDownManager())
    }
}




