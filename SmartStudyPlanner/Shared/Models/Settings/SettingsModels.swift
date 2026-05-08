import SwiftUI
import FirebaseFirestore

// User-level settings that sync through Firebase and are also cached locally.
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
    var dailyGoalAlertsEnabled: Bool
    var dailyGoalAlertTime: Date
    var sessionRemindersEnabled: Bool
    var sessionReminderTime: Date
    var quizzesPendingReminders: Bool
    var quizReminderMinutesAfter: Int
    var deadlineAlertsEnabled: Bool
    var deadlineAlertTime: Date
    var preferredStudyTime: String
    
    var deadlineReminderDaysBefore: Int
    var deadlineReminderHoursBefore: Int
    var sessionReminderMinutesBefore: Int       
    var theme: AppThemePreference
    var darkModeEnabled: Bool
    var widgetConfiguration: String
    var siriIntegrationEnabled: Bool
    var accessibilityFontSize: Double
    var reduceMotionEnabled: Bool
    var highContrastEnabled: Bool
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
            dailyGoalAlertsEnabled: true,
            dailyGoalAlertTime: Self.timeToday(hour: 9, minute: 0),
            sessionRemindersEnabled: true,
            sessionReminderTime: Self.timeToday(hour: 21, minute: 30),
            quizzesPendingReminders: true,
            quizReminderMinutesAfter: 0,
            deadlineAlertsEnabled: true,
            deadlineAlertTime: Self.timeToday(hour: 18, minute: 0),
            preferredStudyTime: "Morning",
            deadlineReminderDaysBefore: 1,
            deadlineReminderHoursBefore: 24,
            sessionReminderMinutesBefore: 15,
            theme: .system,
            darkModeEnabled: true,
            widgetConfiguration: "Progress Summary",
            siriIntegrationEnabled: true,
            accessibilityFontSize: 1.0,
            reduceMotionEnabled: true,
            highContrastEnabled: false,
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
        dailyGoalAlertsEnabled: Bool = true,
        dailyGoalAlertTime: Date = UserSettings.timeToday(hour: 9, minute: 0),
        sessionRemindersEnabled: Bool = true,
        sessionReminderTime: Date = UserSettings.timeToday(hour: 21, minute: 30),
        quizzesPendingReminders: Bool = true,
        quizReminderMinutesAfter: Int = 0,
        deadlineAlertsEnabled: Bool = true,
        deadlineAlertTime: Date = UserSettings.timeToday(hour: 18, minute: 0),
        preferredStudyTime: String = "Morning",
        deadlineReminderDaysBefore: Int = 1,
        deadlineReminderHoursBefore: Int = 24,
        sessionReminderMinutesBefore: Int = 15,
        theme: AppThemePreference = .system,
        darkModeEnabled: Bool = true,
        widgetConfiguration: String = "Progress Summary",
        siriIntegrationEnabled: Bool = true,
        accessibilityFontSize: Double = 1.0,
        reduceMotionEnabled: Bool = true,
        highContrastEnabled: Bool = false,
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
        self.dailyGoalAlertsEnabled = dailyGoalAlertsEnabled
        self.dailyGoalAlertTime = dailyGoalAlertTime
        self.sessionRemindersEnabled = sessionRemindersEnabled
        self.sessionReminderTime = sessionReminderTime
        self.quizzesPendingReminders = quizzesPendingReminders
        self.quizReminderMinutesAfter = quizReminderMinutesAfter
        self.deadlineAlertsEnabled = deadlineAlertsEnabled
        self.deadlineAlertTime = deadlineAlertTime
        self.preferredStudyTime = preferredStudyTime
        self.deadlineReminderDaysBefore = deadlineReminderDaysBefore
        self.deadlineReminderHoursBefore = deadlineReminderHoursBefore
        self.sessionReminderMinutesBefore = sessionReminderMinutesBefore
        self.theme = theme
        self.darkModeEnabled = darkModeEnabled
        self.widgetConfiguration = widgetConfiguration
        self.siriIntegrationEnabled = siriIntegrationEnabled
        self.accessibilityFontSize = accessibilityFontSize
        self.reduceMotionEnabled = reduceMotionEnabled
        self.highContrastEnabled = highContrastEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.soundEnabled = soundEnabled
        self.calendarSyncEnabled = calendarSyncEnabled
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }

    // Converts settings to Firestore-safe values and protects date fields from invalid ranges.
    var firestoreData: [String: Any] {
        let dailyGoalTime = Self.clampDate(dailyGoalAlertTime, fallback: Self.timeToday(hour: 9, minute: 0))
        let sessionTime = Self.clampDate(sessionReminderTime, fallback: Self.timeToday(hour: 21, minute: 30))
        let deadlineTime = Self.clampDate(deadlineAlertTime, fallback: Self.timeToday(hour: 18, minute: 0))
        let updated = Self.clampDate(updatedAt, fallback: Date())

        return [
            "id": id,
            "userId": userId,
            "dailyStudyGoalHours": dailyStudyGoalHours,
            "weeklyStudyGoalDays": weeklyStudyGoalDays,
            "preferredSessionDurationMinutes": preferredSessionDurationMinutes,
            "breakDurationMinutes": breakDurationMinutes,
            "notificationsEnabled": notificationsEnabled,
            "dailyGoalAlertsEnabled": dailyGoalAlertsEnabled,
            "dailyGoalAlertTime": dailyGoalTime,
            "sessionRemindersEnabled": sessionRemindersEnabled,
            "sessionReminderTime": sessionTime,
            "quizzesPendingReminders": quizzesPendingReminders,
            "quizReminderMinutesAfter": quizReminderMinutesAfter,
            "deadlineAlertsEnabled": deadlineAlertsEnabled,
            "deadlineAlertTime": deadlineTime,
            "preferredStudyTime": preferredStudyTime,
            "deadlineReminderDaysBefore": deadlineReminderDaysBefore,
            "deadlineReminderHoursBefore": deadlineReminderHoursBefore,
            "sessionReminderMinutesBefore": sessionReminderMinutesBefore,
            "theme": theme.rawValue,
            "darkModeEnabled": darkModeEnabled,
            "widgetConfiguration": widgetConfiguration,
            "siriIntegrationEnabled": siriIntegrationEnabled,
            "accessibilityFontSize": accessibilityFontSize,
            "reduceMotionEnabled": reduceMotionEnabled,
            "highContrastEnabled": highContrastEnabled,
            "hapticFeedbackEnabled": hapticFeedbackEnabled,
            "soundEnabled": soundEnabled,
            "calendarSyncEnabled": calendarSyncEnabled,
            "updatedAt": updated,
            "syncStatus": syncStatus.rawValue
        ]
    }

    // Builds settings from Firestore data while supporting both Timestamp and Date values from cached/local paths.
    init?(from data: [String: Any], userId: String) {
        let id = data["id"] as? String ?? userId
        let dailyStudyGoalHours = data["dailyStudyGoalHours"] as? Double ?? 3.0
        let weeklyStudyGoalDays = data["weeklyStudyGoalDays"] as? Int ?? Int((data["weeklyStudyGoalDays"] as? Int64) ?? 5)
        let preferredSessionDurationMinutes = data["preferredSessionDurationMinutes"] as? Int ?? Int((data["preferredSessionDurationMinutes"] as? Int64) ?? 60)
        let breakDurationMinutes = data["breakDurationMinutes"] as? Int ?? Int((data["breakDurationMinutes"] as? Int64) ?? 10)
        let notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
        let dailyGoalAlertsEnabled = data["dailyGoalAlertsEnabled"] as? Bool ?? true
        let sessionRemindersEnabled = data["sessionRemindersEnabled"] as? Bool ?? true
        let quizzesPendingReminders = data["quizzesPendingReminders"] as? Bool ?? true
        let quizReminderMinutesAfter = data["quizReminderMinutesAfter"] as? Int ?? Int((data["quizReminderMinutesAfter"] as? Int64) ?? 0)
        let deadlineAlertsEnabled = data["deadlineAlertsEnabled"] as? Bool ?? true
        let preferredStudyTime = data["preferredStudyTime"] as? String ?? "Morning"
        let deadlineReminderDaysBefore = data["deadlineReminderDaysBefore"] as? Int ?? Int((data["deadlineReminderDaysBefore"] as? Int64) ?? 1)
        let deadlineReminderHoursBefore = data["deadlineReminderHoursBefore"] as? Int ?? Int((data["deadlineReminderHoursBefore"] as? Int64) ?? 24)
        let sessionReminderMinutesBefore = data["sessionReminderMinutesBefore"] as? Int ?? Int((data["sessionReminderMinutesBefore"] as? Int64) ?? 15)
        let theme = AppThemePreference(rawValue: data["theme"] as? String ?? "") ?? .system
        let darkModeEnabled = data["darkModeEnabled"] as? Bool ?? true
        let widgetConfiguration = data["widgetConfiguration"] as? String ?? "Progress Summary"
        let siriIntegrationEnabled = data["siriIntegrationEnabled"] as? Bool ?? true
        let accessibilityFontSize = data["accessibilityFontSize"] as? Double ?? 1.0
        let reduceMotionEnabled = data["reduceMotionEnabled"] as? Bool ?? true
        let highContrastEnabled = data["highContrastEnabled"] as? Bool ?? false
        let hapticFeedbackEnabled = data["hapticFeedbackEnabled"] as? Bool ?? true
        let soundEnabled = data["soundEnabled"] as? Bool ?? true
        let calendarSyncEnabled = data["calendarSyncEnabled"] as? Bool ?? false
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? (data["updatedAt"] as? Date) ?? Date()
        let syncStatus = SyncStatus(rawValue: data["syncStatus"] as? String ?? "") ?? .localOnly

        func dateValue(_ key: String, fallback: Date) -> Date {
            if let ts = data[key] as? Timestamp { return ts.dateValue() }
            if let date = data[key] as? Date { return date }
            return fallback
        }

        let dailyGoalTime = Self.clampDate(dateValue("dailyGoalAlertTime", fallback: Self.timeToday(hour: 9, minute: 0)), fallback: Self.timeToday(hour: 9, minute: 0))
        let sessionTime = Self.clampDate(dateValue("sessionReminderTime", fallback: Self.timeToday(hour: 21, minute: 30)), fallback: Self.timeToday(hour: 21, minute: 30))
        let deadlineTime = Self.clampDate(dateValue("deadlineAlertTime", fallback: Self.timeToday(hour: 18, minute: 0)), fallback: Self.timeToday(hour: 18, minute: 0))
        let safeUpdatedAt = Self.clampDate(updatedAt, fallback: Date())

        self.init(
            id: id,
            userId: userId,
            dailyStudyGoalHours: dailyStudyGoalHours,
            weeklyStudyGoalDays: weeklyStudyGoalDays,
            preferredSessionDurationMinutes: preferredSessionDurationMinutes,
            breakDurationMinutes: breakDurationMinutes,
            notificationsEnabled: notificationsEnabled,
            dailyGoalAlertsEnabled: dailyGoalAlertsEnabled,
            dailyGoalAlertTime: dailyGoalTime,
            sessionRemindersEnabled: sessionRemindersEnabled,
            sessionReminderTime: sessionTime,
            quizzesPendingReminders: quizzesPendingReminders,
            quizReminderMinutesAfter: quizReminderMinutesAfter,
            deadlineAlertsEnabled: deadlineAlertsEnabled,
            deadlineAlertTime: deadlineTime,
            preferredStudyTime: preferredStudyTime,
            deadlineReminderDaysBefore: deadlineReminderDaysBefore,
            deadlineReminderHoursBefore: deadlineReminderHoursBefore,
            sessionReminderMinutesBefore: sessionReminderMinutesBefore,
            theme: theme,
            darkModeEnabled: darkModeEnabled,
            widgetConfiguration: widgetConfiguration,
            siriIntegrationEnabled: siriIntegrationEnabled,
            accessibilityFontSize: accessibilityFontSize,
            reduceMotionEnabled: reduceMotionEnabled,
            highContrastEnabled: highContrastEnabled,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            soundEnabled: soundEnabled,
            calendarSyncEnabled: calendarSyncEnabled,
            updatedAt: safeUpdatedAt,
            syncStatus: syncStatus
        )
    }

    private static func timeToday(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    // Firestore can reject dates outside its supported range, so invalid values are replaced before saving.
    private static func clampDate(_ date: Date, fallback: Date) -> Date {
        let seconds = date.timeIntervalSince1970
        if seconds < -62135596800 || seconds >= 253402300800 {
            return fallback
        }
        return date
    }
}

// Lightweight editable profile model used by Settings screens.
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
