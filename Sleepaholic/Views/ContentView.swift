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
    
    @State private var lastSleep: FormattedSleep?

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
        let maxDebtMinutes = 14 * 60
        return min(CGFloat(totalMinutes) / CGFloat(maxDebtMinutes), 1.0)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                HeaderView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                SummaryCard(
                                    icon: "flame.fill",
                                    title: "\(sleepLogViewModel.streakDays) nights",
                                    subtitle: "Streak"
                                )
                            }
                            
                            if let sleep = lastSleep {
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
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Activities")
                                    .font(.h3Semi)
                                    .foregroundColor(.white100)
                                
                                Spacer()
                                
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
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Smart Sleep Insights")
                                .font(.h3Semi)
                                .foregroundStyle(Gradients.main)
                            
                            if sleepLogViewModel.recommendations.isEmpty {
                                Text("No recommendations yet. Start wind down and sleep to see recommendations!")
                                    .multilineTextAlignment(.center)
                                    .font(.body2)
                                    .foregroundColor(.white80)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(sleepLogViewModel.recommendations, id: \.self) { rec in
                                        RecommendationRow(recommendation: rec)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Button {
                    Task {
                        await sleepLogViewModel.startBedtime()
                    }
                } label: {
                    PrimaryButton(
                        title: "Start Bedtime",
                        icon: nil,
                        size: .regular,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 24)
        .task {
            await activityViewModel.loadActivities()
            await sleepLogViewModel.loadSleepLogs()
            
            lastSleep = await sleepLogViewModel.getLastSleep()
            
            await sleepLogViewModel.recalcStats(userAge: userProfileViewModel.profile?.age)
            
            if let age = userProfileViewModel.profile?.age {
                sleepLogViewModel.startListeningForSleepLogs(userAge: age)
            } else {
                sleepLogViewModel.startListeningForSleepLogs(userAge: nil)
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
    .environmentObject(SleepClipViewModel())
}
