//
//  QuizViewModel.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import Foundation

@MainActor
final class QuizViewModel: ObservableObject {
    @Published var questions: [QuizQuestion] = []
    @Published var currentIndex: Int = 0

    init() {
        loadQuestions()
    }

    var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var isLastQuestion: Bool {
        guard !questions.isEmpty else { return false }
        return currentIndex == questions.count - 1
    }

    func selectAnswer(_ answer: String) {
        guard questions.indices.contains(currentIndex) else { return }
        questions[currentIndex].answer = answer
        
        let answersDict = questions.reduce(into: [String: Any]()) { result, question in
            result["Q\(question.id)"] = question.answer ?? "none"
        }

        AnalyticsService.shared.updateUserAttributes(
            attributes: [
                "quiz_answers": answersDict
            ]
        )
    }

    func nextQuestion() {
        guard !questions.isEmpty else { return }
        if currentIndex < questions.count - 1 { currentIndex += 1 }
    }
    
    func previousQuestion() {
        if currentIndex > 0 { currentIndex -= 1 }
    }

    func skipQuestion() {
        if currentQuestion?.isRequired == false { nextQuestion() }
    }
    
    func answerForCurrentQuestion() -> String? {
        currentQuestion?.answer
    }

    func loadQuestions() {
        questions = [
            .init(id: 1, text: "What is your gender?", options: ["Male", "Female", "Other"], isRequired: false, type: .multipleChoice),
            .init(id: 2, text: "How many hours of sleep do you typically get each night?", options: ["<4 hours", "4–5 hours", "6–7 hours", "8+ hours"], isRequired: false, type: .multipleChoice),
            .init(id: 3, text: "Where did you hear about us?", options: ["TikTok", "Instagram", "YouTube", "Google", "X", "App Store"], isRequired: false, type: .multipleChoice),
            .init(id: 4, text: "Has your sleep gotten worse in the last 6 months?", options: ["Yes", "No"], isRequired: false, type: .multipleChoice),
            .init(id: 5, text: "What age did you start noticing trouble with your sleep?", options: ["12 or younger", "13–17", "18–25", "26 or older"], isRequired: false, type: .multipleChoice),
            .init(id: 6, text: "Do you find it difficult to fall asleep without your phone or a screen?", options: ["Frequently", "Occasionally", "Rarely / Never"], isRequired: false, type: .multipleChoice),
            .init(id: 7, text: "Do you often stay up late even when you know you should be sleeping?", options: ["Frequently", "Occasionally", "Rarely / Never"], isRequired: false, type: .multipleChoice),
            .init(id: 8, text: "Do you use your phone in bed to distract yourself from stress or emotions?", options: ["Frequently", "Occasionally", "Rarely / Never"], isRequired: false, type: .multipleChoice),
            .init(id: 9, text: "Do you stay awake scrolling even when you feel tired?", options: ["Frequently", "Occasionally", "Rarely / Never"], isRequired: false, type: .multipleChoice),
            .init(id: 10, text: "Have you ever spent money on sleep aids (e.g., melatonin, sleep apps, supplements)?", options: ["Yes", "No"], isRequired: false, type: .multipleChoice),
            .init(id: 11, text: "A little more about you — name, age", options: [], isRequired: true, type: .textInput),
            .init(id: 12, text: "When is your target bedtime?", options: [], isRequired: true, type: .timePicker),
            .init(id: 13, text: "What is your target wake-up time?", options: [], isRequired: true, type: .timePicker),
        ]
        currentIndex = 0
    }
}
