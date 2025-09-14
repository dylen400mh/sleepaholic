//
//  WakeupView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct WakeupView: View {
    var resetToHome: () -> Void
    @State private var manualWakeTime = Date()
    
    var body: some View {
        VStack {
            // Header
            HeaderView {
                // Settings action
            }
            Spacer()
            
            VStack(spacing: 16) {
                Text("Log Wake Up")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Confirm your wake up time")
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 30)
            
            Button("Log Current Time") {
                resetToHome() // 🚀 jump back to home
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 40)
            
            VStack(spacing: 12) {
                Text("Forgot to log? Enter manually")
                    .foregroundColor(.gray)
                
                DatePicker("", selection: $manualWakeTime, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                
                Button("Log Manually") {
                    resetToHome() // 🚀 same behavior
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    WakeupView(resetToHome: {})
}


