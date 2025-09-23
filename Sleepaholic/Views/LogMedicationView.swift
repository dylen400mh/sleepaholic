//
//  LogMedicationView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogMedicationView: View {
    @State private var name = ""
    @State private var dosage = ""
    @State private var time = Date()
    
    @State private var showError = false
    @State private var goHome = false
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Medication")
            
            Form {
                TextField("What did you have?", text: $name)
                
                HStack {
                    Text("Dosage (mg)")
                    Spacer()
                    TextField("0", text: $dosage)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        showError = true
                        return
                    }
                    guard let finalDosage = Int(dosage), finalDosage > 0 else {
                        showError = true
                        return
                    }
                    
                    let newActivity = Activity(
                        type: "medication",
                        loggedAt: time,
                        amountMg: finalDosage,
                        medication: name
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
        }
    }
}



#Preview {
    NavigationStack {
        LogMedicationView()
            .environmentObject(ActivityViewModel())
    }
}
