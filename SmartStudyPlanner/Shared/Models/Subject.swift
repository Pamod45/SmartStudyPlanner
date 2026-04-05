//
//  Subject.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct Subject: Identifiable, Hashable {
    let id: UUID
    let name: String
    let color: Color
    let resources: Int
    let topics: Int
    let lastUpdated: String

    init(id: UUID = UUID(), name: String, color: Color, resources: Int, topics: Int, lastUpdated: String) {
        self.id = id
        self.name = name
        self.color = color
        self.resources = resources
        self.topics = topics
        self.lastUpdated = lastUpdated
    }
}

extension Subject {
    static let samples: [Subject] = [
        Subject(name: "iOS Development", color: .blue, resources: 6, topics: 12, lastUpdated: "Yesterday"),
        Subject(name: "Data Structures", color: .purple, resources: 14, topics: 28, lastUpdated: "2h ago"),
        Subject(name: "Web APIs", color: .green, resources: 8, topics: 15, lastUpdated: "Mon"),
        Subject(name: "Algorithms", color: .orange, resources: 10, topics: 20, lastUpdated: "Today")
    ]
}
