//
//  ActivitiesView.swift
//  Sleepaholic
//
//  Created by John on 2025-11-08.
//

import SwiftUI

struct ActivitiesView: View {
    @Environment(\.adaptiveVerticalPadding) private var adaptivePadding
    @EnvironmentObject private var activityViewModel: ActivityViewModel

    @State private var selectedDate = Date()

    private var activities: [Activity] {
        activityViewModel.activities
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            dateStrip
            content
        }
        .padding(.horizontal, 24)
        .padding(.vertical, adaptivePadding)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .appBackground()
        .task {
            await activityViewModel.loadActivities(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newValue in
            Task { await activityViewModel.loadActivities(for: newValue) }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Activities")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Text("Log routines & habits to understand their effect on tonight's sleep.")
                    .font(.body3)
                    .foregroundColor(.white70)
            }
            Spacer()
            NavigationLink(destination: LogActivityView()) {
                SecondaryButton(
                    title: "Log",
                    icon: Image("plus"),
                    size: .small,
                    isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var dateStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDate(selectedDate))
                .font(.body1Semi)
                .foregroundColor(.white80)
            DayStripSelector(selectedDate: $selectedDate)
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if activities.isEmpty {
                    VStack(spacing: 12) {
                        Text("No activities yet")
                            .font(.body1Semi)
                            .foregroundColor(.white100)
                        Text("Track caffeine, workouts, naps, alcohol, or medications to see how they impact your sleep.")
                            .multilineTextAlignment(.center)
                            .font(.body3)
                            .foregroundColor(.white70)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color.white10)
                    .cornerRadius(16)
                } else {
                    ForEach(activities) { activity in
                        ActivityRow(activity: activity) {
                            Task { await activityViewModel.deleteActivity(activity) }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ActivitiesView()
            .environmentObject(ActivityViewModel())
    }
    .enableAdaptivePadding()
}
