import XCTest
@testable import SmartStudyPlanner

final class StudyScheduleServiceTests: XCTestCase {

    var service: StudyScheduleService!

    override func setUp() {
        super.setUp()
        // Accessing the singleton instance
        service = StudyScheduleService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testScheduleGeneratesCorrectSessions() {
        // Arrange
        let subject = Subject(id: "subj1", name: "Mathematics")
        let topic1 = StudyPathTopic(order: 1, title: "Algebra", description: "", weightPercent: 10, estimatedMinutes: 60)
        let topic2 = StudyPathTopic(order: 2, title: "Calculus", description: "", weightPercent: 20, estimatedMinutes: 45)
        
        let entries = [
            StudyScheduleService.SubjectEntry(subject: subject, topics: [topic1, topic2], nearestDeadline: Date().addingTimeInterval(86400 * 2))
        ]
        
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let todayEnd = cal.date(byAdding: .day, value: 1, to: todayStart)!
        
        // 2 hours slot today
        let slotStart = cal.date(bySettingHour: 10, minute: 0, second: 0, of: todayStart)!
        let slotEnd = cal.date(bySettingHour: 12, minute: 0, second: 0, of: todayStart)!
        let slot = AvailabilitySlot(type: .specificDate, startTime: slotStart, endTime: slotEnd, date: todayStart)
        
        let period = DateInterval(start: todayStart, end: todayEnd)
        
        // Act
        let sessions = service.schedule(entries: entries, slots: [slot], period: period, breakMinutes: 10, minSessionMinutes: 30)
        
        // Assert
        XCTAssertFalse(sessions.isEmpty, "Should generate at least one study session")
        
        let totalDuration = sessions.reduce(0) { $0 + Int($1.endTime.timeIntervalSince($1.startTime) / 60) }
        XCTAssertEqual(totalDuration, 105, "Total scheduled time should match the 105 minutes estimated (60 + 45)")
        
        // Check break time between sessions
        if sessions.count >= 2 {
            let session1 = sessions[0]
            let session2 = sessions[1]
            let breakDuration = Int(session2.startTime.timeIntervalSince(session1.endTime) / 60)
            XCTAssertEqual(breakDuration, 10, "Break between sessions should be exactly 10 minutes")
        }
    }

    func testScheduleWithInsufficientTime() {
        // Arrange
        let subject = Subject(id: "subj1", name: "Physics")
        let topic = StudyPathTopic(order: 1, title: "Quantum Mechanics", description: "", weightPercent: 50, estimatedMinutes: 120)
        
        let entries = [
            StudyScheduleService.SubjectEntry(subject: subject, topics: [topic], nearestDeadline: nil)
        ]
        
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        
        // Only 15 mins available
        let slotStart = cal.date(bySettingHour: 10, minute: 0, second: 0, of: todayStart)!
        let slotEnd = cal.date(bySettingHour: 10, minute: 15, second: 0, of: todayStart)!
        let slot = AvailabilitySlot(type: .specificDate, startTime: slotStart, endTime: slotEnd, date: todayStart)
        
        let period = DateInterval(start: todayStart, end: todayStart)
        
        // Act
        let sessions = service.schedule(entries: entries, slots: [slot], period: period, breakMinutes: 10, minSessionMinutes: 30)
        
        // Assert
        XCTAssertTrue(sessions.isEmpty, "Should not generate sessions if available slot is less than minSessionMinutes")
    }
}
