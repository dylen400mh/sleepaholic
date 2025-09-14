//
//  ContentView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct ContentView: View {
    @State private var streakDays = 5
    @State private var lastSleep = "11:00 PM → 7:00 AM (8h)"
    @State private var sleepDebt = "6h 30m"
    @State private var recommendation = "Try going to bed 30 minutes earlier tonight."
    
    var body: some View {
        VStack {
            // Header
            HeaderView {
            }
            Spacer()
            
            Text("🔥 \(streakDays) day streak")
            Text("Last sleep: \(lastSleep)")
                .foregroundColor(.gray)
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0.0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("Your sleep debt is:")
                        .foregroundColor(.gray)
                    Text(sleepDebt)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding(.top, 20)
            
            Text(recommendation)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(value: Screen.bedtime) {
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
    NavigationStack {
        ContentView()
    }
}




