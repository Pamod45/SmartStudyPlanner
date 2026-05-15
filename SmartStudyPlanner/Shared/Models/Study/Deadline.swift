import SwiftUI

enum DeadlineTag: String, CaseIterable, Identifiable, Codable {
    case finalExam  = "#FinalExam"
    case cw         = "#CW"
    case submission = "#Submission"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .finalExam:  return "doc.plaintext"
        case .cw:         return "laptopcomputer"
        case .submission: return "tray.and.arrow.up.fill"
        }
    }
}

enum DeadlinePriority: String, Codable {
    case low
    case medium
    case high
    case critical
}

enum DeadlineStatus: String, Codable {
    case upcoming
    case inProgress
    case completed
    case overdue
    case cancelled
}

struct Deadline: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var subjectId: String
    var subjectColorHex: String
    var name: String
    var dueDate: Date
    var hasReminder: Bool
    var isHighPriority: Bool
    var notes: String
    var tag: DeadlineTag
    var priority: DeadlinePriority
    var status: DeadlineStatus
    var reminderDate: Date?
    var linkedSessionIds: [String]
    var notificationId: String?
    var externalCalendarEventId: String?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var subjectColor: Color {
        Color(hex: subjectColorHex)
    }

    var icon: String {
        tag.icon
    }

    var color: Color {
        if isHighPriority { return .red }
        switch tag {
        case .finalExam:  return .blue
        case .submission: return .yellow
        case .cw:         return .brown
        }
    }

    var month: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: dueDate).uppercased()
    }

    var day: Int {
        Calendar.current.component(.day, from: dueDate)
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: dueDate)
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        subjectId: String = "",
        subjectColorHex: String = "#3B82F6",
        name: String,
        dueDate: Date,
        hasReminder: Bool = false,
        isHighPriority: Bool = false,
        notes: String = "",
        tag: DeadlineTag,
        priority: DeadlinePriority = .medium,
        status: DeadlineStatus = .upcoming,
        reminderDate: Date? = nil,
        linkedSessionIds: [String] = [],
        notificationId: String? = nil,
        externalCalendarEventId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.subjectId = subjectId
        self.subjectColorHex = subjectColorHex
        self.name = name
        self.dueDate = dueDate
        self.hasReminder = hasReminder
        self.isHighPriority = isHighPriority
        self.notes = notes
        self.tag = tag
        self.priority = priority
        self.status = status
        self.reminderDate = reminderDate
        self.linkedSessionIds = linkedSessionIds
        self.notificationId = notificationId
        self.externalCalendarEventId = externalCalendarEventId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
