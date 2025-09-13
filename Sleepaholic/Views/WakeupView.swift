//
//  WakeupView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct WakeupView: View {
    @State private var manualWakeTime = Date()
    
    var body: some View {
        VStack {
            // Header
            HeaderView {
                // Settings action
            }
            
            Spacer()
            
            // Main text
            VStack(spacing: 16) {
                Text("Log Wake Up")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Confirm your wake up time")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 30)
            
            // Primary action button
            Button(action: {
                // Log current time action
            }) {
                Text("Log Current Time")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
            
            // Manual entry section
            VStack(spacing: 12) {
                Text("Forgot to log? Enter manually")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                DatePicker(
                    "",
                    selection: $manualWakeTime,
                    displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                
                Button(action: {
                    // Log manual time action
                }) {
                    Text("Log Manually")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    WakeupView()
}
