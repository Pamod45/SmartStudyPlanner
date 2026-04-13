import SwiftUI

enum QuizType: String, Codable {
    case multipleChoice
    case trueFalse
    case flashcard
    case mixed
}

enum QuizDifficulty: String, Codable {
    case easy
    case medium
    case hard
    case adaptive
}

enum QuestionType: String, Codable {
    case multipleChoice
    case trueFalse
    case flashcard
    case shortAnswer
}

struct QuizOption: Identifiable, Codable {
    var id: String
    var text: String
    var isCorrect: Bool

    init(id: String = UUID().uuidString, text: String, isCorrect: Bool) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
    }
}

struct QuizQuestion: Identifiable, Codable {
    var id: String
    var number: Int
    var category: String
    var questionText: String
    var questionType: QuestionType
    var options: [String]
    var correctOptionIndex: Int
    var expertTip: String
    var hint: String?
    var points: Int

    init(
        id: String = UUID().uuidString,
        number: Int,
        category: String,
        questionText: String,
        questionType: QuestionType = .multipleChoice,
        options: [String],
        correctOptionIndex: Int,
        expertTip: String = "",
        hint: String? = nil,
        points: Int = 1
    ) {
        self.id = id
        self.number = number
        self.category = category
        self.questionText = questionText
        self.questionType = questionType
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.expertTip = expertTip
        self.hint = hint
        self.points = points
    }
}

struct QuizAnswer: Identifiable, Codable {
    var id: String
    var questionId: String
    var selectedOptionIndex: Int?
    var isCorrect: Bool
    var timeTakenSeconds: Int

    init(
        id: String = UUID().uuidString,
        questionId: String,
        selectedOptionIndex: Int? = nil,
        isCorrect: Bool = false,
        timeTakenSeconds: Int = 0
    ) {
        self.id = id
        self.questionId = questionId
        self.selectedOptionIndex = selectedOptionIndex
        self.isCorrect = isCorrect
        self.timeTakenSeconds = timeTakenSeconds
    }
}

struct QuizAttempt: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var quizId: String
    var quizName: String
    var topicName: String
    var subjectId: String
    var subjectColorHex: String
    var questions: [QuizQuestion]
    var selectedAnswers: [String: Int]
    var answers: [QuizAnswer]
    var timeSpentSeconds: Int
    var completedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var subjectColor: Color {
        Color(hex: subjectColorHex)
    }

    var correctCount: Int {
        questions.filter { selectedAnswers[$0.id] == $0.correctOptionIndex }.count
    }

    var scorePercent: Int {
        guard !questions.isEmpty else { return 0 }
        return correctCount * 100 / questions.count
    }

    var score: Double {
        Double(scorePercent)
    }

    var totalPoints: Int {
        questions.reduce(0) { $0 + $1.points }
    }

    var earnedPoints: Int {
        questions.filter { selectedAnswers[$0.id] == $0.correctOptionIndex }.reduce(0) { $0 + $1.points }
    }

    var isPassed: Bool { scorePercent >= 70 }

    var timeSpentFormatted: String {
        let m = timeSpentSeconds / 60
        let s = timeSpentSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var accuracyLabel: String {
        let p = scorePercent
        if p >= 85 { return "High" }
        if p >= 60 { return "Medium" }
        return "Low"
    }

    var accuracyColor: Color {
        let p = scorePercent
        if p >= 85 { return .green }
        if p >= 60 { return .orange }
        return Color(red: 1, green: 0.45, blue: 0.45)
    }

    var resultTitle: String {
        let p = scorePercent
        if p >= 85 { return "Excellent Work!" }
        if p >= 60 { return "Good Job!" }
        return "Keep Practicing!"
    }

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: completedAt)
    }

    var durationFormatted: String {
        let m = timeSpentSeconds / 60
        let s = timeSpentSeconds % 60
        return String(format: "%dm %02ds", m, s)
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        quizId: String = "",
        quizName: String,
        topicName: String,
        subjectId: String = "",
        subjectColorHex: String = "#3B82F6",
        questions: [QuizQuestion],
        selectedAnswers: [String: Int] = [:],
        answers: [QuizAnswer] = [],
        timeSpentSeconds: Int,
        completedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.quizId = quizId
        self.quizName = quizName
        self.topicName = topicName
        self.subjectId = subjectId
        self.subjectColorHex = subjectColorHex
        self.questions = questions
        self.selectedAnswers = selectedAnswers
        self.answers = answers
        self.timeSpentSeconds = timeSpentSeconds
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}

struct Quiz: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var subjectId: String
    var topicId: String?
    var title: String
    var description: String?
    var questions: [QuizQuestion]
    var quizType: QuizType
    var difficulty: QuizDifficulty
    var timeLimitMinutes: Int?
    var isAIGenerated: Bool
    var sourceResourceId: String?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        subjectId: String = "",
        topicId: String? = nil,
        title: String,
        description: String? = nil,
        questions: [QuizQuestion] = [],
        quizType: QuizType = .multipleChoice,
        difficulty: QuizDifficulty = .medium,
        timeLimitMinutes: Int? = nil,
        isAIGenerated: Bool = false,
        sourceResourceId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.subjectId = subjectId
        self.topicId = topicId
        self.title = title
        self.description = description
        self.questions = questions
        self.quizType = quizType
        self.difficulty = difficulty
        self.timeLimitMinutes = timeLimitMinutes
        self.isAIGenerated = isAIGenerated
        self.sourceResourceId = sourceResourceId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
