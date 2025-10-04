//
//  ContentView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel

    var debtProgress: CGFloat {
        let parts = sleepLogViewModel.sleepDebt.split(separator: " ")
        var totalMinutes = 0
        for part in parts {
            if part.contains("h") {
                totalMinutes += (Int(part.replacingOccurrences(of: "h", with: "")) ?? 0) * 60
            } else if part.contains("m") {
                totalMinutes += Int(part.replacingOccurrences(of: "m", with: "")) ?? 0
            }
        }
        // Cap between 0–1
        let maxDebtMinutes = 14 * 60 // assuming 14 hours is max
        return min(CGFloat(totalMinutes) / CGFloat(maxDebtMinutes), 1.0)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Sticky header
                HeaderView { }
                    .padding(.top)

                // Scrollable content
                ScrollView {
                    VStack {
                        // 🔥 streak + quality
                        HStack(spacing: 40) {
                            VStack {
                                Text("🔥 \(sleepLogViewModel.streakDays) day streak")
                                    .font(.headline)
                                Text("Last sleep: \(sleepLogViewModel.lastSleep)")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }

                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                    .frame(width: 80, height: 80)

                                Circle()
                                    .trim(from: 0.0, to: CGFloat(sleepLogViewModel.sleepQuality) / 100)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))

                                VStack {
                                    Text("\(sleepLogViewModel.sleepQuality)%")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text("Quality")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.top, 16)

                        // 😴 sleep debt circle
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 200, height: 200)

                            Circle()
                                .trim(from: 0.0, to: debtProgress)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))

                            VStack {
                                Text("Your sleep debt is:")
                                    .foregroundColor(.gray)
                                Text(sleepLogViewModel.sleepDebt)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.top, 20)

                        // 📋 activities
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Today's Activities")
                                    .font(.headline)
                                Spacer()
                                NavigationLink {
                                    LogActivityView()
                                } label: {
                                    Text("Log Activity")
                                        .font(.subheadline)
                                        .padding(6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }

                            }

                            ForEach(activityViewModel.activities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // 💡 recommendations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sleep Recommendations")
                                .font(.headline)
                            Text(sleepLogViewModel.recommendation)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)

                        Spacer(minLength: 120) // leave room for bottom button
                    }
                }
            }

            // Anchored bottom button
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Divider()
                    NavigationLink {
                        WindDownView()
                    } label: {
                        Text(windDown.isActive ? "Continue Wind Down" : "Start Wind Down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        windDown.isActive = true
                    })
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground)) // solid footer background
            }
        }
        .task {
            await userProfileViewModel.loadProfile()
            await activityViewModel.loadActivities()
            await userSettingsViewModel.loadSettings()
            await sleepLogViewModel.loadSleepLogs()
            
            sleepLogViewModel.recalcStats(userAge: userProfileViewModel.profile?.age)
            
            if let s = userSettingsViewModel.settings, !windDown.isActive {
                windDown.targetBedtime  = WindDownManager.dateFromMinutes(s.bedtime)
                windDown.targetWakeup   = WindDownManager.dateFromMinutes(s.wakeUpTime)
                windDown.trackSleep     = s.trackSleep
                windDown.restrictApps   = s.restrictApps
            }
        }
    }
}


#Preview {
    NavigationStack {
        ContentView()
    }
    .environmentObject(WindDownManager())
    .environmentObject(UserSettingsViewModel())
    .environmentObject(ActivityViewModel())
    .environmentObject(SleepLogViewModel())
    .environmentObject(UserProfileViewModel())
}




