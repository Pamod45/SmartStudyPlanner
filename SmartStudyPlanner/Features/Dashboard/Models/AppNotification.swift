//
//  Notification.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-02.
//

import Foundation
import SwiftUI
struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date
    let notificationType: NotificationType
    
    var color : Color {
        switch notificationType {
            case .all: return .clear    
            case .study: return .blue
            case .deadline: return .red
            case .quiz: return .purple
            case .general: return .gray
        }
    }
    
    var icon : String {
        switch notificationType {
            case .all: return ""
            case .study: return "book.fill"
            case .deadline: return "exclamationmark.triangle.fill"
            case .quiz: return "pencil.and.list.clipboard"
            case .general: return "target"
        }
    }
}

enum NotificationType: String, CaseIterable, Identifiable {
    case all = "All"
    case study = "Study"
    case deadline = "Deadline"
    case quiz = "Quizzes"
    case general = "General"
    
    var id: String { self.rawValue }
}

extension AppNotification {
    var dateString: String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if calendar.isDateInToday(date), let minute = components.minute, minute < 60, let hour = components.hour, hour == 0 {
            return minute <= 1 ? "Just now" : "\(minute)min ago"
        }
        
        if calendar.isDateInToday(date), let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        }
        
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d'\(daySuffix(from: date))' MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daySuffix(from date: Date) -> String {
            let day = Calendar.current.component(.day, from: date)
            switch day {
            case 11...13: return "th"
            default:
                switch day % 10 {
                case 1: return "st"
                case 2: return "nd"
                case 3: return "rd"
                default: return "th"
                }
            }
        }
    static var samples: [AppNotification] = [
        AppNotification(title: "Exam Tomorrow", message:"iOS Development Exam is happening tomorrow at 10:00 AM.", date: Date(), notificationType: .deadline),
        AppNotification(title: "Upcoming Session",message:"SwiftUI Layout session starts in 15 minutes.", date: Date(), notificationType: .study),
        AppNotification(title: "Daily Goal Met", message:"Awesome! You've completed 4 hours of study today.", date: Date(), notificationType: .general),
        AppNotification(title: "Pending Quiz", message:"Don't forget to take your Data Structures quiz after the session.", date: Date(), notificationType: .quiz)
    ]
}




