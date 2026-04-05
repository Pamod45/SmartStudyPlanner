//
//  Deadline.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import Foundation
import SwiftUI

enum DeadlineTag: String, CaseIterable, Identifiable {
    case finalExam  = "#FinalExam"
    case cw         = "#CW"
    case submission = "#Submission"

    var id: String { rawValue }
}

enum DeadlineIcon: String {
    case finalExam  = "doc.plaintext"
    case cw         = "laptopcomputer"
    case submission = "tray.and.arrow.up.fill"
}

struct Deadline: Identifiable {
    let id: UUID
    var name: String
    var date: Date
    var hasReminder: Bool
    var isHighPriority: Bool
    var notes: String
    var tag: DeadlineTag
    var subjectID: UUID
    var subjectColor: Color
    var icon: String {
        if      tag == .finalExam   { return DeadlineIcon.finalExam.rawValue }
        else if tag == .cw          { return DeadlineIcon.cw.rawValue }
        else { return DeadlineIcon.submission.rawValue }
    }
    
    var color: Color {
        if isHighPriority { return .red }
        else if tag == .finalExam { return .blue }
        else if tag == .submission { return .yellow }
        else { return .brown }
            
    }

    init(
        id: UUID = UUID(),
        name: String,
        date: Date,
        hasReminder: Bool = false,
        isHighPriority: Bool = false,
        notes: String = "",
        tag: DeadlineTag,
        subjectID: UUID = UUID(),
        subjectColor: Color = .blue
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.hasReminder = hasReminder
        self.isHighPriority = isHighPriority
        self.notes = notes
        self.tag = tag
        self.subjectID = subjectID
        self.subjectColor = subjectColor
    }

    var month: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date).uppercased()
    }

    var day: Int {
        Calendar.current.component(.day, from: date)
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: date)
    }

    static func samples(for subjectID: UUID, color: Color = .blue) -> [Deadline] {
        [
            Deadline(
                name: "Lab Report",
                date: Calendar.current.date(byAdding: .day, value: 5, to: .now)!,
                hasReminder: true,
                tag: .cw,
                subjectID: subjectID,
                subjectColor: color
            ),
            Deadline(
                name: "Final Exam",
                date: Calendar.current.date(byAdding: .month, value: 1, to: .now)!,
                hasReminder: true,
                isHighPriority: true,
                tag: .finalExam,
                subjectID: subjectID,
                subjectColor: color
            )
        ]
    }

    static let dashboardSamples: [Deadline] = [
        Deadline(
            name: "Data Structures CW 1",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 18))!,
            tag: .cw,
            subjectColor: Color(hex: "#93C5FF")
        ),
        Deadline(
            name: "iOS Development Viva",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 25))!,
            isHighPriority: true,
            tag: .finalExam,
            subjectColor: Color(hex: "#F9ABFF")
        )
    ]
}
