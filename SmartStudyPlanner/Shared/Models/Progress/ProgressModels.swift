import SwiftUI

// Lightweight view models used by the Progress screens after ProgressViewModel calculates the values.
struct StatItem {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let badge: String?
    let badgeColor: Color

    init(icon: String, iconColor: Color, value: String, label: String, badge: String? = nil, badgeColor: Color = .blue) {
        self.icon = icon
        self.iconColor = iconColor
        self.value = value
        self.label = label
        self.badge = badge
        self.badgeColor = badgeColor
    }
}

enum SubjectStatus: String {
    case excellent   = "EXCELLENT"
    case good        = "GOOD"
    case needsFocus  = "NEEDS FOCUS"

    var color: Color {
        switch self {
        case .excellent:  return Color(hex: "#44A5FF")
        case .good:       return Color(hex: "#22C55E")
        case .needsFocus: return Color(hex: "#F97316")
        }
    }
}

struct SubjectProgress {
    let name: String
    let subtitle: String
    let mastery: Double
    let status: SubjectStatus
    let color: Color
}

// One generated progress insight with the text and styling needed by the insight card.
struct InsightItem {
    let tag: String
    let tagColor: Color
    let title: String
    let body: String
    let icon: String
}

struct DailyActivity: Identifiable {
    let id: String
    let day: String
    let date: Date
    let hours: Double
    let subject: String
    let color: Color

    init(id: String = UUID().uuidString, day: String, date: Date, hours: Double, subject: String, color: Color) {
        self.id = id
        self.day = day
        self.date = date
        self.hours = hours
        self.subject = subject
        self.color = color
    }
}

struct SubjectDistribution {
    let name: String
    let percentage: Double
    let color: Color
}

struct ResourceUtilization {
    let type: String
    let icon: String
    let count: Int
    let color: Color
}

// Persistable weekly summary shape for saving progress history when snapshot storage is wired in.
struct WeeklyProgressSnapshot: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var weekStartDate: Date
    var weekEndDate: Date
    var totalHoursStudied: Double
    var goalHours: Double
    var sessionsCompleted: Int
    var sessionsSkipped: Int
    var subjectBreakdown: [String: Double]
    var longestStreakDays: Int
    var averageSessionRating: Double?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var goalCompletionPercentage: Double {
        guard goalHours > 0 else { return 0 }
        return min((totalHoursStudied / goalHours) * 100, 100)
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        weekStartDate: Date = Date(),
        weekEndDate: Date = Date(),
        totalHoursStudied: Double = 0,
        goalHours: Double = 0,
        sessionsCompleted: Int = 0,
        sessionsSkipped: Int = 0,
        subjectBreakdown: [String: Double] = [:],
        longestStreakDays: Int = 0,
        averageSessionRating: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalHoursStudied = totalHoursStudied
        self.goalHours = goalHours
        self.sessionsCompleted = sessionsCompleted
        self.sessionsSkipped = sessionsSkipped
        self.subjectBreakdown = subjectBreakdown
        self.longestStreakDays = longestStreakDays
        self.averageSessionRating = averageSessionRating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}

// Stores the user's current and longest consecutive-day study streak.
struct StudyStreak: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var currentStreak: Int
    var longestStreak: Int
    var lastStudyDate: Date?
    var streakStartDate: Date?
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastStudyDate: Date? = nil,
        streakStartDate: Date? = nil,
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastStudyDate = lastStudyDate
        self.streakStartDate = streakStartDate
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
