//
//  HeaderView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var goalsViewModel: DailyGoalsViewModel
    
    var body: some View {
        HStack {
            Image("SleepaholicLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)

            Spacer()

            NavigationLink {
                DailyGoalsView()
            } label: {
                GoalsPill()
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            goalsViewModel.refreshForCurrentDayIfNeeded()
        }
    }
}

private struct GoalsPill: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white10)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "target")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white100)
                )

            Text("Goals")
                .font(.body2Semi)
                .foregroundColor(.white100)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.gradientStart.opacity(0.9), Color.gradientEnd.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white20, lineWidth: 1)
        )
        .shadow(color: Color.main.opacity(0.25), radius: 8, x: 0, y: 6)
    }
}
