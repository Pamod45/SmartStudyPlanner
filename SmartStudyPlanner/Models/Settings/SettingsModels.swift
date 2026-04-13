import SwiftUI

enum AppThemePreference: String, Codable {
    case light
    case dark
    case system
}

struct UserSettings: Codable, Syncable {
    var id: String
    var userId: String
    var dailyStudyGoalHours: Double
    var weeklyStudyGoalDays: Int
    var preferredSessionDurationMinutes: Int
    var breakDurationMinutes: Int
    var notificationsEnabled: Bool
    var deadlineReminderDaysBefore: Int
    var sessionReminderMinutesBefore: Int
    var theme: AppThemePreference
    var accessibilityFontSize: Double
    var hapticFeedbackEnabled: Bool
    var soundEnabled: Bool
    var calendarSyncEnabled: Bool
    var updatedAt: Date
    var syncStatus: SyncStatus

    static var `default`: UserSettings {
        UserSettings(
            id: UUID().uuidString,
            userId: "",
            dailyStudyGoalHours: 3.0,
            weeklyStudyGoalDays: 5,
            preferredSessionDurationMinutes: 60,
            breakDurationMinutes: 10,
            notificationsEnabled: true,
            deadlineReminderDaysBefore: 3,
            sessionReminderMinutesBefore: 15,
            theme: .system,
            accessibilityFontSize: 1.0,
            hapticFeedbackEnabled: true,
            soundEnabled: true,
            calendarSyncEnabled: false,
            updatedAt: Date(),
            syncStatus: .localOnly
        )
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        dailyStudyGoalHours: Double = 3.0,
        weeklyStudyGoalDays: Int = 5,
        preferredSessionDurationMinutes: Int = 60,
        breakDurationMinutes: Int = 10,
        notificationsEnabled: Bool = true,
        deadlineReminderDaysBefore: Int = 3,
        sessionReminderMinutesBefore: Int = 15,
        theme: AppThemePreference = .system,
        accessibilityFontSize: Double = 1.0,
        hapticFeedbackEnabled: Bool = true,
        soundEnabled: Bool = true,
        calendarSyncEnabled: Bool = false,
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.dailyStudyGoalHours = dailyStudyGoalHours
        self.weeklyStudyGoalDays = weeklyStudyGoalDays
        self.preferredSessionDurationMinutes = preferredSessionDurationMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.notificationsEnabled = notificationsEnabled
        self.deadlineReminderDaysBefore = deadlineReminderDaysBefore
        self.sessionReminderMinutesBefore = sessionReminderMinutesBefore
        self.theme = theme
        self.accessibilityFontSize = accessibilityFontSize
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.soundEnabled = soundEnabled
        self.calendarSyncEnabled = calendarSyncEnabled
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}

struct SettingsUser {
    var name: String
    var email: String
    var domain: String
    var institute: String
    var username: String
    var avatarImage: UIImage? = nil
}

struct SettingsSection: Identifiable {
    let id: String
    let rows: [SettingsRowItem]

    init(id: String = UUID().uuidString, rows: [SettingsRowItem]) {
        self.id = id
        self.rows = rows
    }
}

struct SettingsRowItem: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let type: SettingsRowKind

    init(id: String = UUID().uuidString, icon: String, iconColor: Color, title: String, type: SettingsRowKind) {
        self.id = id
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.type = type
    }
}

enum SettingsRowKind {
    case toggle
    case navigation
    case destructive
}
