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
            
            Button("Save") {
                let finalType = selectedType == "Other" ? otherDescription : selectedType
                print("Saved Workout: \(finalType), \(duration) min at \(time)")
                // TODO: Save activity
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    LogWorkoutView()
}
