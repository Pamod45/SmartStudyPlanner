//
//  StudyTopic.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-09.
//

import Foundation

struct StudyTopic: Identifiable, Equatable {
    let id: String
    let name: String
    let resources: Int
    let estimatedHours: Int

    static func samples(for subject: Subject) -> [StudyTopic] {
        let names = [
            "Linear \(subject.name)",
            "Non Linear \(subject.name)",
            "Time Complexity",
            "Advanced Topics"
        ]
        return names.enumerated().map { i, name in
            StudyTopic(id: String(i), name: name, resources: (i + 1) * 2, estimatedHours: (i + 1) * 3)
        }
    }
}
