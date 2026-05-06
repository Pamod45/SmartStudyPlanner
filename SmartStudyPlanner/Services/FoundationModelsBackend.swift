//
//  FoundationModelsBackend.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-05-06.
//

// FoundationModelsBackend.swift
// Uses Apple Intelligence on-device LLM (iOS 26+).
// Structured output via @Generable — no JSON parsing needed.

import Foundation
import FoundationModels

// MARK: - Generable structs for structured output

@available(iOS 26.0, *)
@Generable
struct FMStudyPathResponse {
    @Guide(description: "Ordered list of study topics covering the material")
    var topics: [FMTopic]
}

@available(iOS 26.0, *)
@Generable
struct FMTopic {
    @Guide(description: "Topic number starting from 1")
    var order: Int

    @Guide(description: "Short descriptive title, 3-6 words")
    var title: String

    @Guide(description: "One sentence explaining what this topic covers")
    var description: String

    @Guide(description: "2-4 specific subtopics or concepts within this topic")
    var subtopics: [String]

    @Guide(description: "Integer percentage of total study time. All topics MUST sum to exactly 100. Distribute proportionally by importance.")
    var weightPercent: Int
}

@available(iOS 26.0, *)
@Generable
struct FMQuizResponse {
    @Guide(description: "List of quiz question-answer pairs")
    var items: [FMQuizItem]
}

@available(iOS 26.0, *)
@Generable
struct FMQuizItem {
    @Guide(description: "A clear, specific question about the topic")
    var question: String

    @Guide(description: "A concise, accurate answer to the question")
    var answer: String

    @Guide(description: "The key concept or keyword this question tests")
    var keyword: String
}

@available(iOS 26.0, *)
@Generable
struct FMQuizQuestionsResponse {
    @Guide(description: "Ordered list of multiple-choice quiz questions")
    var questions: [FMQuizQuestion]
}

@available(iOS 26.0, *)
@Generable
struct FMQuizQuestion {
    @Guide(description: "The question text")
    var questionText: String

    @Guide(description: "Exactly 4 answer options, starting with the answer letter, e.g. A. ...")
    var options: [String]

    @Guide(description: "Index of the correct option, 0-3")
    var correctOptionIndex: Int

    @Guide(description: "Topic or concept category")
    var category: String

    @Guide(description: "One-line expert tip or hint shown after answering")
    var expertTip: String

    @Guide(description: "Key concept being tested by this question")
    var keyword: String
}

// MARK: - Backend

@available(iOS 26.0, *)
struct FoundationModelsBackend: StudyLLMBackend {

    func generateStudyPath(from text: String, topicCount: Int) async throws -> GeneratedStudyPath {
        let session = LanguageModelSession()

        // Trim text to avoid hitting context limits — 4000 chars is safe
        let trimmedText = String(text.prefix(4000))

        let prompt = """
        You are an expert tutor. Analyze the following study material and create \
        exactly \(topicCount) study topics that cover it comprehensively. \
        The weightPercent of all topics must sum to exactly 100.

        Study material:
        \(trimmedText)
        """

        let response = try await session.respond(
            to: prompt,
            generating: FMStudyPathResponse.self
        )

        let topics = response.content.topics.map { t in
            GeneratedStudyPath.Topic(
                order:         t.order,
                title:         t.title,
                description:   t.description,
                subtopics:     t.subtopics,
                weightPercent: t.weightPercent
            )
        }

        return GeneratedStudyPath(topics: topics)
    }

    func generateQuiz(from text: String, questionCount: Int) async throws -> GeneratedQuiz {
        let session = LanguageModelSession()
        let trimmedText = String(text.prefix(4000))

        let prompt = """
        You are an expert tutor. Create exactly \(questionCount) quiz questions \
        based on the following study material. Each question should test a \
        different key concept.

        Study material:
        \(trimmedText)
        """

        let response = try await session.respond(
            to: prompt,
            generating: FMQuizResponse.self
        )

        let items = response.content.items.map { i in
            GeneratedQuiz.Item(
                question: i.question,
                answer:   i.answer,
                keyword:  i.keyword
            )
        }

        return GeneratedQuiz(items: items)
    }

    func generateQuizQuestions(from text: String, questionCount: Int, category: String) async throws -> QuizGenerationResult {
        let session = LanguageModelSession()
        let trimmedText = String(text.prefix(4000))
        let clamped = min(questionCount, 10)

        let prompt = """
        You are an expert tutor. Create exactly \(clamped) multiple-choice quiz questions \
        based on the following study material about "\(category)". \
        Each question must have exactly 4 answer options. \
        The correctOptionIndex must be 0, 1, 2, or 3.

        Study material:
        \(trimmedText)
        """

        let response = try await session.respond(
            to: prompt,
            generating: FMQuizQuestionsResponse.self
        )

        let questions = response.content.questions.map { q in
            QuizMCQItem(
                questionText:       q.questionText,
                options:            q.options,
                correctOptionIndex: max(0, min(3, q.correctOptionIndex)),
                category:           q.category.isEmpty ? category : q.category,
                expertTip:          q.expertTip,
                keyword:            q.keyword
            )
        }

        return QuizGenerationResult(questions: questions)
    }
}
