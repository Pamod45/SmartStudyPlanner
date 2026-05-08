import XCTest
@testable import SmartStudyPlanner

final class NotificationTests: XCTestCase {

    func testNotificationTypeProperties() {
        let studyType = NotificationType.study
        let deadlineType = NotificationType.deadline
        let streakType = NotificationType.streakAlert
        
        XCTAssertEqual(studyType.icon, "book.fill")
        XCTAssertEqual(deadlineType.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(streakType.icon, "flame.fill")
    }

    func testNotificationDateStringJustNow() {
        let now = Date()
        let notification = AppNotification(
            title: "Test",
            message: "Test Message",
            notificationType: .study,
            createdAt: now
        )
        
        let dateStr = notification.dateString
        
        XCTAssertTrue(dateStr == "Just now" || dateStr == "0min ago", "Should be Just now for newly created notification")
    }

    func testNotificationDateStringHoursAgo() {
        let calendar = Calendar.current
        let threeHoursAgo = calendar.date(byAdding: .hour, value: -3, to: Date())!
        let notification = AppNotification(
            title: "Test",
            message: "Test Message",
            notificationType: .study,
            createdAt: threeHoursAgo
        )
        
        let dateStr = notification.dateString
        
        let isExpected = dateStr == "3h ago" || dateStr == "Yesterday" || dateStr.contains("h ago")
        XCTAssertTrue(isExpected, "Should represent hours ago or yesterday")
    }
}
