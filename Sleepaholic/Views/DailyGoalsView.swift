//
//  DailyGoalsView.swift
//  Sleepaholic
//
//  Created by John on 2025-11-28
//

import SwiftUI

struct DailyGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding
    @EnvironmentObject private var goalsViewModel: DailyGoalsViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header
                heroCard
                weeklyStatus
                goalsList
                footerNote
            }
            .padding(.horizontal, 24)
            .padding(.bottom, adaptivePadding)
            .padding(.top, adaptivePadding)
        }
        .background(BackgroundView().edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            goalsViewModel.refreshForCurrentDayIfNeeded()
        }
    }
}

private extension DailyGoalsView {
    var header: some View {
        HStack {
            BackButtonView {
                dismiss()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Today's Sleep Goals")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Text("Resets daily at 2:00pm")
                    .font(.body3)
                    .foregroundColor(.white70)
            }
        }
    }

    var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                ProgressRing(progress: goalsViewModel.progress)
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 8) {
                    Text(goalStatusTitle)
                        .font(.h3Semi)
                        .foregroundStyle(Gradients.main)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(goalStatusSubtitle)
                        .font(.body2)
                        .foregroundColor(.white80)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white5, Color.white10],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white10, lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 14)
    }

    var weeklyStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.body2Semi)
                .foregroundColor(.white80)

            HStack(spacing: 10) {
                ForEach(goalsViewModel.weeklyStatuses) { item in
                    VStack(spacing: 8) {
                        WeeklyStatusDot(status: item.status)
                        Text(item.letter.uppercased())
                            .font(.body3Semi)
                            .foregroundColor(.white70)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    var goalsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap to check off last night")
                .font(.body2Semi)
                .foregroundColor(.white80)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(goalsViewModel.todayGoals) { goal in
                    GoalRow(
                        goal: goal,
                        isComplete: goalsViewModel.completed.contains(goal.id)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            goalsViewModel.toggle(goal)
                        }
                    }
                }
            }
        }
    }

    var footerNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why these goals?")
                .font(.body2Semi)
                .foregroundStyle(Gradients.main)
            Text("Each goal is tied to strong sleep-hygiene research: cooler rooms, consistent bed/wake times, light management, caffeine timing, and pre-bed wind-down habits.")
                .font(.body3)
                .foregroundColor(.white70)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white5)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white10, lineWidth: 1)
        )
        .cornerRadius(14)
    }

    func badgeView(text: String) -> some View {
        Text(text)
            .font(.body3Semi)
            .foregroundColor(.white100)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.main.opacity(0.4))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white20, lineWidth: 1)
                    )
            )
    }

    var goalStatusTitle: String {
        if goalsViewModel.isAllComplete {
            return "All goals complete!"
        } else if goalsViewModel.completed.isEmpty {
            return "Fresh goals are ready"
        } else {
            return "Keep it going"
        }
    }

    var goalStatusSubtitle: String {
        let done = goalsViewModel.completed.count
        let total = max(goalsViewModel.todayGoals.count, 1)
        return "\(done) of \(total) checked off"
    }

    var completionBadgeText: String {
        let percent = Int((goalsViewModel.progress * 100).rounded())
        return "\(percent)% complete"
    }
}

private struct GoalRow: View {
    let goal: DailyGoal
    let isComplete: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isComplete ? Gradients.main : LinearGradient(colors: [Color.white10, Color.white5], startPoint: .top, endPoint: .bottom))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.white20, lineWidth: 1)
                        )

                    Image(systemName: isComplete ? "checkmark" : goal.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white100)
                        .transition(.scale)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title)
                        .font(.body1Semi)
                        .foregroundColor(.white100)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(goal.detail)
                        .font(.body3)
                        .foregroundColor(.white70)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isComplete ? Color.main : Color.white10, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(isComplete ? 0.2 : 0.1), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct WeeklyStatusDot: View {
    let status: DayStatusState

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(borderColor, lineWidth: 1.5)
                .background(
                    Circle()
                        .fill(fillStyle)
                )
                .frame(width: 36, height: 36)

            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(symbolColor)
        }
    }

    private var fillStyle: LinearGradient {
        switch status {
        case .complete:
            return LinearGradient(
                colors: [Color.gradientStart, Color.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .partial:
            return LinearGradient(
                colors: [Color.white10, Color.white10],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .missed:
            return LinearGradient(
                colors: [Color.white5, Color.white5],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .upcoming:
            return LinearGradient(
                colors: [Color.white5.opacity(0.8), Color.white5.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderColor: Color {
        switch status {
        case .complete:
            return Color.main.opacity(0.8)
        case .partial:
            return Color.main.opacity(0.7)
        case .missed:
            return Color.white20
        case .upcoming:
            return Color.white20
        }
    }

    private var symbolName: String {
        switch status {
        case .complete:
            return "checkmark"
        case .partial:
            return "minus"
        case .missed:
            return "xmark"
        case .upcoming:
            return "minus"
        }
    }

    private var symbolColor: Color {
        switch status {
        case .complete:
            return Color.white100
        case .partial:
            return Color.main.opacity(0.9)
        case .missed:
            return Color.appYellow
        case .upcoming:
            return Color.white70
        }
    }
}

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white20, lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Gradients.main,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.body1Semi)
                    .foregroundColor(.white100)
                Text("Done")
                    .font(.body3)
                    .foregroundColor(.white70)
            }
        }
    }
}
