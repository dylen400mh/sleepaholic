//
//  InsightsView.swift
//  Sleepaholic
//
//

import SwiftUI

extension TimeInterval {
    func formattedAsHhMm() -> String {
        let h = Int(self / 3600)
        let m = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

extension Date {
    func isYesterday(relativeTo reference: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: reference.addingTimeInterval(-86400))
    }
}

struct InsightsView: View {
    @EnvironmentObject private var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject private var sleepClipViewModel: SleepClipViewModel
    
    @AppStorage("useAppleHealthSleep") private var useAppleHealthSleep = false

    @State private var selectedDate = Date()
    @State private var selectedStage: SleepSegment?

    private var session: UnifiedSleepSession? {
        let clips = sleepClipViewModel.clips
        return sleepLogViewModel.buildUnifiedSession(for: selectedDate, clips: clips)
    }

    private var durationText: String {
        if let seconds = session?.timeAsleep {
            return sleepLogViewModel.formatDuration(seconds)
        }
        return "--"
    }
    
    private var sleepScoreText: String {
        session?.sleepScore.map { "\($0)" } ?? "--"
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            dateStrip
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    metricsGrid
                    timelineCard
                    sleepStagesCard
                    recordingsCard
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await sleepLogViewModel.loadHealthSleep(for: selectedDate)
            await loadClipsIfNeeded()
        }
        .onChange(of: selectedDate) { _, newValue in
            let today = Calendar.current.startOfDay(for: Date())
            let newDay = Calendar.current.startOfDay(for: newValue)

            if newDay > today {
                return
            }
            
            Task {
                await sleepLogViewModel.loadHealthSleep(for: newValue)
                await loadClipsIfNeeded()
            }
        }
        .onTapGesture { selectedStage = nil }
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
                title: "Time in Bed",
                value: session?.timeInBed
                    .map { sleepLogViewModel.formatDuration($0) } ?? "--",
                subtitle: session?.healthSegments?.isEmpty == false
                    ? "Apple Health Data"
                    : "Sleepaholic Log"
            )

            InsightsMetricCard(
                title: "Time Asleep",
                value: durationText,
                subtitle: session == nil
                ? "Unknown"
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
    
    private var sleepStagesCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Sleep Stages")
                .font(.h3Semi)
                .foregroundColor(.white100)

            if let segments = session?.healthSegments?
                .filter({ $0.stage != .inBed }),
               !segments.isEmpty {

                VStack(spacing: 20) {
                    sleepStagesStepChart(segments)
                    sleepStageTimeLabels(segments)
                    sleepStagesLegendHorizontal(segments)
                }
                .padding(16)
                .background(Color.white5)
                .cornerRadius(16)
            } else {
                Text("Enable Apple Health to view sleep stages.")
                    .font(.body3)
                    .foregroundColor(.white70)
                    .padding(16)
                    .background(Color.white5)
                    .cornerRadius(16)
            }
        }
        .overlay(alignment: .center) {
            if let s = selectedStage {
                // Build display strings
                let cal = Calendar.current
                
                let startIsYesterday = s.start.isYesterday(relativeTo: selectedDate)
                let endIsYesterday = s.end.isYesterday(relativeTo: selectedDate)
                let endIsToday = cal.isDate(s.end, inSameDayAs: selectedDate)

                let startDayString = startIsYesterday ? "Yesterday" : "Today"
                let endDayString = endIsYesterday ? "Yesterday" :
                                  endIsToday ? "Today" : startDayString

                let startTime = s.start.formatted(date: .omitted, time: .shortened)
                let endTime = s.end.formatted(date: .omitted, time: .shortened)

                let rangeString =
                    startDayString == endDayString
                    ? "\(startDayString), \(startTime) – \(endTime)"
                    : "\(startDayString), \(startTime) – \(endDayString), \(endTime)"
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(s.stage.name == "Awake" ? s.stage.name : "\(s.stage.name) Sleep")
                        .font(.body1)
                        .foregroundColor(.white100)
                    
                    Text(s.duration.formattedAsHhMm())
                        .font(.body1Semi)
                        .foregroundColor(.white100)

                    // Combined date + time range
                    Text(rangeString)
                        .font(.caption)
                        .foregroundColor(.white70)
                }
                .padding()
                .background(Color.main)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white5, lineWidth: 1)
                )
                .padding()
                .contentShape(Rectangle())
            }
        }
    }
    
    @ViewBuilder
    private func sleepStagesStepChart(_ segments: [SleepSegment]) -> some View {
        let total = segments
            .filter { $0.stage != .inBed }
            .reduce(0) { $0 + $1.duration }

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(segments) { segment in
                    let widthPct = segment.duration / total

                    // x offset based on all previous segments
                    let xOffsetPct = segments.prefix { $0.id != segment.id }
                        .reduce(0.0) { $0 + $1.duration / total }

                    let barHeight: CGFloat = 20
                    let yPos = (1 - segment.stage.depth) * (geo.size.height - barHeight)

                    Rectangle()
                        .fill(segment.stage.color)
                        .frame(
                            width: geo.size.width * widthPct,
                            height: barHeight
                        )
                        .offset(
                            x: geo.size.width * xOffsetPct,
                            y: yPos
                        )
                        .onTapGesture {
                            selectedStage = segment
                        }
                }
            }
        }
        .frame(height: 100)
    }
    
    private func sleepStageTimeLabels(_ segments: [SleepSegment]) -> some View {
        return HStack {
            Text(segments.first!.start.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.white70)

            Spacer()

            Text(segments.last!.end.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.white70)
        }
    }

    private func sleepStagesLegendHorizontal(_ segments: [SleepSegment]) -> some View {
        let stages = segments
            .map { $0.stage }
            .filter { $0 != .inBed }
            .reduce(into: [SleepStage]()) { result, stage in
                if !result.contains(stage) {
                    result.append(stage)
                }
            }
            .sorted { $0.sortOrder < $1.sortOrder }

        return LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 90), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(stages, id: \.self) { stage in
                HStack(spacing: 6) {
                    Circle()
                        .fill(stage.color)
                        .frame(width: 10, height: 10)

                    Text(stage.name)
                        .font(.caption)
                        .foregroundColor(.white80)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 4)
            }
        }
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
        VStack(alignment: .leading) {
            Text(title)
                .font(.body2)
                .foregroundColor(.white70)
            Spacer(minLength: 4)
            Text(value)
                .font(.h2Semi)
                .foregroundColor(.white100)
            Spacer(minLength: 4)
            Text(subtitle)
                .font(.body3)
                .foregroundColor(.white70)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
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
