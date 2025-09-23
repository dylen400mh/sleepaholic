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
    
    @State private var goHome = false
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Alcohol")
            
            Form {
                Stepper("Number of drinks: \(drinks)", value: $drinks, in: 1...20)
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    let newActivity = Activity(
                        type: "alcohol",
                        loggedAt: time,
                        drinks: drinks
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
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
                .environmentObject(WindDownManager())
        }
    }
}


#Preview {
    NavigationStack {
        LogAlcoholView()
            .environmentObject(ActivityViewModel())
    }
}
