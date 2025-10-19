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
        VStack(spacing: 48) {
            OnboardingHeader(previous: previous)
            
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Choose your goals")
                        .font(.h2Semi)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Select the goals you wish to track during your sleep journey.")
                        .font(.body2)
                        .foregroundColor(.white80)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.goals) { goal in
                            MultipleChoiceOption(
                                text: goal.title,
                                isSelected: viewModel.isSelected(goal),
                                icon: goal.icon
                            ) {
                                HapticsManager.play(.light)
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.toggle(goal)
                                }
                            }
                        }
                    }
                }
            }

            Button {
                HapticsManager.play(.medium)
                next()
            } label: {
                PrimaryButton(
                    title: "Track These Goals",
                    icon: nil,
                    size: .regular,
                    isDisabled: false
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AnalyticsService.shared.trackEvent(eventName: "goals_viewed")
        }
    }
}

#Preview {
    GoalsView(next: {}, previous: {})
        .environmentObject(GoalsViewModel())
}
