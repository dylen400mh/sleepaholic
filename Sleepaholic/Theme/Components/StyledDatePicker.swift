//
//  StyledDatePicker.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-24.
//

import SwiftUI

struct StyledDatePicker: View {
    let label: String
    @Binding var date: Date
    @State private var showPicker = false
    @State private var isFocused = false

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.main)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isFocused ? Color.white100 : Color.white50, lineWidth: isFocused ? 1.5 : 1)
                        .animation(.easeInOut(duration: 0.25), value: isFocused)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticsManager.play(.light)
                withAnimation { isFocused = true }
                showPicker = true
            }
            
            Text(label)
                .font(.body3)
                .foregroundColor(isFocused ? .white100 : .white70)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.main)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isFocused ? Color.white100 : Color.white50, lineWidth: 1)
                        )
                )
                .offset(x: 16, y: -28)
                .animation(.easeInOut(duration: 0.25), value: isFocused)
        }
        .frame(height: 56)
        .sheet(isPresented: $showPicker, onDismiss: {
            withAnimation { isFocused = false }
        }) {
            VStack {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }
            .presentationDetents([.height(300), .medium])
            .presentationCornerRadius(24)
        }
    }
}

