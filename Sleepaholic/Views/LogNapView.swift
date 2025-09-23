//
//  LogNapView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogNapView: View {
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(1800)
    
    @State private var showError = false
    @State private var goHome = false
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Nap")
            
            Form {
                DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    var finalEndTime = endTime
                    if finalEndTime <= startTime {
                        // assume nap ended next day
                        finalEndTime = Calendar.current.date(byAdding: .day, value: 1, to: finalEndTime) ?? finalEndTime
                    }
                    
                    guard finalEndTime > startTime else {
                        showError = true
                        return
                    }
                    
                    let newActivity = Activity(
                        type: "nap",
                        loggedAt: finalEndTime,
                        start: startTime,
                        end: finalEndTime
                    )
                    
                    await activityViewModel.addActivity(newActivity)
                    goHome = true
                }
            }) {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .contentShape(Rectangle())
            }
            .alert("End time must be after start time.", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            }
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
        LogNapView()
            .environmentObject(ActivityViewModel())
    }
}
