import Foundation
import SwiftUI

enum NotificationType: String, CaseIterable, Identifiable, Codable {
    case all          = "All"
    case study        = "Study"
    case deadline     = "Deadline"
    case quiz         = "Quizzes"
    case general      = "General"
    case streakAlert  = "Streak"
    case weeklyReport = "Weekly"
    case goalAchieved = "Goal"
    case system       = "System"

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .all:          return .clear
        case .study:        return .blue
        case .deadline:     return .red
        case .quiz:         return .purple
        case .general:      return .gray
        case .streakAlert:  return .orange
        case .weeklyReport: return .cyan
        case .goalAchieved: return .green
        case .system:       return .secondary
        }
    }

    var icon: String {
        switch self {
        case .all:          return ""
        case .study:        return "book.fill"
        case .deadline:     return "exclamationmark.triangle.fill"
        case .quiz:         return "pencil.and.list.clipboard"
        case .general:      return "target"
        case .streakAlert:  return "flame.fill"
        case .weeklyReport: return "chart.bar.fill"
        case .goalAchieved: return "checkmark.seal.fill"
        case .system:       return "gearshape.fill"
        }
    }
}

struct AppNotification: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var title: String
    var message: String
    var notificationType: NotificationType
    var referenceId: String?
    var isRead: Bool
    var scheduledAt: Date
    var deliveredAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var color: Color { notificationType.color }
    var icon: String { notificationType.icon }

    var dateString: String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: createdAt, to: now)

        if calendar.isDateInToday(createdAt), let minute = components.minute, minute < 60, let hour = components.hour, hour == 0 {
            return minute <= 1 ? "Just now" : "\(minute)min ago"
        }
        if calendar.isDateInToday(createdAt), let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        }
        if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: createdAt)
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        title: String,
        message: String,
        notificationType: NotificationType,
        referenceId: String? = nil,
        isRead: Bool = false,
        scheduledAt: Date = Date(),
        deliveredAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.notificationType = notificationType
        self.referenceId = referenceId
        self.isRead = isRead
        self.scheduledAt = scheduledAt
        self.deliveredAt = deliveredAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
