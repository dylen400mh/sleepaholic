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
            
            VStack(spacing: 16) {
                Text("Select the activity you wish to log:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
                
                NavigationLink(destination: LogCaffeineView()) {
                    Text("☕️ Caffeine").activityButtonStyle()
                }
                NavigationLink(destination: LogWorkoutView()) {
                    Text("🏋️‍♂️ Workout").activityButtonStyle()
                }
                NavigationLink(destination: LogAlcoholView()) {
                    Text("🍷 Alcohol").activityButtonStyle()
                }
                NavigationLink(destination: LogMedicationView()) {
                    Text("💊 Medication").activityButtonStyle()
                }
                NavigationLink(destination: LogNapView()) {
                    Text("😴 Nap").activityButtonStyle()
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Reusable style
extension Text {
    func activityButtonStyle() -> some View {
        self.font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        LogActivityView()
    }
}
