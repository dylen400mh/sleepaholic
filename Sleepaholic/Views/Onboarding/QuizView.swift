//
//  QuizView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import SwiftUI

struct QuizView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @EnvironmentObject var userSettingsViewModel: UserSettingsViewModel

    @EnvironmentObject private var viewModel: QuizViewModel

    @State private var name = ""
    @State private var age = ""
    @State private var bedtime = Date()
    @State private var wakeup = Date()
    @State private var selectedOption: String? = nil

    let next: () -> Void
    let previous: () -> Void
    let startAt: Int
    @Binding var didSkipQuiz: Bool

    var body: some View {
        if let q = viewModel.currentQuestion {
            VStack(spacing: 0) {
                VStack(spacing: 48) {
                    // MARK: - Header
                    OnboardingHeader(previous: {
                        if viewModel.currentIndex > 0 {
                            viewModel.previousQuestion()
                            restorePreviousAnswer()
                        } else {
                            previous()
                        }
                    })
                    
                    VStack(spacing: 12) {
                        // MARK: - Progress Bar
                        GeometryReader { geo in
                            let fraction = CGFloat(viewModel.currentIndex + 1) / CGFloat(max(viewModel.questions.count, 1))
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.white20)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Gradients.main)
                                    .frame(width: geo.size.width * fraction, height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        // MARK: - Question Counter
                        Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                            .font(.body2)
                            .foregroundColor(.white80)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    
                    // MARK: - Question
                    VStack(alignment: .leading, spacing: 32) {
                        Text(q.text)
                            .font(.h2Semi)
                            .foregroundColor(.white100)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // MARK: - Answer input
                        Group {
                            switch q.type {
                            case .multipleChoice:
                                ScrollView(.vertical) {
                                    VStack(spacing: 16) {
                                        ForEach(q.options, id: \.self) { option in
                                            MultipleChoiceOption(
                                                text: option,
                                                isSelected: selectedOption == option,
                                                icon: nil
                                            ) {
                                                HapticsManager.play(.light)
                                                selectedOption = option
                                            }
                                        }
                                    }
                                }
                                
                            case .textInput:
                                VStack(spacing: 24) {
                                    InputField(label: "Name", text: $name)
                                    InputField(label: "Age", text: $age)
                                }
                                
                            case .timePicker:
                                DatePicker("",
                                           selection: q.id == 12 ? $bedtime : $wakeup,
                                           displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .foregroundColor(Color.white100)
                                .frame(maxHeight: 200)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                
                // MARK: - Footer buttons
                VStack(spacing: 16) {
                    Button {
                        HapticsManager.play(.medium)
                        Task { saveCurrentAnswer(for: q) }
                    } label: {
                        PrimaryButton(
                            title: viewModel.isLastQuestion ? "Finish" : "Continue",
                            icon: nil,
                            size: .regular,
                            isDisabled: !canContinue(q)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canContinue(q))
                    
                    if !q.isRequired {
                        Button(action: {
                            HapticsManager.play(.light)
                            didSkipQuiz = true
                            viewModel.currentIndex = 10 // Jump directly to Q11
                            restorePreviousAnswer()
                        }) {
                            HStack(spacing: 4) {
                                Text("Skip quiz")
                                    .font(.body1Semi)
                                    .foregroundColor(.white100)
                                
                                Image(systemName: "arrow.right")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white100)
                            }
                        }
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
            .task {
                AnalyticsService.shared.trackEvent(eventName: "quiz_viewed")
                
                // Prefill from profile/settings
                await userSettingsViewModel.loadSettings()
                prefillUserData()
                restorePreviousAnswer()
                
                if startAt > 0 && startAt < viewModel.questions.count {
                    viewModel.currentIndex = startAt
                }
            }
            .animation(.easeInOut, value: viewModel.currentIndex)
        }
    }

    // MARK: - Logic

    private func saveCurrentAnswer(for q: QuizQuestion) {
        switch q.type {
        case .multipleChoice:
            if let selected = selectedOption {
                viewModel.selectAnswer(selected)
                
                // Save gender if this is question 1
                if q.id == 1 {
                    let profile = UserProfile(
                        name: userProfileViewModel.profile?.name ?? "",
                        age: userProfileViewModel.profile?.age ?? 0,
                        gender: selected,
                        createdAt: userProfileViewModel.profile?.createdAt ?? Date()
                    )
                    Task { await userProfileViewModel.saveProfile(profile) }
                }
            }

        case .textInput:
            // Save profile info to Firestore
            let profile = UserProfile(
                name: name,
                age: Int(age) ?? 0,
                gender: userProfileViewModel.profile?.gender ?? "",
                createdAt: userProfileViewModel.profile?.createdAt ?? Date()
            )
            Task { await userProfileViewModel.saveProfile(profile) }
            viewModel.selectAnswer("Name:\(name) | Age:\(age)")

        case .timePicker:
            let fmt = DateFormatter()
            fmt.timeStyle = .short
            let time = q.id == 12 ? fmt.string(from: bedtime)
                                  : fmt.string(from: wakeup)
            viewModel.selectAnswer(time)

            // Save settings to Firestore
            let bedtimeMinutes = Calendar.current.component(.hour, from: bedtime) * 60 +
                                 Calendar.current.component(.minute, from: bedtime)
            let wakeupMinutes = Calendar.current.component(.hour, from: wakeup) * 60 +
                                Calendar.current.component(.minute, from: wakeup)

            let current = userSettingsViewModel.settings ?? UserSettings(
                bedtime: bedtimeMinutes,
                wakeUpTime: wakeupMinutes,
                trackSleep: false,
                restrictApps: false
            )

            let updated = UserSettings(
                bedtime: bedtimeMinutes,
                wakeUpTime: wakeupMinutes,
                trackSleep: current.trackSleep,
                restrictApps: current.restrictApps
            )

            Task { await userSettingsViewModel.saveSettings(updated) }
        }

        // Move forward
        if viewModel.isLastQuestion {
            next()
        } else {
            viewModel.nextQuestion()
            restorePreviousAnswer()
        }
    }

    private func restorePreviousAnswer() {
        guard let q = viewModel.currentQuestion else { return }

        if let saved = q.answer {
            switch q.type {
            case .multipleChoice:
                selectedOption = saved

            case .textInput:
                let parts = saved.split(separator: "|")
                if parts.count == 2 {
                    name = parts[0].replacingOccurrences(of: "Name:", with: "").trimmingCharacters(in: .whitespaces)
                    age = parts[1].replacingOccurrences(of: "Age:", with: "").trimmingCharacters(in: .whitespaces)
                }

            case .timePicker:
                // Time already restored by DatePicker binding
                break
            }
        } else {
            // Reset if no stored answer
            selectedOption = nil
        }
    }

    private func prefillUserData() {
        if let profile = userProfileViewModel.profile {
            if !profile.name.isEmpty { name = profile.name }
            if profile.age != 0 { age = String(profile.age) }
        }

        if let settings = userSettingsViewModel.settings {
            let bedtimeDate = Calendar.current.date(bySettingHour: settings.bedtime / 60,
                                                    minute: settings.bedtime % 60,
                                                    second: 0, of: Date()) ?? Date()
            let wakeupDate = Calendar.current.date(bySettingHour: settings.wakeUpTime / 60,
                                                   minute: settings.wakeUpTime % 60,
                                                   second: 0, of: Date()) ?? Date()
            bedtime = bedtimeDate
            wakeup = wakeupDate
        }
    }

    private func canContinue(_ q: QuizQuestion) -> Bool {
        guard q.isRequired else { return selectedOption != nil || q.type != .multipleChoice }
        switch q.type {
        case .textInput:
            let ageOK = Int(age) != nil && !age.trimmingCharacters(in: .whitespaces).isEmpty
            let nameOK = !name.trimmingCharacters(in: .whitespaces).isEmpty
            return nameOK && ageOK
        case .timePicker:
            return true
        case .multipleChoice:
            return selectedOption != nil
        }
    }
}

#Preview {
    QuizView(next: {}, previous: {}, startAt: 0, didSkipQuiz: .constant(false))
        .environmentObject(UserProfileViewModel())
        .environmentObject(UserSettingsViewModel())
}
