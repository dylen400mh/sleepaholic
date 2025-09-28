//
//  WakeupView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct WakeupView: View {
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject var windDown: WindDownManager
    @State private var manualWakeTime = Date()
    @State private var goHome = false
    
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
            
            Button(action: {
                Task {
                    await sleepLogViewModel.logWakeup(at: Date())
                    windDown.reset()
                    goHome = true
                }
            }) {
                Text("Log Current Time")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            
            VStack(spacing: 12) {
                Text("Forgot to log? Enter manually")
                    .foregroundColor(.gray)
                
                DatePicker("", selection: $manualWakeTime, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                
                Button("Log Manually") {
                    Task {
                        await sleepLogViewModel.logWakeup(at: manualWakeTime)
                        windDown.reset()
                        goHome = true
                    }
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    WakeupView()
        .environmentObject(SleepLogViewModel())
        .environmentObject(WindDownManager())
}


