// Coordinates NLTextAnalyzer + the best available LLM backend.

import Foundation
import Combine

@MainActor
final class StudyContentOrchestrator: ObservableObject {

    static let shared = StudyContentOrchestrator()

    private let hostedServerURL = URL(string: "http://192.168.1.21:8080/v1/chat/completions")!

    @Published private(set) var isGenerating = false
    @Published private(set) var error: Error?

    private lazy var backend: StudyLLMBackend = {
        LLMBackendSelector.resolve(hostedURL: hostedServerURL)
    }()

    private init() {}

    func buildStudyPath(from text: String,
                        topicCount: Int = 5) async throws -> [StudyPathTopic] {
        isGenerating = true
        error = nil
        defer { isGenerating = false }

        do {
            let result = try await backend.generateStudyPath(from: text, topicCount: topicCount)

            return result.topics.map { t in
                StudyPathTopic(
                    order:            t.order,
                    title:            t.title,
                    description:      t.description,
                    subtopics:        t.subtopics,
                    weightPercent:    t.weightPercent,
                    estimatedMinutes: t.estimatedMinutes,
                    difficultyLevel:  t.difficultyLevel
                )
            }
        } catch {
            self.error = error
            throw error
        }
    }

    func buildQuizQuestions(
        from text: String,
        questionCount: Int,
        category: String
    ) async throws -> [QuizQuestion] {
        let clamped = min(questionCount, 10)
        isGenerating = true
        error = nil
        defer { isGenerating = false }

        do {
            let result = try await backend.generateQuizQuestions(
                from: text,
                questionCount: clamped,
                category: category
            )

            return result.questions.enumerated().map { index, item in
                QuizQuestion(
                    id: UUID().uuidString,
                    number: index + 1,
                    category: item.category,
                    questionText: item.questionText,
                    questionType: .multipleChoice,
                    options: item.options,
                    correctOptionIndex: item.correctOptionIndex,
                    expertTip: item.expertTip,
                    keyword: item.keyword,
                    hint: nil,
                    points: 1
                )
            }
        } catch {
            self.error = error
            throw error
        }
    }

//    func buildQuiz(from text: String,
//                   questionCount: Int = 5) async throws -> [QuizItem] {
//        isGenerating = true
//        error = nil
//        defer { isGenerating = false }
//
//        do {
//            let result = try await backend.generateQuiz(from: text, questionCount: questionCount)
//
//            return result.items.map { i in
//                QuizItem(
//                    id:       UUID().uuidString,
//                    question: i.question,
//                    answer:   i.answer,
//                    keyword:  i.keyword
//                )
//            }
//        } catch {
//            self.error = error
//            throw error
//        }
//    }


//    func buildWeeklyPlan(from topics: [StudyPathTopic],
//                         weeks: Int = 4) -> [StudyWeek] {
//        guard !topics.isEmpty, weeks > 0 else { return [] }
//        let perWeek = max(1, Int(ceil(Double(topics.count) / Double(weeks))))
//        return stride(from: 0, to: topics.count, by: perWeek).map { start in
//            let slice = Array(topics[start..<min(start + perWeek, topics.count)])
//            let w = start / perWeek + 1
//            return StudyWeek(
//                weekNumber:     w,
//                topics:         slice,
//                estimatedHours: slice.reduce(0) { $0 + max(1, $1.weightPercent / 10) }
//            )
//        }
//    }


    func quickSummary(from text: String, sentenceCount: Int = 3) -> String {
        NLTextAnalyzer
            .importantSentences(from: text, count: sentenceCount)
            .joined(separator: " ")
    }
}
