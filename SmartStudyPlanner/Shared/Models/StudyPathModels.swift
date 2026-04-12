//
//  StudyPathModels.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct StudyPathTopic: Identifiable {
    let id: UUID
    var order: Int
    var title: String
    var description: String
    var subtopics: [String]
    var weightPercent: Int
    var resources: [Resource]
    var completionPercent: Int
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        description: String,
        subtopics: [String] = [],
        weightPercent: Int,
        resources: [Resource] = [],
        completionPercent: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.description = description
        self.subtopics = subtopics
        self.weightPercent = weightPercent
        self.resources = resources
        self.completionPercent = completionPercent
        self.isCompleted = isCompleted
    }
}

struct StudyPath: Identifiable {
    let id: UUID
    var subjectID: UUID
    var topics: [StudyPathTopic]
    var generatedFromResourceIDs: [UUID]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        subjectID: UUID,
        topics: [StudyPathTopic],
        generatedFromResourceIDs: [UUID],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.subjectID = subjectID
        self.topics = topics
        self.generatedFromResourceIDs = generatedFromResourceIDs
        self.createdAt = createdAt
    }

    static func generate(for subject: Subject, using resources: [Resource]) -> StudyPath {
        let topics: [StudyPathTopic] = [
            StudyPathTopic(
                order: 1,
                title: "Swift Basics",
                description: "Variables, Optionals, and Control Flow",
                subtopics: [],
                weightPercent: 20,
                resources: resources.filter { $0.type == .pdf || $0.type == .note },
                completionPercent: 100,
                isCompleted: true
            ),
            StudyPathTopic(
                order: 2,
                title: "SwiftUI Layout",
                description: "Mastering the layout engine",
                subtopics: ["Stacks (VStack, HStack, ZStack)", "Alignment Guides", "Spacing & Padding"],
                weightPercent: 45,
                resources: resources.filter { $0.type == .ppt || $0.type == .doc },
                completionPercent: 45,
                isCompleted: false
            ),
            StudyPathTopic(
                order: 3,
                title: "State Management",
                description: "@State, @Binding, and @ObservedObject",
                subtopics: [],
                weightPercent: 35,
                resources: resources.filter { $0.type == .link || $0.type == .recording },
                completionPercent: 35,
                isCompleted: false
            )
        ]
        return StudyPath(
            subjectID: subject.id,
            topics: topics,
            generatedFromResourceIDs: resources.map { $0.id }
        )
    }
}
