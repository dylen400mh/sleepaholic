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

    private var session: UnifiedSleepSession? {
        let clips = sleepClipViewModel.clips
        return sleepLogViewModel.buildUnifiedSession(for: selectedDate, clips: clips)
    }

    private var durationText: String {
        guard let session = session else { return "--" }
        
        // Prefer Apple Health segments
        if let segments = session.healthSegments, !segments.isEmpty {
            let total = segments.reduce(0) { $0 + $1.duration }
            return formatDuration(total)
        }

        // Fallback to manual
        if let log = session.manualLog, let end = log.end {
            let total = end.timeIntervalSince(log.start)
            return formatDuration(total)
        }

        return "--"
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
    
    private var sleepScoreText: String {
        guard let session = session else { return "--" }

        // Apple Health sleep score (HK only)
        if let segments = session.healthSegments, !segments.isEmpty {
            return calculateSleepScore(from: segments)
        }

        // Manual logs have no sleep staging → no score
        return "--"
    }

    private func calculateSleepScore(from segments: [SleepSegment]) -> String {
        let total = segments.reduce(0) { $0 + $1.duration }
        if total == 0 { return "--" }

        let deep = segments.filter { $0.stage == .deep }.reduce(0) { $0 + $1.duration }
        let rem = segments.filter { $0.stage == .rem }.reduce(0) { $0 + $1.duration }

        let score = Int(((deep + rem) / total) * 100)
        return "\(score)"
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
                value: sleepScoreText,
                subtitle: session?.healthSegments?.isEmpty == false
                ? "Based on Apple Health"
                : "Requires Apple Health"
            )

            InsightsMetricCard(
                title: "Time Asleep",
                value: durationText,
                subtitle: session == nil
                ? "No data"
                : session?.healthSegments?.isEmpty == false
                    ? "Apple Health Data"
                    : "Sleepaholic Log"
            )
        }
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timeline")
                .font(.h3Semi)
                .foregroundColor(.white100)

            if let session = session {

                // Prefer Apple Health in-bed timeline
                if let segments = session.healthSegments, !segments.isEmpty {
                    let start = segments.first!.start
                    let end = segments.last!.end

                    timelineBox(start: start, end: end, source: "Apple Health")

                // Fallback to manual log
                } else if let log = session.manualLog, let end = log.end {
                    timelineBox(start: log.start, end: end, source: "Sleepaholic")
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
    }
    
    @ViewBuilder
    private func timelineBox(start: Date, end: Date, source: String) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bedtime")
                    .font(.body2)
                    .foregroundColor(.white70)
                Text(start.formatted(date: .omitted, time: .shortened))
                    .font(.body1Semi)
                    .foregroundColor(.white100)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Wake")
                    .font(.body2)
                    .foregroundColor(.white70)
                Text(end.formatted(date: .omitted, time: .shortened))
                    .font(.body1Semi)
                    .foregroundColor(.white100)
            }

            Spacer()

            Text(source)
                .font(.caption)
                .foregroundColor(.white70)
        }
        .padding()
        .background(Color.white5)
        .cornerRadius(16)
    }

    private var recordingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Recordings")
                .font(.h3Semi)
                .foregroundColor(.white100)

            if let session = session,
               let _ = session.manualLog,
               !session.clips.isEmpty {
                VStack(spacing: 12) {
                    ForEach(session.clips) { clip in
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
        guard let session = session else {
            sleepClipViewModel.clips = []
            return
        }
        
        // Only manual logs have Firestore IDs for clips
        guard let manual = session.manualLog,
              let id = manual.id else {
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
