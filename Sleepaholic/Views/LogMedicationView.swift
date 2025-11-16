//
//  LogMedicationView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogMedicationView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var time = Date()
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Log Medication")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            // MARK: - Inputs
            VStack(spacing: 24) {
                StyledDatePicker(label: "Time", date: $time)

                InputField(
                    label: "What did you have?",
                    text: $name
                )

                InputField(
                    label: "Amount (mg)",
                    text: $dosage,
                    keyboardType: .numberPad
                )
            }

            Spacer()
            
            // MARK: - Save Button
            Button {
                Task {
                    await saveMedicationLog()
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
        .padding(.vertical, adaptivePadding)
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .appBackground()
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard Int(dosage) ?? 0 > 0 else { return false }
        return true
    }

    // MARK: - Save Logic
    private func saveMedicationLog() async {
        let finalDosage = Int(dosage) ?? 0
        let newActivity = Activity(
            type: "medication",
            loggedAt: time,
            amountMg: finalDosage,
            medication: name
        )

        await activityViewModel.addActivity(newActivity)
        await MainActor.run {
            dismiss()
        }
    }
}



#Preview {
    NavigationStack {
        LogMedicationView()
            .environmentObject(ActivityViewModel())
    }
}
