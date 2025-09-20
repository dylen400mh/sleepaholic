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
            
            Button("Save") {
                let finalKind = selectedKind == "Other" ? customKind : selectedKind
                let finalAmount = Int(amount) ?? 0
                print("Saved Caffeine: \(finalKind), \(finalAmount)mg at \(time)")
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
        .onAppear {
            // Pre-populate when view first loads
            if let defaultAmount = caffeineOptions[selectedKind] {
                amount = "\(defaultAmount)"
            }
        }
    }
}

#Preview {
    LogCaffeineView()
}
