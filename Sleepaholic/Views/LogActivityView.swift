//
//  LogActivityView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogActivityView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(8)
                }
                Spacer()
                Text("Log Activity")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                // placeholder to balance spacing
                Spacer()
                    .frame(width: 32)
            }
            .padding()
            
            Spacer()
            
            // Buttons for activity types
            VStack(spacing: 16) {
                Button("☕️ Caffeine") {
                    // Handle caffeine logging
                }
                .activityButtonStyle()
                
                Button("🏋️‍♂️ Workout") {
                    // Handle workout logging
                }
                .activityButtonStyle()
                
                Button("🍷 Alcohol") {
                    // Handle alcohol logging
                }
                .activityButtonStyle()
                
                Button("💊 Medication") {
                    // Handle medication logging
                }
                .activityButtonStyle()
                
                Button("😴 Nap") {
                    // Handle nap logging
                }
                .activityButtonStyle()
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Reusable style
extension Button {
    func activityButtonStyle() -> some View {
        self.font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
    }
}

#Preview {
    LogActivityView()
}
