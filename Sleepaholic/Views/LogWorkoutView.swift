//
//  LogWorkoutView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    @State private var selectedType = "Strength"
    @State private var otherDescription = ""
    @State private var duration = ""
    @State private var time = Date()
    @State private var goHome = false
    @State private var showError = false
    
    let workoutOptions = ["Strength", "Cardio", "Other"]
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Log Workout")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            // MARK: - Inputs
            VStack(spacing: 24) {
                // Time Picker
                StyledDatePicker(label: "Time", date: $time)

                // Workout Type Dropdown
                StyledDropdown(
                    label: "Type",
                    options: workoutOptions,
                    selected: $selectedType
                )

                // Custom description if “Other”
                if selectedType == "Other" {
                    InputField(label: "What was your workout?", text: $otherDescription)
                }

                // Duration input
                InputField(
                    label: "Duration (min)",
                    text: $duration,
                    keyboardType: .numberPad
                )
            }

            Spacer()
            
            // MARK: - Save Button
            Button {
                Task {
                    await saveWorkoutLog()
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
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
        }
        .alert("Please fill in all fields.", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        }
        .appBackground()
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        guard !selectedType.isEmpty else { return false }
        if selectedType == "Other" && otherDescription.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        guard Int(duration) ?? 0 > 0 else { return false }
        return true
    }

    // MARK: - Save Logic
    private func saveWorkoutLog() async {
        guard isFormValid else {
            showError = true
            return
        }

        let finalDuration = Int(duration) ?? 0
        let newActivity = Activity(
            type: "workout",
            loggedAt: time,
            kind: selectedType,
            otherDescription: selectedType == "Other" ? otherDescription : nil,
            durationMin: finalDuration
        )

        await activityViewModel.addActivity(newActivity)
        goHome = true
    }
}


#Preview {
    NavigationStack {
        LogWorkoutView()
            .environmentObject(ActivityViewModel())
    }
}
