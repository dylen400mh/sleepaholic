//
//  SleepReflectionModalView.swift
//  Sleepaholic
//
//  Created by Codex on 2025-12-02.
//

import SwiftUI

struct SleepReflectionModalView: View {
    @EnvironmentObject var sleepReflectionViewModel: SleepReflectionViewModel
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    guard !sleepReflectionViewModel.isSaving else { return }
                    sleepReflectionViewModel.closeModal()
                }
            
            VStack(spacing: 20) {
                // Handle + Close
                HStack {
                    Capsule()
                        .fill(Color.white20)
                        .frame(width: 48, height: 5)
                        .padding(.vertical, 12)
                    
                    Spacer()
                    
                    Button {
                        guard !sleepReflectionViewModel.isSaving else { return }
                        HapticsManager.play(.light)
                        sleepReflectionViewModel.closeModal()
                    } label: {
                        Image("x")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .padding(10)
                            .background(Color.white10)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                
                // Progress
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= currentStepIndex ? Color.gradientEnd : Color.white20)
                            .frame(width: 10, height: 10)
                    }
                    
                    Spacer()
                    
                    Text(stepLabel)
                        .font(.body3)
                        .foregroundColor(.white70)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.h2Semi)
                        .foregroundColor(.white100)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.body3)
                            .foregroundColor(.white70)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    optionsView
                }
                .disabled(sleepReflectionViewModel.isSaving)
                .opacity(sleepReflectionViewModel.isSaving ? 0.7 : 1)
                .frame(maxWidth: .infinity)
                
                if let error = sleepReflectionViewModel.errorMessage {
                    Text(error)
                        .font(.body3)
                        .foregroundColor(.appRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
                
                if sleepReflectionViewModel.isSaving {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.white100)
                        Text("Saving your reflection...")
                            .font(.body3)
                            .foregroundColor(.white100)
                    }
                    .padding(.vertical, 4)
                }
                
                Button {
                    HapticsManager.play(.light)
                    sleepReflectionViewModel.skipForToday()
                } label: {
                    Text("Skip for today")
                        .font(.body2Semi)
                        .foregroundColor(.white80)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(sleepReflectionViewModel.isSaving)
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: 640)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.background)
                    .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(LinearGradient(
                                colors: [Color.white10, Color.white5],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.clear)
    }
    
    private var optionsView: some View {
        Group {
            switch sleepReflectionViewModel.currentStep {
            case .sleepQuality:
                VStack(spacing: 12) {
                    ReflectionChoiceButton(
                        label: "Slept great",
                        emoji: "😴",
                        gradient: GradientPalette.mint,
                        action: { sleepReflectionViewModel.selectSleepQuality(.great) }
                    )
                    ReflectionChoiceButton(
                        label: "It was okay",
                        emoji: "😐",
                        gradient: GradientPalette.sunrise,
                        action: { sleepReflectionViewModel.selectSleepQuality(.okay) }
                    )
                    ReflectionChoiceButton(
                        label: "Rough night",
                        emoji: "🥱",
                        gradient: GradientPalette.ember,
                        action: { sleepReflectionViewModel.selectSleepQuality(.rough) }
                    )
                }
            case .morningFeeling:
                VStack(spacing: 12) {
                    ReflectionChoiceButton(
                        label: "Great",
                        emoji: "😄",
                        gradient: GradientPalette.mint,
                        action: { sleepReflectionViewModel.selectMorningFeeling(.great) }
                    )
                    ReflectionChoiceButton(
                        label: "Okay",
                        emoji: "😐",
                        gradient: GradientPalette.sunrise,
                        action: { sleepReflectionViewModel.selectMorningFeeling(.okay) }
                    )
                    ReflectionChoiceButton(
                        label: "Bad",
                        emoji: "🥴",
                        gradient: GradientPalette.ember,
                        action: { sleepReflectionViewModel.selectMorningFeeling(.rough) }
                    )
                }
            case .scheduleConsistency:
                VStack(spacing: 12) {
                    ReflectionChoiceButton(
                        label: "Yes, hit my targets",
                        emoji: "✅",
                        gradient: GradientPalette.mint,
                        action: { sleepReflectionViewModel.selectScheduleConsistency(.onSchedule) }
                    )
                    ReflectionChoiceButton(
                        label: "Off my schedule",
                        emoji: "⏰",
                        gradient: GradientPalette.ember,
                        action: { sleepReflectionViewModel.selectScheduleConsistency(.offSchedule) }
                    )
                }
            }
        }
    }
    
    private var title: String {
        switch sleepReflectionViewModel.currentStep {
        case .sleepQuality:
            return "How was your last night's sleep?"
        case .morningFeeling:
            return "How do you feel this morning?"
        case .scheduleConsistency:
            return "Did you go to bed and wake up on schedule?"
        }
    }
    
    private var subtitle: String? {
        switch sleepReflectionViewModel.currentStep {
        case .sleepQuality:
            return "A quick check helps us tune your recommendations."
        case .morningFeeling:
            return "Tell us your mood so we can spot trends."
        case .scheduleConsistency:
            if let settings = userSettingsViewModel.settings {
                let bedtime = WindDownManager.dateFromMinutes(settings.bedtime).formatted(date: .omitted, time: .shortened)
                let wake = WindDownManager.dateFromMinutes(settings.wakeUpTime).formatted(date: .omitted, time: .shortened)
                return "Target: bed at \(bedtime), wake at \(wake)."
            } else {
                return "Staying close to your targets keeps your rhythm on track."
            }
        }
    }
    
    private var currentStepIndex: Int {
        switch sleepReflectionViewModel.currentStep {
        case .sleepQuality: return 0
        case .morningFeeling: return 1
        case .scheduleConsistency: return 2
        }
    }
    
    private var stepLabel: String {
        "Step \(currentStepIndex + 1) of 3"
    }
}

// MARK: - Subviews
private struct ReflectionChoiceButton: View {
    let label: String
    let emoji: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button {
            HapticsManager.play(.light)
            action()
        } label: {
            HStack {
                Text(emoji)
                    .font(.system(size: 32))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.body1Semi)
                    .foregroundColor(.white100)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Palette
private enum GradientPalette {
    static let mint = LinearGradient(
        colors: [Color.appGreen, Color.gradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let sunrise = LinearGradient(
        colors: [Color.appYellow, Color.main],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let ember = LinearGradient(
        colors: [Color.appRed, Color.main],
        startPoint: .leading,
        endPoint: .trailing
    )
}

#Preview {
    SleepReflectionModalView()
        .environmentObject(SleepReflectionViewModel())
        .environmentObject(UserSettingsViewModel())
        .appBackground()
}
