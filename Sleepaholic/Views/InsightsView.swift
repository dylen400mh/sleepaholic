//
//  InsightsView.swift
//  Sleepaholic
//
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject private var sleepClipViewModel: SleepClipViewModel

    @State private var selectedDate = Date()

    private var selectedLog: SleepLog? {
        let calendar = Calendar.current
        return sleepLogViewModel.sleepLogs.first { log in
            if let end = log.end {
                return calendar.isDate(end, inSameDayAs: selectedDate)
            }
            return calendar.isDate(log.start, inSameDayAs: selectedDate)
        }
    }

    private var durationText: String {
        guard let log = selectedLog, let end = log.end else { return "--" }
        let duration = end.timeIntervalSince(log.start)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            dateStrip
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    metricsGrid
                    timelineCard
                    recordingsCard
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await loadClipsIfNeeded()
        }
        .onChange(of: selectedDate) { _, _ in
            Task { await loadClipsIfNeeded() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.body1Semi)
                    .foregroundColor(.white80)
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.h2Semi)
                    .foregroundColor(.white100)
            }
            Spacer()
            Button {
                // placeholder action for future trends page
            } label: {
                Text("Trends")
                    .font(.body2Semi)
                    .foregroundStyle(Gradients.main)
            }
            .buttonStyle(.plain)
        }
    }

    private var dateStrip: some View {
        DayStripSelector(selectedDate: $selectedDate)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            InsightsMetricCard(
                title: "Sleep Score",
                value: selectedLog?.sleepQuality.map { "\($0)" } ?? "--",
                subtitle: "/100"
            )

            InsightsMetricCard(
                title: "Time Asleep",
                value: durationText,
                subtitle: selectedLog == nil ? "Log sleep to unlock" : "Calculated from your sleep session"
            )
        }
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timeline")
                .font(.h3Semi)
                .foregroundColor(.white100)

            if let log = selectedLog {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bedtime")
                            .font(.body2)
                            .foregroundColor(.white70)
                        Text(log.start.formatted(date: .omitted, time: .shortened))
                            .font(.body1Semi)
                            .foregroundColor(.white100)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wake")
                            .font(.body2)
                            .foregroundColor(.white70)
                        Text(log.end?.formatted(date: .omitted, time: .shortened) ?? "--")
                            .font(.body1Semi)
                            .foregroundColor(.white100)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white5)
                .cornerRadius(16)
            } else {
                Text("No sleep recorded for this day yet.")
                    .font(.body3)
                    .foregroundColor(.white70)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white5)
                    .cornerRadius(16)
            }
        }
    }

    private var recordingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Recordings")
                .font(.h3Semi)
                .foregroundColor(.white100)

            if let log = selectedLog, log.id != nil, !sleepClipViewModel.clips.isEmpty {
                VStack(spacing: 12) {
                    ForEach(sleepClipViewModel.clips) { clip in
                        HStack {
                            Image(systemName: "waveform")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white80)
                                .padding(12)
                                .background(Circle().fill(Color.white5))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recording")
                                    .font(.body1Semi)
                                    .foregroundColor(.white100)
                                Text("Tap to play")
                                    .font(.body3)
                                    .foregroundColor(.white70)
                            }

                            Spacer()

                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white100)
                        }
                        .padding()
                        .background(Color.white10)
                        .cornerRadius(16)
                    }
                }
            } else {
                Text("Recordings captured during sleep will appear here for review.")
                    .font(.body3)
                    .foregroundColor(.white70)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white5)
                    .cornerRadius(16)
            }
        }
    }

    private func loadClipsIfNeeded() async {
        guard let log = selectedLog, let id = log.id else {
            sleepClipViewModel.clips = []
            return
        }
        await sleepClipViewModel.loadClips(for: id)
    }
}

private struct InsightsMetricCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body2)
                .foregroundColor(.white70)
            Text(value)
                .font(.h2Semi)
                .foregroundColor(.white100)
            Text(subtitle)
                .font(.body3)
                .foregroundColor(.white70)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white10)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        InsightsView()
            .environmentObject(SleepLogViewModel())
            .environmentObject(SleepClipViewModel())
    }
}
