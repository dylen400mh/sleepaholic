//
//  ContentView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct ContentView: View {
    // Example placeholder values
    @State private var streakDays = 5
    @State private var lastSleep = "11:00 PM → 7:00 AM (8h)"
    @State private var sleepDebt = "6h 30m"
    @State private var recommendation = "Try going to bed 30 minutes earlier tonight."
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Sleepaholic")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // Settings action
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                }
            }
            .padding()
            
            Spacer()
            
            // Streak
            HStack {
                Text("🔥 \(streakDays) day streak")
                    .font(.headline)
            }
            
            // Last sleep
            Text("Last sleep: \(lastSleep)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            Spacer()
            
            // Circular progress bar with sleep debt inside
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0.0, to: 0.7) // Placeholder progress
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("Your sleep debt is:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(sleepDebt)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding(.top, 20)
            
            // Recommendation
            Text(recommendation)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal)
            
            Spacer()
            
            // Bedtime button
            Button(action: {
                // Start bedtime action
            }) {
                Text("Start Bedtime")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
    }
}

#Preview {
    ContentView()
}

