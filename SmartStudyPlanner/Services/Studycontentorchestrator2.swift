//// StudyContentOrchestrator.swift
//// Coordinates NLTextAnalyzer (heavy lifting) + SmolLM2Service (atomic LLM tasks).
////
//// Call order:
////   1. NL extracts/clusters keywords — no token limit, instant
////   2. SmolLM2 is called ONCE PER TOPIC for a title, ONCE for a description
////   3. Everything is assembled into typed model objects
////
//// ViewModel or View calls this; it handles its own async work.
//
//import Foundation
//import Combine
//
//@MainActor
//final class StudyContentOrchestrator: ObservableObject {
//
//    // ── Shared singleton (matches existing app patterns) ──────────────────
//    static let shared = StudyContentOrchestrator()
//
//    @Published private(set) var isReady = false
//    @Published private(set) var setupError: Error?
//
//    private let llm = SmolLM2Service.shared
//
//    private init() {}
//
//    // MARK: - Lazy setup (safe to call multiple times)
//
//    func ensureReady() async {
//        guard !isReady else { return }
//        do {
//            try await llm.setup()
//            isReady = true
//            setupError = nil
//        } catch {
//            setupError = error
//            print("❌ SmolLM2 setup failed: \(error.localizedDescription)")
//        }
//    }
//
//    // MARK: - Study Path ────────────────────────────────────────────────────
//
//    /// Build a complete study path from raw uploaded text.
//    /// - Parameters:
//    ///   - text:       Raw content the user uploaded (PDF extracted text, notes, etc.)
//    ///   - topicCount: How many topics to produce (default 5)
//    /// - Returns: Ordered array of `StudyPathTopic` ready to display.
//    func buildStudyPath(from text: String,
//                        topicCount: Int = 5) async throws -> [StudyPathTopic] {
//        await ensureReady()
//        guard isReady else { throw SmolLM2Service.LLMError.notInitialized }
//
//        // ── 1. NL does the heavy work ──────────────────────────────────────
//        let keywords = NLTextAnalyzer.extractKeywords(from: text,
//                                                       max: topicCount * 5)
//        let clusters = NLTextAnalyzer.clusterKeywords(keywords,
//                                                      into: topicCount)
//
//        // ── 2. LLM gets ONE atomic call per topic ──────────────────────────
//        var topics = [StudyPathTopic]()
//        let baseWeight = 100 / topicCount
//
//        for (i, cluster) in clusters.enumerated() {
//            // Build a compact keyword string that comfortably fits in 32 tokens
//            let keyString = cluster.prefix(3).joined(separator: ", ")
//
//            // Sequential calls are deliberate — the CoreML model is not
//            // re-entrant, and the actor enforces one call at a time.
//            let title = try await llm.titleFor(keywords: keyString)
//            let desc  = try await llm.describeOneSentence(
//                topic: title.isEmpty ? keyString : title)
//
//            // Last topic absorbs rounding remainder so weights sum to 100
//            let weight = (i == clusters.count - 1)
//                ? 100 - baseWeight * (clusters.count - 1)
//                : baseWeight
//
//            topics.append(StudyPathTopic(
//                id:                UUID().uuidString,
//                order:             i + 1,
//                title:             title.isEmpty ? keyString.capitalized : title,
//                description:       desc.isEmpty  ? "Study \(keyString)"  : desc,
//                subtopics:         cluster,
//                weightPercent:     weight,
//                resourceIds:       [],
//                completionPercent: 0,
//                isCompleted:       false
//            ))
//        }
//
//        return topics
//    }
//
//    // MARK: - Quiz ──────────────────────────────────────────────────────────
//
//    /// Generate a quiz from raw text.
//    /// - Parameters:
//    ///   - text:          Source material
//    ///   - questionCount: Number of Q&A pairs (default 5)
//    func buildQuiz(from text: String,
//                   questionCount: Int = 5) async throws -> [QuizItem] {
//        await ensureReady()
//        guard isReady else { throw SmolLM2Service.LLMError.notInitialized }
//
//        let keywords = NLTextAnalyzer.extractKeywords(from: text,
//                                                       max: questionCount * 3)
//        // Shuffle for variety; pick the target number
//        let selected = Array(keywords.shuffled().prefix(questionCount))
//
//        var items = [QuizItem]()
//        for kw in selected {
//            let question = try await llm.quizQuestion(for: kw)
//            let answer   = try await llm.quizAnswer(for: kw)
//
//            items.append(QuizItem(
//                id:       UUID().uuidString,
//                question: question.isEmpty ? "What is \(kw)?" : question,
//                answer:   answer.isEmpty   ? kw               : answer,
//                keyword:  kw
//            ))
//        }
//        return items
//    }
//
//    // MARK: - Weekly Study Plan ─────────────────────────────────────────────
//    // Pure algorithmic — no LLM call needed. Topics already have weight;
//    // we distribute them across weeks proportionally.
//
//    func buildWeeklyPlan(from topics: [StudyPathTopic],
//                         weeks: Int = 4) -> [StudyWeek] {
//        guard !topics.isEmpty, weeks > 0 else { return [] }
//        let perWeek = max(1, Int(ceil(Double(topics.count) / Double(weeks))))
//        return stride(from: 0, to: topics.count, by: perWeek).map { start in
//            let slice = Array(topics[start..<min(start + perWeek, topics.count)])
//            let w     = start / perWeek + 1
//            return StudyWeek(
//                weekNumber:     w,
//                topics:         slice,
//                estimatedHours: slice.reduce(0) { $0 + max(1, $1.weightPercent / 10) }
//            )
//        }
//    }
//
//    // MARK: - Quick extractive summary (zero LLM calls, instant)
//
//    /// Returns the 3 most information-dense sentences from `text`.
//    /// Useful for a "content preview" card before building the full path.
//    func quickSummary(from text: String, sentenceCount: Int = 3) -> String {
//        NLTextAnalyzer
//            .importantSentences(from: text, count: sentenceCount)
//            .joined(separator: " ")
//    }
//}
//
//// MARK: - Result Models
//
//struct QuizItem: Identifiable, Codable {
//    let id: String
//    let question: String
//    let answer: String
//    let keyword: String
//}
//
//struct StudyWeek: Identifiable {
//    var id: Int { weekNumber }
//    let weekNumber: Int
//    let topics: [StudyPathTopic]
//    let estimatedHours: Int
//}
