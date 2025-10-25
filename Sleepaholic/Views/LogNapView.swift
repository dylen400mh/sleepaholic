//
//  LogNapView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogNapView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(1800)
    @State private var goHome = false
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Log Nap")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            // MARK: - Inputs
            VStack(spacing: 24) {
                StyledDatePicker(label: "Start Time", date: $startTime)
                StyledDatePicker(label: "End Time", date: $endTime)
            }
            
            Spacer()
            
            // MARK: - Save Button
            Button {
                Task {
                    await saveNapLog()
                }
            } label: {
                PrimaryButton(
                    title: "Save",
                    icon: nil,
                    size: .regular,
                    isDisabled: !isFormValid
                )
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
        }
        .appBackground()
    }
    
    // MARK: - Validation
   private var isFormValid: Bool {
       true
   }

   // MARK: - Save Logic
   private func saveNapLog() async {
       var finalStartTime = startTime
       let finalEndTime = endTime
       
       // If start time appears after end time (crossing midnight),
       // assume the nap started on the previous day.
       if finalStartTime > finalEndTime {
           finalStartTime = Calendar.current.date(byAdding: .day, value: -1, to: finalStartTime) ?? finalStartTime
       }

       let newActivity = Activity(
           type: "nap",
           loggedAt: finalEndTime,
           start: finalStartTime,
           end: finalEndTime
       )

       await activityViewModel.addActivity(newActivity)
       goHome = true
   }
}


#Preview {
    NavigationStack {
        LogNapView()
            .environmentObject(ActivityViewModel())
    }
}
