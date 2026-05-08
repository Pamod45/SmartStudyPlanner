//
//  HostedLLMBackend.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-05-06.
//

import Foundation

// Hosted fallback LLM backend used by StudyContentOrchestrator when Foundation Models are unavailable.
// It asks the server for strict JSON, then validates and salvages the response before turning it into app models.
struct HostedLLMBackend: StudyLLMBackend {

    let serverURL: URL
    private let temperature: Double = 0.1
    private let timeoutInterval: TimeInterval = 120
    private let studyPathInputWordLimit = 1_400
    private let quizInputWordLimit = 1_200

    func generateStudyPath(from text: String, topicCount: Int) async throws -> GeneratedStudyPath {
        let systemPrompt = """
        You are an expert tutor. Create a study path from the provided text.
        Output MUST be ONLY valid JSON — no markdown fences, no explanation. MAKE SURE YOU ONLY PROVIDE THE CURRENT GIVEN OUTPUT FORMAT. THAT IS THE ONE AND ONLY ACCEPTABLE OUTPUT.
        Use exactly this schema (array of \(topicCount) objects, weightPercent must sum to 100):
        [
          {
            "order": 1,
            "title": "Topic Title",
            "description": "One sentence description.",
            "subtopics": ["Subtopic A", "Subtopic B"],
            "weightPercent": 20,
            "difficultyLevel": 6,
            "estimatedMinutes": 90
          }
        ]
        Rules:
        - difficultyLevel: 1 (very easy) to 10 (very hard).
        - estimatedMinutes: realistic total study time a student needs to master this topic.
        - The first character of your response must be "[".
        - The last character of your response must be "]".
        - Do NOT write notes, comments, explanations, apologies, summaries, or follow-up text after the JSON.
        - Do NOT include any text outside the JSON array.
        """

        let userMessage = "Study material:\n\(limitedWords(from: text, maxWords: studyPathInputWordLimit))\n\nReturn ONLY the JSON array."

        let raw = try await callServer(system: systemPrompt, user: userMessage, maxTokens: 1_400)

        print("🔵 [HostedLLM] Study path raw response:\n\(raw)")

        let topics = try parseTopics(from: raw)
        return GeneratedStudyPath(topics: topics)
    }

    func generateQuiz(from text: String, questionCount: Int) async throws -> GeneratedQuiz {
        let systemPrompt = """
        You are an expert tutor. Create quiz questions from the provided study material.
        Output MUST be ONLY valid JSON — no markdown fences, no explanation.
        Use exactly this schema (array of \(questionCount) objects):
        [
          {
            "question": "What is ...?",
            "answer": "...",
            "keyword": "main concept tested"
          }
        ]
        """

        let userMessage = "Study material:\n\(limitedWords(from: text, maxWords: quizInputWordLimit))\n\nReturn ONLY the JSON array."

        let raw = try await callServer(system: systemPrompt, user: userMessage, maxTokens: 2048)

        print("🔵 [HostedLLM] Quiz raw response:\n\(raw)")

        let items = try parseQuizItems(from: raw)
        return GeneratedQuiz(items: items)
    }

    func generateQuizQuestions(from text: String, questionCount: Int, category: String) async throws -> QuizGenerationResult {
        let clamped = min(questionCount, 10)

        let systemPrompt = """
        You are an expert tutor. Create \(clamped) multiple-choice quiz questions from the study material below.
        Output MUST be ONLY valid JSON — no markdown fences, no explanation.
        Each item MUST follow this schema exactly:
        [
          {
            "questionText": "What is ...?",
            "options": ["A. Subject-specific answer", "B. Plausible wrong answer", "C. Plausible wrong answer", "D. Plausible wrong answer"],
            "correctOptionIndex": 0,
            "category": "\(category)",
            "expertTip": "One-line hint about the concept.",
            "keyword": "main concept tested"
          }
        ]
        Rules:
        - options must contain EXACTLY 4 strings.
        - Every option MUST be a real, subject-specific answer choice based on the study material.
        - NEVER use placeholder option text like "First option", "Second option", "Third option", "Fourth option", "Subject-specific answer", or "Plausible wrong answer".
        - The correct option must be one of the 4 options.
        - correctOptionIndex must be 0, 1, 2, or 3.
        - The first character of your response must be "[".
        - The last character of your response must be "]".
        - Do NOT write notes, comments, explanations, apologies, summaries, or follow-up text after the JSON.
        - Do NOT include any text outside the JSON array.
        """

        let userMessage = "Study material:\n\(limitedWords(from: text, maxWords: quizInputWordLimit))\n\nReturn ONLY the JSON array."

        let raw = try await callServer(system: systemPrompt, user: userMessage, maxTokens: 2_048)

        print("🔵 [HostedLLM] Quiz questions raw response:\n\(raw)")

        return try parseQuizQuestions(from: raw, fallbackCategory: category)
    }

    // Sends an OpenAI-compatible chat completion request to the configured local/hosted server.
    private func callServer(system: String, user: String, maxTokens: Int) async throws -> String {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        let body: [String: Any] = [
            "messages": [
                ["role": "system",    "content": system],
                ["role": "user",      "content": user]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw LLMError.badServerResponse(code)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw LLMError.unexpectedResponseShape
        }

        return content
    }

    private func parseTopics(from raw: String) throws -> [GeneratedStudyPath.Topic] {
        let clean = jsonArrayString(from: stripMarkdown(raw))

        struct RawTopic: Decodable {
            let order: Int
            let title: String
            let description: String
            let subtopics: [String]
            let weightPercent: Int?
            let difficultyLevel: Int?
            let estimatedMinutes: Int?
        }

        guard let data = clean.data(using: .utf8) else {
            throw LLMError.invalidJSON("Cannot encode string to data")
        }

        let decoded: [RawTopic]
        do {
            decoded = try JSONDecoder().decode([RawTopic].self, from: data)
        } catch {
            print("[HostedLLM] Study path decode failed. Attempting salvage…")
            let salvaged = salvageCompleteObjects(RawTopic.self, from: clean)
            guard !salvaged.isEmpty else { throw error }
            decoded = salvaged
        }
        return decoded.map {
            let weight = $0.weightPercent ?? 0
            return GeneratedStudyPath.Topic(
                order:            $0.order,
                title:            $0.title,
                description:      $0.description,
                subtopics:        $0.subtopics,
                weightPercent:    weight,
                difficultyLevel:  max(1, min(10, $0.difficultyLevel ?? 5)),
                estimatedMinutes: $0.estimatedMinutes ?? max(30, weight * 6)
            )
        }
    }

    private func parseQuizItems(from raw: String) throws -> [GeneratedQuiz.Item] {
        let clean = stripMarkdown(raw)

        struct RawItem: Decodable {
            let question: String
            let answer: String
            let keyword: String
        }

        guard let data = clean.data(using: .utf8) else {
            throw LLMError.invalidJSON("Cannot encode string to data")
        }

        let decoded = try JSONDecoder().decode([RawItem].self, from: data)
        return decoded.map {
            GeneratedQuiz.Item(question: $0.question, answer: $0.answer, keyword: $0.keyword)
        }
    }

    // Quiz responses are the most fragile, so this parser rejects placeholder options and salvages complete JSON objects if needed.
    private func parseQuizQuestions(from raw: String, fallbackCategory: String) throws -> QuizGenerationResult {
        
        struct RawMCQ: Decodable {
            let questionText: String
            let options: [String]
            let correctOptionIndex: Int
            let category: String?
            let expertTip: String?
            let keyword: String?
        }

        var clean = stripMarkdown(raw)

        if let arrayStart = clean.firstIndex(of: "["),
           let arrayEnd   = clean.lastIndex(of: "]") {
            clean = String(clean[arrayStart...arrayEnd])
        }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        // --- Attempt 1: full decode ---
        var decoded: [RawMCQ] = []
        if let data = clean.data(using: .utf8) {
            if let result = try? JSONDecoder().decode([RawMCQ].self, from: data) {
                decoded = result
            } else {
                print("[HostedLLM] Full decode failed (likely truncated). Attempting salvage…")
                decoded = salvageCompleteObjects(RawMCQ.self, from: clean)
                if decoded.isEmpty {
                    print("[HostedLLM] Salvage also returned 0 objects. Raw:\n\(clean.prefix(500))")
                    throw LLMError.invalidJSON("Could not decode any quiz questions from response")
                }
                print("[HostedLLM] Salvage recovered \(decoded.count) question(s)")
            }
        }

        let questions = decoded.compactMap { item -> QuizMCQItem? in
            guard !item.questionText.isEmpty, item.options.count == 4 else { return nil }
            guard !containsPlaceholderOptions(item.options) else { return nil }
            return QuizMCQItem(
                questionText:       item.questionText,
                options:            item.options,
                correctOptionIndex: max(0, min(3, item.correctOptionIndex)),
                category:           item.category ?? fallbackCategory,
                expertTip:          item.expertTip ?? "",
                keyword:            item.keyword ?? ""
            )
        }

        guard !questions.isEmpty else {
            throw LLMError.invalidJSON("Parsed zero valid questions from response")
        }
        return QuizGenerationResult(questions: questions)
    }

    private func containsPlaceholderOptions(_ options: [String]) -> Bool {
        let placeholders = [
            "first option",
            "second option",
            "third option",
            "fourth option",
            "subject-specific answer",
            "plausible wrong answer"
        ]

        return options.contains { option in
            let normalized = option.lowercased()
            return placeholders.contains { normalized.contains($0) }
        }
    }

    private func salvageCompleteObjects<T: Decodable>(_ type: T.Type, from raw: String) -> [T] {
        var results: [T] = []
        var depth = 0
        var objectStart: String.Index? = nil
        var inString = false
        var prev: Character = "\0"

        for idx in raw.indices {
            let ch = raw[idx]
            if ch == "\"" && prev != "\\" { inString.toggle() }
            if !inString {
                if ch == "{" {
                    if depth == 0 { objectStart = idx }
                    depth += 1
                } else if ch == "}" {
                    depth = max(0, depth - 1)
                    if depth == 0, let start = objectStart {
                        let candidate = String(raw[start...idx])
                        if let data = candidate.data(using: .utf8),
                           let obj  = try? JSONDecoder().decode(type, from: data) {
                            results.append(obj)
                        }
                        objectStart = nil
                    }
                }
            }
            prev = ch
        }
        return results
    }

    private func stripMarkdown(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```json") { s = String(s.dropFirst(7)) }
        else if s.hasPrefix("```") { s = String(s.dropFirst(3)) }
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func jsonArrayString(from raw: String) -> String {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = clean.firstIndex(of: "["),
           let end = clean.lastIndex(of: "]") {
            clean = String(clean[start...end])
        }
        return clean
    }

    private func limitedWords(from text: String, maxWords: Int) -> String {
        let words = text
            .split { $0.isWhitespace || $0.isNewline }
            .prefix(maxWords)
        return words.joined(separator: " ")
    }

    enum LLMError: LocalizedError {
        case badServerResponse(Int)
        case unexpectedResponseShape
        case invalidJSON(String)

        var errorDescription: String? {
            switch self {
            case .badServerResponse(let code): return "Server returned HTTP \(code)"
            case .unexpectedResponseShape:     return "Response JSON shape didn't match expected format"
            case .invalidJSON(let detail):     return "JSON parse error: \(detail)"
            }
        }
    }
}
