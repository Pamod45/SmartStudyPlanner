//
//  FoundationModelsBackend.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-05-06.
//

import Foundation
import FoundationModels
import Combine

// On-device LLM backend used when Apple Foundation Models are available.
// StudyContentOrchestrator calls this through StudyLLMBackend, so the rest of the app does not care which backend is selected.
@Generable
struct FMStudyPathResponse {
    @Guide(description: "Ordered list of study topics covering the material")
    var topics: [FMTopic]
}

@Generable
struct FMTopic {
    @Guide(description: "Should be a number starting from 1 to indicating the sequence of the topics in the study path.")
    var order: Int

    @Guide(description: "Short descriptive title, 3-6 words")
    var title: String

    @Guide(description: "Should be a one-sentence description, less than 20 words.")
    var description: String

    @Guide(description: "Should be a list of 2-5 key concepts or subtopics that fall under the main topic.")
    var subtopics: [String]

    @Guide(description: "Integer percentage of total study time. All topics MUST sum to exactly 100. Distribute proportionally by importance.")
    var weightPercent: Int
    
    @Guide(description: "Should be an integer from 1 (very easy) to 10 (very difficult) indicating the relative difficulty of the topic compared to the others.")
    var difficultyLevel: Int
    
    @Guide(description: "Should be a realistic estimate of the total study time in minutes that a student would need to master this topic, based on its complexity(difficultyLevel) and weight in the overall material.")
    var estimatedMinutes: Int
}

@Generable
struct FMQuizResponse {
    @Guide(description: "List of quiz question-answer pairs")
    var items: [FMQuizItem]
}

@Generable
struct FMQuizItem {
    @Guide(description: "A clear, specific question about the topic")
    var question: String

    @Guide(description: "A concise, accurate answer to the question")
    var answer: String

    @Guide(description: "The key concept or keyword this question tests")
    var keyword: String
}

@Generable
struct FMQuizQuestionsResponse {
    @Guide(description: "Ordered list of multiple-choice quiz questions")
    var questions: [FMQuizQuestion]
}

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

struct FoundationModelsBackend: StudyLLMBackend {
    
    let contextCharacterLimit: Int = 8000

    func generateStudyPath(from text: String, topicCount: Int) async throws -> GeneratedStudyPath {
        let session = LanguageModelSession()

        let trimmedText = String(text.prefix(contextCharacterLimit))

        let prompt = """
        You are an expert tutor. Analyze the following study material and create \
        exactly \(topicCount) study topics that cover it comprehensively. \
        The weightPercent of all topics must sum to exactly 100.

        Study material:
        \(trimmedText)
        """
        
        print("[FondationalModelBackend] prompt: \(prompt)")

        let response = try await session.respond(
            to: prompt,
            generating: FMStudyPathResponse.self
        )

        let topics = response.content.topics.map { t in
            GeneratedStudyPath.Topic(
                order:            t.order,
                title:            t.title,
                description:      t.description,
                subtopics:        t.subtopics,
                weightPercent:    t.weightPercent,
                difficultyLevel:  t.difficultyLevel,
                estimatedMinutes: t.estimatedMinutes
            )
        }

        return GeneratedStudyPath(topics: topics)
    }

    func generateQuiz(from text: String, questionCount: Int) async throws -> GeneratedQuiz {
        let session = LanguageModelSession()
        let trimmedText = String(text.prefix(contextCharacterLimit))

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
        let trimmedText = String(text.prefix(contextCharacterLimit))
        let clamped = min(questionCount, 10)

        let prompt = """
        You are an expert tutor. Create exactly \(clamped+1) multiple-choice quiz questions \
        based on the following study material about "\(category)". \
        Each question must have exactly 4 answer options. \
        The correctOptionIndex must be 0, 1, 2, or 3.

        Study material:
        \(trimmedText)
        """
        
        print("[FondationalModelBackend] prompt: \(prompt)")

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
        var i = 0
        for question in questions {
            i+=1
            print("Question Number: \(i) Question: \(question.questionText)")
            print("Options count: \(question.options.count)")
        }
        
        print("Question count: \(questions.count)")

        return QuizGenerationResult(questions: questions)
    }
}
