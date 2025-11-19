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

    private var healthSegmentsForDay: [SleepSegment] {
        sleepLogViewModel.fetchedHealthSegments
    }

    private var manualLogForDay: SleepLog? {
        sleepLogViewModel.sleepLogs.first { log in
            guard let end = log.end else { return false }
            return Calendar.current.isDate(end, inSameDayAs: selectedDate)
        }
    }
    
    // MARK: - Metric strings

    private var sleepScoreText: String {
        guard !healthSegmentsForDay.isEmpty else { return "--" }
        let score = sleepLogViewModel.computeSleepScore(from: healthSegmentsForDay)
        return "\(score)"
    }

    private var timeInBedText: String {
        if !healthSegmentsForDay.isEmpty {
            let start = healthSegmentsForDay.first!.start
            let end   = healthSegmentsForDay.last!.end
            return sleepLogViewModel.formatDuration(end.timeIntervalSince(start))
        }
        if let log = manualLogForDay, let end = log.end {
            return sleepLogViewModel.formatDuration(end.timeIntervalSince(log.start))
        }
        return "--"
    }

    private var timeAsleepText: String {
        guard !healthSegmentsForDay.isEmpty else { return "--" }
        let asleep = sleepLogViewModel.computeTimeAsleep(from: healthSegmentsForDay)
        return sleepLogViewModel.formatDuration(asleep)
    }

    private var hasHealthData: Bool {
        !healthSegmentsForDay.isEmpty
    }

    private var hasManualData: Bool {
        manualLogForDay != nil
    }
    
    private var healthAuthorized: Bool {
        HealthKitManager.shared.isAuthorized()
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
                subtitle: hasHealthData
                ? "Based on Apple Health"
                : healthAuthorized
                    ? "No Apple Health data for this night"
                    : "Enable Apple Health to view"
            )
            
            
            
            InsightsMetricCard(
                title: "Time in Bed",
                value: timeInBedText,
                subtitle: hasHealthData
                    ? "Based on Apple Health"
                    :  hasManualData
                        ? "Based on Sleepaholic Log"
                        : "No Data"
            )

            InsightsMetricCard(
                title: "Time Asleep",
                value: timeAsleepText,
                subtitle: hasHealthData
                ? "Based on Apple Health"
                : healthAuthorized
                    ? "No Apple Health data for this night"
                    : "Enable Apple Health to view"
            )
        }
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timeline")
                .font(.h3Semi)
                .foregroundColor(.white100)

            if hasHealthData {
                let start = healthSegmentsForDay.first!.start
                let end   = healthSegmentsForDay.last!.end
                timelineBox(start: start, end: end, source: "From Apple Health")
            } else if let log = manualLogForDay, let end = log.end {
                timelineBox(start: log.start, end: end, source: "From Sleepaholic")
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
                Text("Wake-Up")
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

            let stageSegments = healthSegmentsForDay.filter { $0.stage != .inBed }
            if !stageSegments.isEmpty {
                VStack(spacing: 20) {
                    sleepStagesStepChart(stageSegments)
                    sleepStageTimeLabels(stageSegments)
                    sleepStagesLegendHorizontal(stageSegments)
                }
                .padding(16)
                .background(Color.white5)
                .cornerRadius(16)
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
            } else if healthAuthorized {
                Text("No sleep stage data available for this night.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body3)
                    .foregroundColor(.white70)
                    .padding(16)
                    .background(Color.white5)
                    .cornerRadius(16)
            } else {
                Text("Enable Apple Health to view sleep stages.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body3)
                    .foregroundColor(.white70)
                    .padding(16)
                    .background(Color.white5)
                    .cornerRadius(16)
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

            if hasManualData, !sleepClipViewModel.clips.isEmpty {
                VStack(spacing: 12) {
                    ForEach(sleepClipViewModel.clips) { clip in
                        SleepClipPlayer(clip: clip)
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
        guard let log = manualLogForDay, let id = log.id else {
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
