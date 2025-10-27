//
//  ScheduleRow.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-26.
//

import SwiftUI

import SwiftUI

struct ScheduleRow: View {
    let label: String
    @Binding var date: Date
    
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(label)
                        .font(.body1)
                        .foregroundColor(.white70)
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.body1Semi)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            VStack {
                DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            }
            .presentationDetents([.height(300), .medium])
            .presentationCornerRadius(24)
        }
    }
}
