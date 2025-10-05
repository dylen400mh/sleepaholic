//
//  OpenAIService.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-04.
//

import Foundation

final class OpenAIService {
    static let shared = OpenAIService()  // Singleton for convenience
    private init() {}

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o-mini"

    func generateSleepInsights(from input: SleepInsightInput) async throws -> SleepInsightOutput {
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            throw NSError(domain: "Missing API Key", code: 401)
        }

        // Encode user input
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let inputData = try encoder.encode(input)
        let inputJSON = String(data: inputData, encoding: .utf8) ?? "{}"
        
        // Build prompt
        let prompt = """
        You are a certified sleep health expert analyzing a user's recent sleep and lifestyle data.

        ### TASK
        Using ONLY the provided JSON data, output:
        {
          "quality": <integer between 0 and 100>,
          "recommendations": ["tip1", "tip2", "tip3"]
        }

        Respond **only in valid JSON**, no commentary.

        ### STRICT RULES
        1. **Use data exclusively** — do not assume missing habits or preferences.
           - If an activity (like caffeine or alcohol) is not logged, DO NOT mention it.
           - If consistency data is within a healthy range, DO NOT suggest improvement.
        2. **Context awareness:**
           - Treat bedtime as "late" only if it results in < target sleep hours or creates sleep debt.
           - Treat bedtime as "early" only if it reduces total sleep below target hours.
           - Assume the user already practices basic hygiene unless data indicates otherwise.
        3. **Scoring Sleep Quality (0–100):**
           - 90–100 → Excellent: Met/exceeded target, consistent, low debt, few disturbances.
           - 75–89 → Good: Slightly below target or small debt.
           - 60–74 → Fair: Missed target by 1–2 h or minor inconsistency.
           - 40–59 → Poor: High debt, irregular sleep times.
           - 0–39 → Very poor: Severe lack of sleep, highly irregular schedule, or multiple disturbances.
        4. **Audio Clips Count:**
           - 0–3 clips → Quiet night, no penalty.
           - >3 clips → Slight quality reduction.
        5. **Recommendations:**
           - Provide exactly **3 actionable tips** (≤15 words each).
           - Each must directly relate to the provided data (sleep duration, consistency, logged activities, or disturbances).
           - Avoid generic or speculative advice like “limit screens” or “relax more” unless clearly justified by data.
        6. **If data shows overall good sleep**, you may give positive reinforcement instead of improvement tips.

        ### USER DATA
        \(inputJSON)
        """

        // Prepare the body
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are an expert in sleep science."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Execute request
        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw NSError(domain: "Invalid response format", code: 500)
        }

        // Decode model response
        let outputData = Data(content.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(SleepInsightOutput.self, from: outputData)
    }
}
