//
//  Subject.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct Subject: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let resources: Int
    let topics: Int
    let lastUpdated: String
}

extension Subject {
    static let samples: [Subject] = [
        Subject(name: "iOS Development", color: .blue, resources: 6, topics: 12, lastUpdated: "Yesterday"),
        Subject(name: "Data Structures", color: .purple, resources: 14, topics: 28, lastUpdated: "2h ago"),
        Subject(name: "Web APIs", color: .green, resources: 8, topics: 15, lastUpdated: "Mon"),
        Subject(name: "Algorithms", color: .orange, resources: 10, topics: 20, lastUpdated: "Today")
    ]
}
