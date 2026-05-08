import XCTest
import SwiftUI
@testable import SmartStudyPlanner

final class QuizTests: XCTestCase {

    func testQuizAttemptCalculations() {
        let question1 = QuizQuestion(number: 1, category: "Math", questionText: "1+1?", options: ["1", "2", "3", "4"], correctOptionIndex: 1, points: 10)
        let question2 = QuizQuestion(number: 2, category: "Math", questionText: "2*2?", options: ["2", "4", "6", "8"], correctOptionIndex: 1, points: 20)
        let question3 = QuizQuestion(number: 3, category: "Math", questionText: "3-1?", options: ["1", "2", "3", "4"], correctOptionIndex: 1, points: 15)
        
        let questions = [question1, question2, question3]
        
        let selectedAnswers = [
            question1.id: 1,
            question2.id: 1,
            question3.id: 0
        ]
        
        let attempt = QuizAttempt(
            quizName: "Math Test",
            topicName: "Basic Arithmetic",
            questions: questions,
            selectedAnswers: selectedAnswers,
            timeSpentSeconds: 125
        )
        
        XCTAssertEqual(attempt.correctCount, 2, "Should have 2 correct answers")
        XCTAssertEqual(attempt.scorePercent, 66, "Score percent should be (2/3) * 100 = 66")
        XCTAssertEqual(attempt.totalPoints, 45, "Total points should be 10 + 20 + 15 = 45")
        XCTAssertEqual(attempt.earnedPoints, 30, "Earned points should be 10 + 20 = 30")
        XCTAssertFalse(attempt.isPassed, "Should fail if score percent is below 70")
        XCTAssertEqual(attempt.accuracyLabel, "Medium", "Accuracy label should be Medium for 66%")
        XCTAssertEqual(attempt.timeSpentFormatted, "02:05", "125 seconds should format to 02:05")
    }

    func testQuizAttemptPerfectScore() {
        let question = QuizQuestion(number: 1, category: "Science", questionText: "Water boils at?", options: ["100C", "0C"], correctOptionIndex: 0)
        
        let attempt = QuizAttempt(
            quizName: "Science Test",
            topicName: "Physics",
            questions: [question],
            selectedAnswers: [question.id: 0],
            timeSpentSeconds: 60
        )
        
        XCTAssertEqual(attempt.scorePercent, 100, "Should have 100% score")
        XCTAssertTrue(attempt.isPassed, "Should pass with 100%")
        XCTAssertEqual(attempt.accuracyLabel, "High", "Accuracy label should be High for 100%")
    }
}
