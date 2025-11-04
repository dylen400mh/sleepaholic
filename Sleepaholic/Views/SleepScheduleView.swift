//
//  SleepScheduleView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-26.
//

import SwiftUI

struct SleepScheduleView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var windDown: WindDownManager
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    
    @State private var bedtime = Date()
    @State private var wakeTime = Date()
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Sleep Schedule")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            // MARK: - Form
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    ScheduleRow(label: "Target Bedtime", date: $bedtime)
                    SettingsSeparator()
                    ScheduleRow(label: "Target Wake-Up Time", date: $wakeTime)
                }
            }
        }
        .padding(.vertical, adaptivePadding)
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .appBackground()
        .task {
            // Load existing settings from Firestore
            await userSettingsViewModel.loadSettings()
            if let settings = userSettingsViewModel.settings {
                bedtime = WindDownManager.dateFromMinutes(settings.bedtime)
                wakeTime = WindDownManager.dateFromMinutes(settings.wakeUpTime)
            } else {
                // fallback to manager defaults
                bedtime = windDown.targetBedtime
                wakeTime = windDown.targetWakeup
            }
        }
        .onChange(of: bedtime) { _, newValue in
            Task { await handleTimeChange(bedtime: newValue, wake: wakeTime) }
        }
        .onChange(of: wakeTime) { _, newValue in
            Task { await handleTimeChange(bedtime: bedtime, wake: newValue) }
        }
    }
    
    // MARK: - Logic
    private func handleTimeChange(bedtime: Date, wake: Date) async {
        guard var settings = userSettingsViewModel.settings else { return }
        
        // Update WindDownManager (this automatically reschedules notifications)
        windDown.targetBedtime = bedtime
        windDown.targetWakeup = wake
        
        // Update only bedtime / wakeup values
        settings.bedtime = WindDownManager.minutesFromDate(bedtime)
        settings.wakeUpTime = WindDownManager.minutesFromDate(wake)
            
        // Persist changes
        await userSettingsViewModel.saveSettings(settings)
        
        print("Updated bedtime and wake-up time, rescheduled notifications.")
    }
}

#Preview {
    NavigationStack {
        SleepScheduleView()
    }
}

