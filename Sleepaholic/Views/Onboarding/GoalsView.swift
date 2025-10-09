//
//  GoalsView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-09.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var viewModel: GoalsViewModel
    let next: () -> Void
    let previous: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            BackButtonView(previous: previous)
                .padding(.top)

            VStack(spacing: 8) {
                Text("Choose your goals")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Select the goals you wish to track during your sleep journey.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.goals) { goal in
                        Button {
                            HapticsManager.play(.light)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.toggle(goal)
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: goal.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 36, height: 36)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Circle())

                                Text(goal.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)

                                Spacer()

                                if viewModel.isSelected(goal) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 20))
                                        .transition(.scale)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                viewModel.isSelected(goal)
                                ? Color.accentColor.opacity(0.2)
                                : Color(.secondarySystemBackground)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        viewModel.isSelected(goal)
                                        ? Color.accentColor
                                        : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
            }

            Spacer()

            Button {
                HapticsManager.play(.medium)
                next()
            } label: {
                Text("Track these goals")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    GoalsView(next: {}, previous: {})
        .environmentObject(GoalsViewModel())
}
