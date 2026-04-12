//
//  QuizModels.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct QuizQuestion: Identifiable {
    let id: UUID
    var number: Int
    var category: String
    var questionText: String
    var options: [String]
    var correctOptionIndex: Int
    var expertTip: String

    init(
        id: UUID = UUID(),
        number: Int,
        category: String,
        questionText: String,
        options: [String],
        correctOptionIndex: Int,
        expertTip: String = ""
    ) {
        self.id = id
        self.number = number
        self.category = category
        self.questionText = questionText
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.expertTip = expertTip
    }
}

struct QuizAttempt: Identifiable {
    let id: UUID
    var quizName: String
    var topicName: String
    var questions: [QuizQuestion]
    var selectedAnswers: [UUID: Int]
    var completedAt: Date
    var timeSpentSeconds: Int
    var subjectColor: Color

    init(
        id: UUID = UUID(),
        quizName: String,
        topicName: String,
        questions: [QuizQuestion],
        selectedAnswers: [UUID: Int] = [:],
        completedAt: Date = Date(),
        timeSpentSeconds: Int,
        subjectColor: Color
    ) {
        self.id = id
        self.quizName = quizName
        self.topicName = topicName
        self.questions = questions
        self.selectedAnswers = selectedAnswers
        self.completedAt = completedAt
        self.timeSpentSeconds = timeSpentSeconds
        self.subjectColor = subjectColor
    }

    var correctCount: Int {
        questions.filter { selectedAnswers[$0.id] == $0.correctOptionIndex }.count
    }

    var scorePercent: Int {
        guard !questions.isEmpty else { return 0 }
        return correctCount * 100 / questions.count
    }

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

    static func samples(for subjectID: UUID, color: Color) -> [QuizAttempt] {
        let q1 = sampleQuestions(category: "SwiftUI Essentials")
        let q2 = sampleQuestions(category: "State Management")
        let q3 = sampleQuestions(category: "Concurrency")

        var a1: [UUID: Int] = [:]
        var a2: [UUID: Int] = [:]
        var a3: [UUID: Int] = [:]
        for (i, q) in q1.enumerated() { a1[q.id] = i == 0 ? (q.correctOptionIndex + 1) % 4 : q.correctOptionIndex }
        for q in q2 { a2[q.id] = q.correctOptionIndex }
        for (i, q) in q3.enumerated() { a3[q.id] = i == 1 ? (q.correctOptionIndex + 1) % 4 : q.correctOptionIndex }

        return [
            QuizAttempt(quizName: "SwiftUI Layout", topicName: "SwiftUI Layout",
                        questions: q1, selectedAnswers: a1,
                        completedAt: Date().addingTimeInterval(-86400 * 18),
                        timeSpentSeconds: 760, subjectColor: color),
            QuizAttempt(quizName: "State Mgmt", topicName: "State Management",
                        questions: q2, selectedAnswers: a2,
                        completedAt: Date().addingTimeInterval(-86400 * 21),
                        timeSpentSeconds: 1095, subjectColor: color),
            QuizAttempt(quizName: "Concurrency", topicName: "Concurrency",
                        questions: q3, selectedAnswers: a3,
                        completedAt: Date().addingTimeInterval(-86400 * 27),
                        timeSpentSeconds: 535, subjectColor: color)
        ]
    }

    static func sampleQuestions(category: String) -> [QuizQuestion] {
        [
            QuizQuestion(number: 1, category: category,
                         questionText: "Which design principle emphasizes depth?",
                         options: ["Flat Design", "Luminous Depth", "Material Design", "Neumorphism"],
                         correctOptionIndex: 1,
                         expertTip: "Luminous Depth uses layering and lighting to create a sense of depth."),
            QuizQuestion(number: 2, category: category,
                         questionText: "What is the primary surface color?",
                         options: ["#000000", "#1C1C1E", "#131313", "#1A1A2E"],
                         correctOptionIndex: 2,
                         expertTip: "Surface colors define the background of cards and containers."),
            QuizQuestion(number: 3, category: category,
                         questionText: "What font is used for display text?",
                         options: ["SF Pro", "Roboto Serif", "Helvetica", "Inter"],
                         correctOptionIndex: 3,
                         expertTip: "Inter is a popular choice for clean UI typography.")
        ]
    }

    static func generateQuestions(from topics: [StudyPathTopic], resources: [Resource], count: Int) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        let category = topics.first?.title ?? "General"
        let base = QuizAttempt.sampleQuestions(category: category)
        var i = 0
        while questions.count < count {
            var q = base[i % base.count]
            q = QuizQuestion(id: UUID(), number: questions.count + 1,
                             category: q.category, questionText: q.questionText,
                             options: q.options, correctOptionIndex: q.correctOptionIndex,
                             expertTip: q.expertTip)
            questions.append(q)
            i += 1
        }
        return questions
    }
}
