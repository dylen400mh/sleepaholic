//
//  DayStripSelector.swift
//  Sleepaholic
//
//  Created by John on 2025-11-08.
//

import SwiftUI

struct DayStripSelector: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let isFuture = day > Date()

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        selectedDate = day
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(Self.dayFormatter.string(from: day))
                            .font(.caption)
                            .foregroundColor(isSelected ? .white100 : .white70)
                        Text(dayLetter(for: day))
                            .font(.body1Semi)
                            .foregroundColor(isSelected ? .white100 : .white70)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.main.opacity(0.25) : Color.white5)
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? Color.main : Color.white10, lineWidth: isSelected ? 2 : 1)
                                    )
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
                .opacity(isFuture ? 0.5 : 1)
            }
        }
    }

    private var weekDates: [Date] {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek)
        }
    }

    private func dayLetter(for date: Date) -> String {
        let symbol = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
        return symbol.prefix(1).uppercased()
    }
}

#Preview {
    DayStripSelectorPreview()
}

private struct DayStripSelectorPreview: View {
    @State private var date = Date()

    var body: some View {
        DayStripSelector(selectedDate: $date)
            .padding()
            .background(Color.background)
    }
}
