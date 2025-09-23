//
//  LogWorkoutView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogWorkoutView: View {
    @State private var selectedType = "Strength"
    @State private var otherDescription = ""
    @State private var duration = 30
    @State private var time = Date()
    
    @State private var goHome = false
    @State private var showError = false
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    let workoutOptions = ["Strength", "Cardio", "Other"]
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Workout")
            
            Form {
                // Picker for workout type
                Picker("Type", selection: $selectedType) {
                    ForEach(workoutOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                
                // If "Other", show custom text field
                if selectedType == "Other" {
                    TextField("What was your workout?", text: $otherDescription)
                }
                
                Stepper("Duration: \(duration) min", value: $duration, in: 5...180, step: 5)
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    if selectedType == "Other" {
                        guard !otherDescription.trimmingCharacters(in: .whitespaces).isEmpty else {
                            showError = true
                            return
                        }
                    }
                    
                    guard duration > 0 else {
                        showError = true
                        return
                    }
                    
                    let newActivity = Activity(
                        type: "workout",
                        loggedAt: time,
                        kind: selectedType,
                        otherDescription: selectedType == "Other" ? otherDescription : nil,
                        durationMin: duration
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
            .alert("Please fill in all fields.", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
                .environmentObject(WindDownManager())
        }
    }
}


#Preview {
    NavigationStack {
        LogWorkoutView()
            .environmentObject(ActivityViewModel())
    }
}
