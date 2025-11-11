//
//  LogAlcoholView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogAlcoholView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    @State private var drinks = ""
    @State private var time = Date()
    
    private let tabBarClearance: CGFloat = 36
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Log Alcohol")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            VStack(spacing: 24) {
                StyledDatePicker(label: "Time", date: $time)
                
                InputField(
                    label: "Number of Drinks",
                    text: $drinks,
                    keyboardType: .numberPad
                )
            }
            
            Spacer()
            
            // MARK: - Save Button
            Button {
                Task {
                    await saveAlcoholLog()
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
        .padding(.bottom, tabBarClearance)
        .padding(.vertical, adaptivePadding)
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .appBackground()
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        guard Int(drinks) ?? 0 > 0 else { return false }
        return true
    }

    // MARK: - Save Logic
    private func saveAlcoholLog() async {
        guard isFormValid else {
            return
        }

        let drinkCount = Int(drinks) ?? 0
        let newActivity = Activity(
            type: "alcohol",
            loggedAt: time,
            drinks: drinkCount
        )

        await activityViewModel.addActivity(newActivity)
        await MainActor.run {
            dismiss()
        }
    }
}


#Preview {
    NavigationStack {
        LogAlcoholView()
            .environmentObject(ActivityViewModel())
    }
}
