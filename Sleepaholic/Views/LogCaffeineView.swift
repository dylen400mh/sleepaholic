//
//  LogCaffeineView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogCaffeineView: View {
    @State private var selectedKind = "Coffee"
    @State private var customKind = ""
    @State private var amount: String = ""
    @State private var time = Date()
    
    let caffeineOptions: [String: Int] = [
        "Coffee": 95,
        "Espresso": 63,
        "Energy Drink": 80,
        "Caffeine Pill": 200,
        "Tea": 40,
        "Other": 0
    ]
    
    @State private var goHome = false
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Caffeine")
            
            Form {
                // Picker
                Picker("What did you have?", selection: $selectedKind) {
                    ForEach(Array(caffeineOptions.keys), id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedKind) { oldValue, newValue in
                    if let defaultAmount = caffeineOptions[newValue], defaultAmount > 0 {
                        amount = "\(defaultAmount)"
                    } else {
                        amount = ""
                    }
                }
                
                if selectedKind == "Other" {
                    TextField("Enter description", text: $customKind)
                }
                
                // Amount (numbers only)
                HStack {
                    Text("Amount (mg)")
                    Spacer()
                    TextField("0", text: $amount)
                        .keyboardType(.numberPad) // numbers only
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    let finalKind = selectedKind
                    let finalOtherDescription = selectedKind == "Other" ? customKind : nil
                    let finalAmount = Int(amount) ?? 0
                    
                    let newActivity = Activity(
                        type: "caffeine",
                        loggedAt: time,
                        kind: finalKind,
                        otherDescription: finalOtherDescription,
                        amountMg: finalAmount
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
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
                .environmentObject(WindDownManager())
        }
        .onAppear {
            // Pre-populate when view first loads
            if let defaultAmount = caffeineOptions[selectedKind] {
                amount = "\(defaultAmount)"
            }
        }
    }
}

#Preview {
    NavigationStack {
        LogCaffeineView()
            .environmentObject(ActivityViewModel())
    }
}
