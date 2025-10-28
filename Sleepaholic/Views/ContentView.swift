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
    @EnvironmentObject var sleepClipViewModel: SleepClipViewModel

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
            VStack(spacing: 24) {
                // Sticky header
                HeaderView()
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            // sleep quality & streak
                            HStack(spacing: 12) {
                                SummaryCard(
                                    icon: "moon.fill",
                                    title: sleepLogViewModel.sleepQuality != 0 ? "\(sleepLogViewModel.sleepQuality)%" : "Updating...",
                                    subtitle: "Sleep Quality"
                                )
                                SummaryCard(
                                    icon: "flame.fill",
                                    title: "\(sleepLogViewModel.streakDays) nights",
                                    subtitle: "Streak"
                                )
                            }
                            
                            // last sleep
                            if let sleep = sleepLogViewModel.getLastSleep() {
                                VStack(spacing: 8) {
                                    Text("Last Sleep: \(sleep.duration)")
                                        .font(.h2Semi)
                                        .foregroundColor(.white100)
                                    
                                    Text("\(sleep.start) to \(sleep.end) - \(sleep.date)")
                                        .font(.body3)
                                        .foregroundColor(.white80)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(Color.main80)
                                .cornerRadius(12)
                            }
                        }
                        
                        
                        // MARK: - Sleep Debt Progress
                        SleepDebtProgressView(
                            progress: debtProgress,
                            sleepDebt: sleepLogViewModel.sleepDebt
                        )
                        
                        // 📋 activities
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Activities")
                                    .font(.h3Semi)
                                    .foregroundColor(.white100)
                                
                                NavigationLink(destination: LogActivityView()) {
                                    SecondaryButton(
                                        title: "Log Activity",
                                        icon: Image("plus"),
                                        size: .small,
                                        isDisabled: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            VStack(spacing: 4) {
                                ForEach(activityViewModel.activities) { activity in
                                    ActivityRow(activity: activity, onDelete: {
                                        Task {
                                            await activityViewModel.deleteActivity(activity)
                                        }
                                    })
                                }
                            }
                        }
                        
                        // 💡 recommendations
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Sleep Recommendations")
                                .font(.h3Semi)
                            
                            if sleepLogViewModel.recommendations.isEmpty {
                                Text("No recommendations yet. Start wind down and sleep to see recommendations!")
                                    .multilineTextAlignment(.center)
                                    .font(.body2)
                                    .foregroundColor(.white80)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(sleepLogViewModel.recommendations, id: \.self) { rec in
                                        Text("• \(rec)")
                                            .font(.body2)
                                            .foregroundColor(.white80)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                
                NavigationLink(destination: WindDownView()) {
                    PrimaryButton(
                        title: windDown.isActive ? "Continue Wind Down" : "Start Wind Down",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    windDown.isActive = true
                })
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
        .task {
            await activityViewModel.loadActivities()
            await sleepLogViewModel.loadSleepLogs()
            // 💤 Load clips for the most recent sleep log (if available)
            if let latestLog = sleepLogViewModel.sleepLogs.first {
                if let id = latestLog.id  {
                    await sleepClipViewModel.loadClips(for: id)
                }
            }
            
            sleepLogViewModel.recalcStats(userAge: userProfileViewModel.profile?.age)
            
            if let s = userSettingsViewModel.settings, !windDown.isActive {
                windDown.targetBedtime  = WindDownManager.dateFromMinutes(s.bedtime)
                windDown.targetWakeup   = WindDownManager.dateFromMinutes(s.wakeUpTime)
                windDown.trackSleep     = s.trackSleep
                windDown.restrictApps   = s.restrictApps
            }
            
            if let age = userProfileViewModel.profile?.age {
                sleepLogViewModel.startListeningForSleepLogs(userAge: age)
            } else {
                sleepLogViewModel.startListeningForSleepLogs(userAge: nil)
            }
        }
        .appBackground()
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
    .environmentObject(SleepClipViewModel())
}




