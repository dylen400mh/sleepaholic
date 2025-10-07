//
//  QuizQuestion.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-05.
//

import Foundation

enum QuestionType: String, Codable {
    case multipleChoice
    case textInput
    case timePicker
}

struct QuizQuestion: Identifiable, Codable {
    let id: Int
    let text: String
    let options: [String]
    let isRequired: Bool
    let type: QuestionType
    var answer: String?
}
