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
    let subject: String
    let title: String
    let startTime: Date
    let endTime: Date
    let subjectColor: Color
    let hasReminder: Bool

    init(
        id: UUID = UUID(),
        subject: String,
        title: String,
        startTime: Date,
        endTime: Date,
        subjectColor: Color,
        hasReminder: Bool = false
    ) {
        self.id = id
        self.subject = subject
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.subjectColor = subjectColor
        self.hasReminder = hasReminder
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
                title: "SwiftUI Layout",
                startTime: cal.date(bySettingHour: 9, minute: 0, second: 0, of: date)!,
                endTime: cal.date(bySettingHour: 9, minute: 45, second: 0, of: date)!,
                subjectColor: .cyan,
                hasReminder: false
            ),
            StudySession(
                subject: "Data Structures",
                title: "Binary Trees",
                startTime: cal.date(bySettingHour: 11, minute: 0, second: 0, of: date)!,
                endTime: cal.date(bySettingHour: 11, minute: 30, second: 0, of: date)!,
                subjectColor: .purple,
                hasReminder: true
            )
        ]
    }
}
