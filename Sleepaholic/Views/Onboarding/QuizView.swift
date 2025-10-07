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

    var body: some View {
        VStack(spacing: 32) {
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
                            // Jump directly to question 11 (index 10)
                            viewModel.currentIndex = 10
                            selectedOption = nil
                        } label: {
                            Text("Skip Quiz")
                                .foregroundColor(.gray)
                        }
                    }

                    if q.type == .multipleChoice {
                        if selectedOption != nil {
                            Button {
                                viewModel.selectAnswer(selectedOption!)
                                selectedOption = nil
                                viewModel.nextQuestion()
                            } label: {
                                Text("Continue")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        Button {
                            Task {
                                if q.id == 11 {
                                    // Save name + age to profile
                                    let profile = UserProfile(
                                        name: name,
                                        age: Int(age) ?? 0,
                                        gender: userProfileViewModel.profile?.gender ?? "",
                                        createdAt: userProfileViewModel.profile?.createdAt ?? Date()
                                    )
                                    await userProfileViewModel.saveProfile(profile)
                                } else if q.id == 12 || q.id == 13 {
                                    // Save bedtime/wakeup to settings
                                    let bedtimeMinutes = Calendar.current.component(.hour, from: bedtime) * 60 +
                                                         Calendar.current.component(.minute, from: bedtime)
                                    let wakeupMinutes = Calendar.current.component(.hour, from: wakeup) * 60 +
                                                        Calendar.current.component(.minute, from: wakeup)

                                    let currentSettings = userSettingsViewModel.settings ?? UserSettings(
                                        bedtime: bedtimeMinutes,
                                        wakeUpTime: wakeupMinutes,
                                        trackSleep: false,
                                        restrictApps: false
                                    )
                                    let updated = UserSettings(
                                        bedtime: bedtimeMinutes,
                                        wakeUpTime: wakeupMinutes,
                                        trackSleep: currentSettings.trackSleep,
                                        restrictApps: currentSettings.restrictApps
                                    )
                                    await userSettingsViewModel.saveSettings(updated)
                                }

                                // Save locally and continue
                                if q.type == .textInput {
                                    viewModel.selectAnswer("Name:\(name) | Age:\(age)")
                                } else if q.type == .timePicker {
                                    let fmt = DateFormatter()
                                    fmt.timeStyle = .short
                                    let time = q.id == 12 ? fmt.string(from: bedtime)
                                                          : fmt.string(from: wakeup)
                                    viewModel.selectAnswer(time)
                                }

                                if viewModel.isLastQuestion {
                                    next()
                                } else {
                                    viewModel.nextQuestion()
                                }
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
        }
        .onAppear {
            // Prefill name + age if available
            if let profile = userProfileViewModel.profile {
                if !profile.name.isEmpty {
                    name = profile.name
                }
                if profile.age != 0 {
                    age = String(profile.age)
                }
            }

            // Prefill bedtime/wakeup if available
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
        .animation(.easeInOut, value: viewModel.currentIndex)
    }

    private func canContinue(_ q: QuizQuestion) -> Bool {
        guard q.isRequired else { return true }
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
    QuizView(next: {})
        .environmentObject(UserProfileViewModel())
        .environmentObject(UserSettingsViewModel())
}
