//
//  TimePickerSheet.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-21.
//

import SwiftUI

struct TimePickerSheet: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white20)
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            Text(title)
                .font(.h3Semi)
                .foregroundColor(.white100)

            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

            Spacer(minLength: 8)
        }
        .padding(.bottom, 12)
        .background(Color.main)
    }
}
