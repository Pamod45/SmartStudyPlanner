//
//  StudySession.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import Foundation
import SwiftUI

struct StudySession: Identifiable {
    let id: UUID
    let subjectID: UUID
    let subject: String
    let topic: String
    let title: String
    let startTime: Date
    let endTime: Date
    let subjectColor: Color
    let hasReminder: Bool
    let resourceIDs: [UUID]

    init(
        id: UUID = UUID(),
        subjectID: UUID = UUID(),
        subject: String,
        topic: String = "",
        title: String,
        startTime: Date,
        endTime: Date,
        subjectColor: Color,
        hasReminder: Bool = false,
        resourceIDs: [UUID] = []
    ) {
        self.id = id
        self.subjectID = subjectID
        self.subject = subject
        self.topic = topic
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.subjectColor = subjectColor
        self.hasReminder = hasReminder
        self.resourceIDs = resourceIDs
    }

    var timeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return "\(f.string(from: startTime)) - \(f.string(from: endTime))"
    }

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var duration: String {
        "\(durationMinutes) min"
    }

    var startHour: CGFloat {
        let cal = Calendar.current
        let hour = CGFloat(cal.component(.hour, from: startTime))
        let minute = CGFloat(cal.component(.minute, from: startTime))
        return hour + minute / 60.0
    }

    var endHour: CGFloat {
        let cal = Calendar.current
        let hour = CGFloat(cal.component(.hour, from: endTime))
        let minute = CGFloat(cal.component(.minute, from: endTime))
        return hour + minute / 60.0
    }

    static func makeSamples(for date: Date = .now) -> [StudySession] {
        let cal = Calendar.current
        return [
            StudySession(
                subject: "iOS Development",
                topic: "SwiftUI Layout",
                title: "SwiftUI Layout",
                startTime: cal.date(bySettingHour: 9, minute: 0, second: 0, of: date)!,
                endTime: cal.date(bySettingHour: 9, minute: 45, second: 0, of: date)!,
                subjectColor: .cyan,
                hasReminder: false
            ),
            StudySession(
                subject: "Data Structures",
                topic: "Binary Trees",
                title: "Binary Trees",
                startTime: cal.date(bySettingHour: 11, minute: 0, second: 0, of: date)!,
                endTime: cal.date(bySettingHour: 11, minute: 30, second: 0, of: date)!,
                subjectColor: .purple,
                hasReminder: true
            )
        ]
    }

    static let planSamples: [StudySession] = {
        let cal = Calendar.current
        let apr9  = cal.date(from: DateComponents(year: 2026, month: 4, day: 9))!
        let apr11 = cal.date(from: DateComponents(year: 2026, month: 4, day: 11))!
        return [
            StudySession(
                subject: "iOS Development",
                topic: "SwiftUI Layouts & Navigation",
                title: "SwiftUI Layouts & Navigation",
                startTime: cal.date(bySettingHour: 10, minute: 0, second: 0, of: apr9)!,
                endTime:   cal.date(bySettingHour: 11, minute: 30, second: 0, of: apr9)!,
                subjectColor: .blue,
                hasReminder: true
            ),
            StudySession(
                subject: "Data Structures",
                topic: "Binary Trees & Traversals",
                title: "Binary Trees & Traversals",
                startTime: cal.date(bySettingHour: 13, minute: 0, second: 0, of: apr9)!,
                endTime:   cal.date(bySettingHour: 14, minute: 0, second: 0, of: apr9)!,
                subjectColor: .purple,
                hasReminder: false
            ),
            StudySession(
                subject: "Algorithms",
                topic: "Time Complexity & Big-O",
                title: "Time Complexity & Big-O",
                startTime: cal.date(bySettingHour: 11, minute: 0, second: 0, of: apr11)!,
                endTime:   cal.date(bySettingHour: 12, minute: 30, second: 0, of: apr11)!,
                subjectColor: .orange,
                hasReminder: false
            )
        ]
    }()
}
