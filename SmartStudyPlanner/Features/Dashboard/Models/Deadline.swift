//
//  Deadline.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import Foundation
import SwiftUI
struct Deadline: Identifiable {
    let id = UUID()
    let month: String
    let day: Int
    let title: String
    let subtitle: String
    let subjectColor: Color
}
