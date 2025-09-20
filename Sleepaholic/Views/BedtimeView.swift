//
//  BedtimeView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct BedtimeView: View {
    var body: some View {
        VStack {
            // Header
            HeaderView {
            }
            Spacer()
            // Main text
            VStack(spacing: 16) {
                Text("Bedtime in progress")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your phone is restricted until you wake up")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Text("Grayscale • Do Not Disturb • Low Brightness • Non-Essential Apps Disabled")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            NavigationLink {
                WakeupView()
            } label: {
                Text("Log Wake Up")
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
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        BedtimeView()
    }
}



