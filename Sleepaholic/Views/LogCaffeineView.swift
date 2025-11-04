//
//  LogCaffeineView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI
import OrderedCollections

struct LogCaffeineView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    @State private var selectedKind = ""
    @State private var customKind = ""
    @State private var amount: String = ""
    @State private var time = Date()
    @State private var goHome = false
    
    let caffeineOptions: OrderedDictionary<String, Int> = [
        "Coffee": 95,
        "Espresso": 63,
        "Energy Drink": 80,
        "Caffeine Pill": 200,
        "Tea": 40,
        "Other": 0
    ]
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Log Caffeine")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }

            // MARK: - Inputs
            VStack(spacing: 24) {
                // Time Input
                StyledDatePicker(label: "Time", date: $time)

                // Caffeine Type Dropdown
                StyledDropdown(
                    label: "What did you have?",
                    options: Array(caffeineOptions.keys),
                    selected: $selectedKind
                )
                .onChange(of: selectedKind) { oldValue, newValue in
                    guard !newValue.isEmpty else {
                        amount = ""
                        return
                    }
                    
                    if let defaultAmount = caffeineOptions[newValue], defaultAmount > 0 {
                        amount = "\(defaultAmount)"
                    } else {
                        amount = ""
                    }
                }
                
                if selectedKind == "Other" {
                    InputField(label: "Description", text: $customKind)
                }

                // Amount Field
                InputField(label: "Amount (mg)", text: $amount, keyboardType: .numberPad)
            }

            Spacer()

            // MARK: - Save Button
            Button {
                Task {
                    await saveCaffeineLog()
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
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
        }
        .appBackground()
        
    }
    
    private var isFormValid: Bool {
        guard !selectedKind.isEmpty else { return false }
        if selectedKind == "Other" && customKind.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        guard Int(amount) ?? 0 > 0 else { return false }
        return true
    }
    
    private func saveCaffeineLog() async {
        guard isFormValid else {
            return
        }

        let kind = selectedKind
        let finalAmount = Int(amount) ?? 0

        let newActivity = Activity(
            type: "caffeine",
            loggedAt: time,
            kind: kind,
            otherDescription: kind == "Other" ? customKind : nil,
            amountMg: finalAmount
        )

        await activityViewModel.addActivity(newActivity)
        goHome = true
    }
}

#Preview {
    NavigationStack {
        LogCaffeineView()
            .environmentObject(ActivityViewModel())
    }
}
