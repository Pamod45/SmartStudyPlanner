import XCTest
@testable import SmartStudyPlanner

final class StudyPathTests: XCTestCase {

    func testStudyPathTopicCalculations() {
        // Arrange & Act
        let topic = StudyPathTopic(
            order: 1,
            title: "Physics",
            description: "Intro to Physics",
            weightPercent: 20, // estimatedMinutes should default to max(30, 20 * 6) = 120
            difficultyLevel: 15 // Should be clamped to 10
        )
        
        // Assert
        XCTAssertEqual(topic.estimatedMinutes, 120, "estimatedMinutes should default to weightPercent * 6 if not provided")
        XCTAssertEqual(topic.estimatedHours, 2, "estimatedHours should be estimatedMinutes / 60")
        XCTAssertEqual(topic.difficultyLevel, 10, "Difficulty level should be clamped to a maximum of 10")
    }

    func testStudyPathTopicMinimumDefaults() {
        // Arrange & Act
        let topic = StudyPathTopic(
            order: 1,
            title: "Math",
            description: "Intro to Math",
            weightPercent: 2, // estimatedMinutes default would be 12, but should be max(30, 12) = 30
            difficultyLevel: -5 // Should be clamped to 1
        )
        
        // Assert
        XCTAssertEqual(topic.estimatedMinutes, 30, "estimatedMinutes should be a minimum of 30")
        XCTAssertEqual(topic.estimatedHours, 1, "estimatedHours should be a minimum of 1")
        XCTAssertEqual(topic.difficultyLevel, 1, "Difficulty level should be clamped to a minimum of 1")
    }

    func testStudyPathTopicFirestoreMapping() {
        // Arrange
        let date = Date()
        let topic = StudyPathTopic(
            id: "topic123",
            subjectId: "subj1",
            userId: "user1",
            order: 5,
            title: "Biology",
            description: "Cells",
            weightPercent: 15,
            isCompleted: true,
            generatedAt: date
        )
        
        // Act
        let data = topic.firestoreData
        
        // Assert
        XCTAssertEqual(data["id"] as? String, "topic123")
        XCTAssertEqual(data["title"] as? String, "Biology")
        XCTAssertEqual(data["weightPercent"] as? Int, 15)
        XCTAssertEqual(data["isCompleted"] as? Bool, true)
        XCTAssertNotNil(data["generatedAt"] as? Date)
    }
}
