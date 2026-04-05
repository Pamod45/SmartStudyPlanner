//
//  StudySession.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import Foundation
import SwiftUI
struct StudySession: Identifiable {
    let id = UUID()
    let subject: String
    let title: String
    let timeRange: String
    let duration: String
    let subjectColor: Color
}
