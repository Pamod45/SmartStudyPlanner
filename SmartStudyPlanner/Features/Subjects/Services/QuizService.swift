import Foundation
import Combine
import FirebaseFirestore

// Saves and loads completed quiz attempts for the workspace quiz history.
// Generated questions are created elsewhere; this service persists the finished attempts.

class QuizService {
    static let shared = QuizService()
    private let db = Firestore.firestore()

    private init() {}

    // Stores a completed attempt with its questions and selected answers, then caches the synced copy.
    func saveAttempt(_ attempt: QuizAttempt, userId: String) async throws {
        let questionsEncoded = try attempt.questions.map { q -> [String: Any] in
            [
                "id": q.id,
                "number": q.number,
                "category": q.category,
                "questionText": q.questionText,
                "questionType": q.questionType.rawValue,
                "options": q.options,
                "correctOptionIndex": q.correctOptionIndex,
                "expertTip": q.expertTip,
                "keyword": q.keyword,
                "hint": q.hint as Any,
                "points": q.points
            ]
        }

        let selectedAnswersEncoded: [String: Int] = attempt.selectedAnswers

        let data: [String: Any] = [
            "id": attempt.id,
            "subjectId": attempt.subjectId,
            "userId": userId,
            "quizName": attempt.quizName,
            "topicName": attempt.topicName,
            "questions": questionsEncoded,
            "selectedAnswers": selectedAnswersEncoded,
            "scorePercent": attempt.scorePercent,
            "timeSpentSeconds": attempt.timeSpentSeconds,
            "completedAt": Timestamp(date: attempt.completedAt),
            "syncStatus": SyncStatus.synced.rawValue
        ]

        try await db.collection("quizAttempts").document(attempt.id).setData(data, merge: true)

        var synced = attempt
        synced.syncStatus = .synced
        CoreDataService.shared.upsertAttempt(synced)
    }

    // Loads attempts for a subject, rebuilds questions from Firestore data, and returns newest first.
    func fetchAttempts(subjectId: String) async throws -> [QuizAttempt] {
        let snapshot = try await db.collection("quizAttempts")
            .whereField("subjectId", isEqualTo: subjectId)
            .getDocuments()

        let attempts = snapshot.documents.compactMap { doc -> QuizAttempt? in
            let data = doc.data()

            guard let id         = data["id"]           as? String,
                  let quizName   = data["quizName"]     as? String,
                  let topicName  = data["topicName"]    as? String,
                  let subjectId  = data["subjectId"]    as? String else { return nil }

            let userId        = data["userId"]           as? String ?? ""
            let scorePercent  = data["scorePercent"]     as? Int    ?? 0
            let timeSpent     = data["timeSpentSeconds"] as? Int    ?? 0
            let completedAt   = (data["completedAt"]     as? Timestamp)?.dateValue() ?? Date()
            let syncStatusRaw = data["syncStatus"]       as? String ?? ""
            let syncStatus    = SyncStatus(rawValue: syncStatusRaw) ?? .synced

            let questionsRaw  = data["questions"]        as? [[String: Any]] ?? []
            let questions: [QuizQuestion] = questionsRaw.compactMap { q in
                guard
                    let qId   = q["id"]              as? String,
                    let text  = q["questionText"]    as? String,
                    let opts  = q["options"]         as? [String],
                    let cIdx  = q["correctOptionIndex"] as? Int,
                    let cat   = q["category"]        as? String
                else { return nil }

                let qtRaw    = q["questionType"] as? String ?? "multipleChoice"
                let qt       = QuestionType(rawValue: qtRaw) ?? .multipleChoice
                let tip      = q["expertTip"]    as? String ?? ""
                let keyword  = q["keyword"]      as? String ?? ""
                let hint     = q["hint"]         as? String
                let pts      = q["points"]       as? Int    ?? 1
                let number   = q["number"]       as? Int    ?? 0

                return QuizQuestion(
                    id: qId,
                    number: number,
                    category: cat,
                    questionText: text,
                    questionType: qt,
                    options: opts,
                    correctOptionIndex: cIdx,
                    expertTip: tip,
                    keyword: keyword,
                    hint: hint,
                    points: pts
                )
            }

            let selectedAnswers = data["selectedAnswers"] as? [String: Int] ?? [:]

            return QuizAttempt(
                id: id,
                userId: userId,
                quizName: quizName,
                topicName: topicName,
                subjectId: subjectId,
                questions: questions,
                selectedAnswers: selectedAnswers,
                timeSpentSeconds: timeSpent,
                completedAt: completedAt,
                syncStatus: syncStatus
            )
        }
        attempts.forEach { CoreDataService.shared.upsertAttempt($0) }

        return attempts.sorted { $0.completedAt > $1.completedAt }
    }

    // Removes one saved attempt from Firestore and the local cache.
    func deleteAttempt(id: String) async throws {
        try await db.collection("quizAttempts").document(id).delete()
        CoreDataService.shared.deleteAttempt(id: id)
    }

    // Deletes a batch of attempts, used when removing an entire quiz history group.
    func deleteAttempts(ids: [String]) async throws {
        guard !ids.isEmpty else { return }

        let batch = db.batch()
        for id in ids {
            batch.deleteDocument(db.collection("quizAttempts").document(id))
        }
        try await batch.commit()

        ids.forEach { CoreDataService.shared.deleteAttempt(id: $0) }
    }
}
