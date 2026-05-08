import XCTest
@testable import SmartStudyPlanner

// @MainActor ensures every test and its ObservableObject lifetimes stay on the
// main thread, preventing the Combine publisher double-free seen on iOS 26.2.
@MainActor
final class ProgressTests: XCTestCase {

    // MARK: - WeeklyProgressSnapshot.goalCompletionPercentage

    func testWeeklySnapshotGoalCompletionPercentageClamps() {
        let zeroPlan = WeeklyProgressSnapshot(totalHoursStudied: 5, goalHours: 0)
        XCTAssertEqual(zeroPlan.goalCompletionPercentage, 0.0,
                       "Percentage should be 0 when goalHours is 0 to avoid division by zero")

        let halfDone = WeeklyProgressSnapshot(totalHoursStudied: 5, goalHours: 10)
        XCTAssertEqual(halfDone.goalCompletionPercentage, 50.0, accuracy: 0.01,
                       "Percentage should be 50 when half the goal is completed")

        let overDone = WeeklyProgressSnapshot(totalHoursStudied: 15, goalHours: 10)
        XCTAssertEqual(overDone.goalCompletionPercentage, 100.0,
                       "Percentage must clamp to 100 even when hours exceed the goal")
    }

    // MARK: - ProgressViewModel.subjectDistribution

    func testSubjectDistributionIsEmptyWithNoCompletedSessions() {
        let distribution = ProgressViewModel.subjectDistribution(from: [])

        XCTAssertTrue(distribution.isEmpty,
                      "Distribution should be empty when there are no completed sessions")
    }

    func testSubjectDistributionPercentagesMatchStudyTime() {
        let cal  = Calendar.current
        let base = cal.startOfDay(for: Date())
        // Algebra: 60 min (9:00–10:00)
        let aStart = cal.date(bySettingHour: 9,  minute: 0,  second: 0, of: base)!
        let aEnd   = cal.date(bySettingHour: 10, minute: 0,  second: 0, of: base)!
        // Biology: 30 min (10:00–10:30) — exactly half of Algebra → 2:1 ratio, 66.6% / 33.3%
        let bStart = cal.date(bySettingHour: 10, minute: 0,  second: 0, of: base)!
        let bEnd   = cal.date(bySettingHour: 10, minute: 30, second: 0, of: base)!

        let sessionA = StudySession(subjectId: "s-a", subjectName: "Algebra",
                                    title: "Algebra 1", startTime: aStart, endTime: aEnd,
                                    status: .completed)
        let sessionB = StudySession(subjectId: "s-b", subjectName: "Biology",
                                    title: "Biology 1", startTime: bStart, endTime: bEnd,
                                    status: .completed)

        let distribution = ProgressViewModel.subjectDistribution(from: [sessionA, sessionB])
        XCTAssertEqual(distribution.count, 2, "Distribution should have one entry per subject")

        let algebraEntry = try? XCTUnwrap(distribution.first { $0.name == "Algebra" })
        let biologyEntry = try? XCTUnwrap(distribution.first { $0.name == "Biology" })

        // Total = 90 min. Algebra = 60/90 = 2/3, Biology = 30/90 = 1/3
        XCTAssertEqual(algebraEntry?.percentage ?? 0, 2.0 / 3.0, accuracy: 0.01,
                       "Algebra should account for 2/3 of total study time")
        XCTAssertEqual(biologyEntry?.percentage ?? 0, 1.0 / 3.0, accuracy: 0.01,
                       "Biology should account for 1/3 of total study time")

        XCTAssertEqual(distribution.first?.name, "Algebra",
                       "Subject with more study time should appear first (sorted descending)")
    }

    // MARK: - ProgressViewModel.computeStreak
    // computeStreak is a static func — no ViewModel instance required, no Combine lifecycle.

    func testStreakIsZeroForEmptySessions() {
        let result = ProgressViewModel.computeStreak(from: [])

        XCTAssertEqual(result.currentStreak, 0)
        XCTAssertEqual(result.longestStreak, 0)
        XCTAssertNil(result.lastStudyDate)
    }

    func testStreakCountsConsecutiveDaysAndResetsOnGap() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func session(daysAgo: Int) -> StudySession {
            let date  = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let start = cal.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
            let end   = cal.date(bySettingHour: 11, minute: 0, second: 0, of: date)!
            return StudySession(subjectName: "Maths", title: "Study",
                                scheduledDate: date, startTime: start, endTime: end,
                                status: .completed)
        }

        // Current run: today + yesterday = 2 days
        // Earlier run: days 5,6,7,8 ago = 4 consecutive days (longest)
        let sessions = [
            session(daysAgo: 0),
            session(daysAgo: 1),
            session(daysAgo: 5),
            session(daysAgo: 6),
            session(daysAgo: 7),
            session(daysAgo: 8)
        ]

        let result = ProgressViewModel.computeStreak(from: sessions)

        XCTAssertEqual(result.currentStreak, 2,
                       "Current streak should be 2 — today and yesterday only, gap at day-2 resets it")
        XCTAssertEqual(result.longestStreak, 4,
                       "Longest streak should be 4 from the consecutive days-5 through days-8 block")
    }
}
