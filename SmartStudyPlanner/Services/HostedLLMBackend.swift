//
//  HostedLLMBackend.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-05-06.
//

import Foundation

struct HostedLLMBackend: StudyLLMBackend {

    let serverURL: URL
    private let temperature: Double = 0.3
    private let timeoutInterval: TimeInterval = 120

    func generateStudyPath(from text: String, topicCount: Int) async throws -> GeneratedStudyPath {
        let systemPrompt = """
        You are an expert tutor. Create a study path from the provided text.
        Output MUST be ONLY valid JSON — no markdown fences, no explanation.
        Use exactly this schema (array of \(topicCount) objects, weightPercent must sum to 100):
        [
          {
            "order": 1,
            "title": "Topic Title",
            "description": "One sentence description.",
            "subtopics": ["Subtopic A", "Subtopic B"],
            "weightPercent": 20
          }
        ]
        """

        let userMessage = "Study material:\n\(String(text.prefix(6000)))\n\nReturn ONLY the JSON array."

        let raw = try await callServer(system: systemPrompt, user: userMessage)

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

        let userMessage = "Study material:\n\(String(text.prefix(6000)))\n\nReturn ONLY the JSON array."

        let raw = try await callServer(system: systemPrompt, user: userMessage)

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
            "options": ["A. First option", "B. Second option", "C. Third option", "D. Fourth option"],
            "correctOptionIndex": 0,
            "category": "\(category)",
            "expertTip": "One-line hint about the concept.",
            "keyword": "main concept tested"
          }
        ]
        Rules:
        - options must contain EXACTLY 4 strings.
        - correctOptionIndex must be 0, 1, 2, or 3.
        - Do NOT include any text outside the JSON array.
        """

        let userMessage = "Study material:\n\(String(text.prefix(6000)))\n\nReturn ONLY the JSON array."

        let raw = try await callServer(system: systemPrompt, user: userMessage)

        print("🔵 [HostedLLM] Quiz questions raw response:\n\(raw)")

        return try parseQuizQuestions(from: raw, fallbackCategory: category)
    }

    private func callServer(system: String, user: String) async throws -> String {
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
            "max_tokens": 2048
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
        let clean = stripMarkdown(raw)

        struct RawTopic: Decodable {
            let order: Int
            let title: String
            let description: String
            let subtopics: [String]
            let weightPercent: Int?
        }

        guard let data = clean.data(using: .utf8) else {
            throw LLMError.invalidJSON("Cannot encode string to data")
        }

        let decoded = try JSONDecoder().decode([RawTopic].self, from: data)
        return decoded.map {
            GeneratedStudyPath.Topic(
                order:         $0.order,
                title:         $0.title,
                description:   $0.description,
                subtopics:     $0.subtopics,
                weightPercent: $0.weightPercent ?? 0
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
