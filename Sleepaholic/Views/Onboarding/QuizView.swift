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

    @StateObject private var viewModel = QuizViewModel()

    @State private var name = ""
    @State private var age = ""
    @State private var bedtime = Date()
    @State private var wakeup = Date()
    @State private var selectedOption: String? = nil

    let next: () -> Void
    let previous: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // MARK: - Back Button
            HStack {
                Button {
                    if viewModel.currentIndex > 0 {
                        viewModel.previousQuestion()
                        restorePreviousAnswer()
                    } else {
                        previous()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(8)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                // MARK: - Progress Bar
                ProgressView(value: Double(viewModel.currentIndex + 1),
                             total: Double(viewModel.questions.count))
                    .accentColor(.accentColor)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .padding(.horizontal)

                // MARK: - Question Counter
                Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)


            // MARK: - Question
            if let q = viewModel.currentQuestion {
                Spacer()

                Text(q.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // MARK: - Answer input
                Group {
                    switch q.type {
                    case .multipleChoice:
                        VStack(spacing: 12) {
                            ForEach(q.options, id: \.self) { option in
                                Button {
                                    selectedOption = option
                                } label: {
                                    Text(option)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(selectedOption == option ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedOption == option ? Color.accentColor : .clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)

                    case .textInput:
                        VStack(spacing: 16) {
                            TextField("Enter your name", text: $name)
                                .textFieldStyle(.roundedBorder)
                            TextField("Enter your age", text: $age)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal)

                    case .timePicker:
                        DatePicker("",
                                   selection: q.id == 12 ? $bedtime : $wakeup,
                                   displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxHeight: 200)
                    }
                }

                Spacer()

                // MARK: - Footer buttons
                VStack(spacing: 12) {
                    if !q.isRequired {
                        Button {
                            viewModel.currentIndex = 10 // Jump directly to Q11
                            restorePreviousAnswer()
                        } label: {
                            Text("Skip Quiz")
                                .foregroundColor(.gray)
                        }
                    }

                    Button {
                        Task {
                            saveCurrentAnswer(for: q)
                        }
                    } label: {
                        Text(viewModel.isLastQuestion ? "Finish" : "Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canContinue(q) ? Color.accentColor : Color.gray.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(!canContinue(q))
                }
            }
        }
        .task {
            // Prefill from profile/settings
            await userProfileViewModel.loadProfile()
            await userSettingsViewModel.loadSettings()
            prefillUserData()
            restorePreviousAnswer()
        }
        .animation(.easeInOut, value: viewModel.currentIndex)
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
    QuizView(next: {}, previous: {})
        .environmentObject(UserProfileViewModel())
        .environmentObject(UserSettingsViewModel())
}
