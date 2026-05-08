import XCTest
@testable import SmartStudyPlanner

final class StudyPlanTests: XCTestCase {

    func testAvailabilitySlotAppliesOnSpecificDateAndNotOtherDays() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        let slot = AvailabilitySlot(
            type: .specificDate,
            startTime: cal.date(bySettingHour: 9,  minute: 0, second: 0, of: today)!,
            endTime:   cal.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
            date: today
        )

        XCTAssertTrue(slot.applies(on: today),      "Slot must apply on its own date")
        XCTAssertFalse(slot.applies(on: tomorrow),  "Slot must not apply on a different day")
        XCTAssertFalse(slot.applies(on: yesterday), "Slot must not apply on a past day")
    }

    func testAvailabilitySlotAppliesWithinDateRangeBoundaries() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 3, to: start)!
        let mid   = cal.date(byAdding: .day, value: 1, to: start)!
        let before = cal.date(byAdding: .day, value: -1, to: start)!
        let after  = cal.date(byAdding: .day, value: 4,  to: start)!

        let slot = AvailabilitySlot(
            type: .dateRange,
            startTime: cal.date(bySettingHour: 9,  minute: 0, second: 0, of: start)!,
            endTime:   cal.date(bySettingHour: 11, minute: 0, second: 0, of: start)!,
            date: nil,
            rangeStart: start,
            rangeEnd: end
        )

        XCTAssertTrue(slot.applies(on: start), "Range slot must apply on the first day")
        XCTAssertTrue(slot.applies(on: end),   "Range slot must apply on the last day")
        XCTAssertTrue(slot.applies(on: mid),   "Range slot must apply on a day inside the range")
        XCTAssertFalse(slot.applies(on: before), "Range slot must not apply before the range start")
        XCTAssertFalse(slot.applies(on: after),  "Range slot must not apply after the range end")
    }

    func testStudySessionComputedDurationProperties() {
        let cal = Calendar.current
        let base  = cal.startOfDay(for: Date())
        let start = cal.date(bySettingHour: 10, minute: 0,  second: 0, of: base)!
        let end   = cal.date(bySettingHour: 11, minute: 30, second: 0, of: base)!

        let session = StudySession(
            subjectName: "Mathematics",
            title: "Algebra",
            startTime: start,
            endTime: end
        )

        XCTAssertEqual(session.durationMinutes, 90,    "durationMinutes should be 90 for a 10:00–11:30 session")
        XCTAssertEqual(session.duration, "90 min",     "duration string should include the minute count")
        XCTAssertEqual(session.startHour, 10.0, accuracy: 0.01, "startHour should be 10.0")
        XCTAssertEqual(session.endHour,   11.5, accuracy: 0.01, "endHour should be 11.5 (11:30)")
    }

    func testStudyPlanProgressPercentageClampsAtHundred() {
        let zeroPlan = StudyPlan(title: "Zero Target", targetHours: 0, completedHours: 5)
        XCTAssertEqual(zeroPlan.progressPercentage, 0.0,
                       "Progress should be 0 when targetHours is 0 to avoid division by zero")

        let halfPlan = StudyPlan(title: "Half Done", targetHours: 10, completedHours: 5)
        XCTAssertEqual(halfPlan.progressPercentage, 50.0, accuracy: 0.01,
                       "Progress should be 50% when half the target hours are completed")

        let overPlan = StudyPlan(title: "Overdone", targetHours: 10, completedHours: 15)
        XCTAssertEqual(overPlan.progressPercentage, 100.0,
                       "Progress must clamp to 100 even when completedHours exceeds targetHours")
    }

    func testSchedulerPrioritizesTopicWithNearerDeadline() {
        let service = StudyScheduleService.shared

        let subjectA = Subject(id: "subj-urgent",  name: "Urgent Subject")
        let subjectB = Subject(id: "subj-relaxed", name: "Relaxed Subject")

        // Identical topics so only deadline pressure differentiates priority.
        let topicA = StudyPathTopic(order: 1, title: "Urgent Topic",  description: "", weightPercent: 20, estimatedMinutes: 30)
        let topicB = StudyPathTopic(order: 1, title: "Relaxed Topic", description: "", weightPercent: 20, estimatedMinutes: 30)

        let entries = [
            StudyScheduleService.SubjectEntry(subject: subjectA, topics: [topicA],
                                              nearestDeadline: Date().addingTimeInterval(86_400)),       // 1 day
            StudyScheduleService.SubjectEntry(subject: subjectB, topics: [topicB],
                                              nearestDeadline: Date().addingTimeInterval(86_400 * 60))   // 60 days
        ]

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let slotStart = cal.date(bySettingHour: 9,  minute: 0, second: 0, of: today)!
        let slotEnd   = cal.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        let slot = AvailabilitySlot(type: .specificDate, startTime: slotStart, endTime: slotEnd, date: today)
        let period = DateInterval(start: today, end: cal.date(byAdding: .day, value: 1, to: today)!)

        let sessions = service.schedule(entries: entries, slots: [slot], period: period, breakMinutes: 5, minSessionMinutes: 30)

        XCTAssertEqual(sessions.count, 2, "Both topics should be scheduled into the available block")
        XCTAssertEqual(sessions.first?.subjectId, subjectA.id,
                       "The subject with the nearer deadline should be scheduled first")
    }

    func testSchedulerSpreadsTopicAcrossMultipleBlocks() {
        let service = StudyScheduleService.shared

        let subject = Subject(id: "subj-long", name: "Long Topic Subject")
        // 90-minute topic, but each daily slot is only 60 minutes.
        let topic = StudyPathTopic(order: 1, title: "Long Topic", description: "", weightPercent: 30, estimatedMinutes: 90)

        let entries = [
            StudyScheduleService.SubjectEntry(subject: subject, topics: [topic], nearestDeadline: nil)
        ]

        let cal   = Calendar.current
        let day1  = cal.startOfDay(for: Date())
        let day2  = cal.date(byAdding: .day, value: 1, to: day1)!

        let slot1 = AvailabilitySlot(
            type: .specificDate,
            startTime: cal.date(bySettingHour: 10, minute: 0, second: 0, of: day1)!,
            endTime:   cal.date(bySettingHour: 11, minute: 0, second: 0, of: day1)!,
            date: day1
        )
        let slot2 = AvailabilitySlot(
            type: .specificDate,
            startTime: cal.date(bySettingHour: 10, minute: 0, second: 0, of: day2)!,
            endTime:   cal.date(bySettingHour: 11, minute: 0, second: 0, of: day2)!,
            date: day2
        )

        let period = DateInterval(start: day1, end: cal.date(byAdding: .day, value: 2, to: day1)!)

        let sessions = service.schedule(
            entries: entries,
            slots: [slot1, slot2],
            period: period,
            breakMinutes: 5,
            minSessionMinutes: 30
        )

        XCTAssertEqual(sessions.count, 2, "A 90-min topic should be split across two 60-min blocks")
        let total = sessions.reduce(0) { $0 + $1.durationMinutes }
        XCTAssertEqual(total, 90, "Total scheduled time must equal the topic's estimated 90 minutes")
        XCTAssertTrue(sessions.allSatisfy { $0.topic == "Long Topic" },
                      "Both sessions must reference the same topic")
    }
}
