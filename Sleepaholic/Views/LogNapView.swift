//
//  LogNapView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogNapView: View {
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(1800)
    
    var body: some View {
        VStack {
            FormHeader(title: "Log Nap")
            
            Form {
                DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
            }
            
            Spacer()
            
            Button(action: {
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
    LogNapView()
}
