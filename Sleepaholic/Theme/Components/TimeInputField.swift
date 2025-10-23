//
//  TimeInputField.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-21.
//

import SwiftUI

struct TimeInputField: View {
    let label: String
    @Binding var date: Date
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.main)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white50, lineWidth: 1)
                )
            
            HStack(spacing: 8) {
                Image("clock2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white100)
                
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.body1)
                    .foregroundColor(.white100)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                Spacer()
            }
            .padding(16)
            
            Text(label)
                .font(.body3)
                .foregroundColor(.white70)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                    .fill(Color.main)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white50, lineWidth: 1)
                    )
                )
                .offset(x: 16, y: -28)
        }
        .onTapGesture {
            HapticsManager.play(.light)
            onTap()
        }
    }
}
