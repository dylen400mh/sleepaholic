//
//  LogAlcoholView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogAlcoholView: View {
    @State private var drinks = 1
    @State private var time = Date()
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Alcohol")
            
            Form {
                Stepper("Number of drinks: \(drinks)", value: $drinks, in: 1...20)
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            
            Spacer()
            
            Button("Save") {
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
    LogAlcoholView()
}
