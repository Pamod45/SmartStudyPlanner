import Foundation
import Combine

// Coordinates subject workspace AI generation through the selected LLM backend.
// Resource text extraction happens before this service is called.

@MainActor
final class StudyContentOrchestrator: ObservableObject {

    static let shared = StudyContentOrchestrator()

    private let hostedServerURL = URL(string: "http://192.168.42.21:8080/v1/chat/completions")!
//    private let hostedServerURL = URL(string: "http://192.168.1.21:8080/v1/chat/completions")!
//    private let ragStudyPathURL = URL(string: "http://192.168.1.21:8081/generate/study-path")!
//    private let ragQuizURL = URL(string: "http://192.168.1.21:8081/generate/quiz")!

    @Published private(set) var isGenerating = false
    @Published private(set) var error: Error?

    private lazy var backend: StudyLLMBackend = {
        LLMBackendSelector.resolve(hostedURL: hostedServerURL)
    }()

    private init() {}

    // Turns extracted resource text into study path topics that can be saved by StudyPathService.
    func buildStudyPath(from text: String,
                        topicCount: Int = 5) async throws -> [StudyPathTopic] {
        isGenerating = true
        error = nil
        defer { isGenerating = false }

        do {
            let result = try await Task.detached {
                try await self.backend.generateStudyPath(from: text, topicCount: topicCount)
            }.value

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

    // Turns selected topic/resource text into multiple-choice questions for a new quiz attempt.
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
            let result = try await Task.detached {
                try await self.backend.generateQuizQuestions(
                    from: text,
                    questionCount: clamped,
                    category: category
                )
            }.value

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


    // Local fallback summary helper that does not call the LLM backend.
    func quickSummary(from text: String, sentenceCount: Int = 3) -> String {
        NLTextAnalyzer
            .importantSentences(from: text, count: sentenceCount)
            .joined(separator: " ")
    }
}
