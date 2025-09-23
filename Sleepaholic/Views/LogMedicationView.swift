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
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Medication")
            
            Form {
                TextField("What did you have?", text: $name)
                
                HStack {
                    Text("Dosage (mg)")
                    Spacer()
                    TextField("0", text: $dosage)
                        .keyboardType(.numberPad) // ✅ numbers only
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            
            Spacer()
            
            Button(action: {
                let finalDosage = Int(dosage) ?? 0
                print("Saved Medication: \(name), \(finalDosage)mg at \(time)")
                // TODO: Save activity
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
    }
}



#Preview {
    LogMedicationView()
}
