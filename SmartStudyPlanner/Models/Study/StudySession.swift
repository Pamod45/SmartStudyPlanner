import SwiftUI

enum SessionStatus: String, Codable {
    case scheduled
    case inProgress
    case completed
    case skipped
    case rescheduled
}

enum SessionType: String, Codable {
    case focused
    case review
    case practice
    case reading
    case groupStudy
}

struct StudySession: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var subjectId: String
    var subjectName: String
    var subjectColorHex: String
    var title: String
    var topic: String
    var notes: String?
    var scheduledDate: Date
    var startTime: Date
    var endTime: Date
    var actualDurationMinutes: Int?
    var status: SessionStatus
    var sessionType: SessionType
    var hasReminder: Bool
    var linkedDeadlineId: String?
    var linkedPlanId: String?
    var resourceIds: [String]
    var topicIds: [String]
    var rating: Int?
    var externalCalendarEventId: String?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var subjectColor: Color {
        Color(hex: subjectColorHex)
    }

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var duration: String {
        "\(durationMinutes) min"
    }

    var timeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return "\(f.string(from: startTime)) - \(f.string(from: endTime))"
    }

    var startHour: CGFloat {
        let cal = Calendar.current
        let hour = CGFloat(cal.component(.hour, from: startTime))
        let minute = CGFloat(cal.component(.minute, from: startTime))
        return hour + minute / 60.0
    }

    var endHour: CGFloat {
        let cal = Calendar.current
        let hour = CGFloat(cal.component(.hour, from: endTime))
        let minute = CGFloat(cal.component(.minute, from: endTime))
        return hour + minute / 60.0
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        subjectId: String = "",
        subjectName: String,
        subjectColorHex: String = "#3B82F6",
        title: String,
        topic: String = "",
        notes: String? = nil,
        scheduledDate: Date = Date(),
        startTime: Date,
        endTime: Date,
        actualDurationMinutes: Int? = nil,
        status: SessionStatus = .scheduled,
        sessionType: SessionType = .focused,
        hasReminder: Bool = false,
        linkedDeadlineId: String? = nil,
        linkedPlanId: String? = nil,
        resourceIds: [String] = [],
        topicIds: [String] = [],
        rating: Int? = nil,
        externalCalendarEventId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.subjectId = subjectId
        self.subjectName = subjectName
        self.subjectColorHex = subjectColorHex
        self.title = title
        self.topic = topic
        self.notes = notes
        self.scheduledDate = scheduledDate
        self.startTime = startTime
        self.endTime = endTime
        self.actualDurationMinutes = actualDurationMinutes
        self.status = status
        self.sessionType = sessionType
        self.hasReminder = hasReminder
        self.linkedDeadlineId = linkedDeadlineId
        self.linkedPlanId = linkedPlanId
        self.resourceIds = resourceIds
        self.topicIds = topicIds
        self.rating                  = rating
        self.externalCalendarEventId = externalCalendarEventId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
