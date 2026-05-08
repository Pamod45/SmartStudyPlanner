//
//  NotificationService.swift
//  SmartStudyPlanner
//
//  Central scheduler for all local notifications.
//  This is the ONLY place in the app that calls UNUserNotificationCenter.
//  History is written to NotificationStore only when iOS actually delivers
//  the notification (handled in AppDelegate).
//

import Foundation
import UserNotifications

final class NotificationService {


    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()


    private func sessionReminderId(_ sessionId: String) -> String { "session-\(sessionId)" }
    private func quizReminderId(_ sessionId: String)   -> String { "quiz-\(sessionId)" }
    private func deadlineAlertId(_ deadlineId: String) -> String { "deadline-\(deadlineId)" }
    private let dailyGoalAlertId = "daily-goal-alert"


    func requestAuthorisation() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("[NotificationService] Auth error: \(error)") }
            print("[NotificationService] Permission granted: \(granted)")
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }


    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelNotifications(ids: [String]) {
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }



    func scheduleSessionReminder(session: StudySession, settings: UserSettings) {
        let notifId = sessionReminderId(session.id)
        cancelNotification(id: notifId)

        guard settings.sessionRemindersEnabled, session.hasReminder else { return }

        let minutesBefore = settings.sessionReminderMinutesBefore
        let fireDate = session.startTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Study Session Starting Soon"
        content.body  = "\"\(session.title)\" starts in \(minutesBefore) min — get ready!"
        content.sound = .default
        content.userInfo = [
            "type":      NotificationType.study.rawValue,
            "userId":    session.userId,
            "referenceId": session.id
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, fireDate.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("[NotificationService] Session reminder error: \(error)") }
        }
    }


    func scheduleQuizReminder(for session: StudySession, settings: UserSettings) {
        let notifId = quizReminderId(session.id)
        cancelNotification(id: notifId)

        guard settings.quizzesPendingReminders else { return }

        let delayMinutes = settings.quizReminderMinutesAfter
        let fireInterval: TimeInterval = delayMinutes == 0 ? 5 : TimeInterval(delayMinutes * 60)

        let content = UNMutableNotificationContent()
        content.title = "Quiz Time! 📝"
        content.body  = "You just finished \"\(session.subjectName)\". Test your knowledge with a quick quiz!"
        content.sound = .default
        content.userInfo = [
            "type":        NotificationType.quiz.rawValue,
            "userId":      session.userId,
            "referenceId": session.id
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, fireInterval), repeats: false)
        let request = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("[NotificationService] Quiz reminder error: \(error)") }
        }
    }


    func scheduleDeadlineAlert(deadline: Deadline, settings: UserSettings) {
        let notifId = deadlineAlertId(deadline.id)
        cancelNotification(id: notifId)         // always cancel stale one first

        guard settings.deadlineAlertsEnabled, deadline.hasReminder else { return }

        let hoursBefore = settings.deadlineReminderHoursBefore
        let fireDate = deadline.dueDate.addingTimeInterval(TimeInterval(-hoursBefore * 3600))
        guard fireDate > Date() else { return }

        let timeLabel: String
        switch hoursBefore {
        case 1:   timeLabel = "in 1 hour"
        case 3:   timeLabel = "in 3 hours"
        case 24:  timeLabel = "tomorrow"
        case 72:  timeLabel = "in 3 days"
        case 168: timeLabel = "in 1 week"
        default:  timeLabel = "in \(hoursBefore) hours"
        }

        let content = UNMutableNotificationContent()
        content.title = "Deadline Approaching ⚠️"
        content.body  = "\"\(deadline.name)\" is due \(timeLabel). Stay on track!"
        content.sound = .default
        content.userInfo = [
            "type":        NotificationType.deadline.rawValue,
            "userId":      deadline.userId,
            "referenceId": deadline.id
        ]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            ),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("[NotificationService] Deadline alert error: \(error)") }
        }
    }



    func rescheduleDailyGoalAlert(settings: UserSettings) {
        cancelNotification(id: dailyGoalAlertId)

        guard settings.dailyGoalAlertsEnabled else { return }

        let cal = Calendar.current
        let alertTime = settings.dailyGoalAlertTime
        var comps = DateComponents()
        comps.hour   = cal.component(.hour,   from: alertTime)
        comps.minute = cal.component(.minute, from: alertTime)

        let content = UNMutableNotificationContent()
        content.title = "Daily Study Goal 🎯"
        content.body  = "Don't forget to hit your study goal today. Every session counts!"
        content.sound = .default
        content.userInfo = [
            "type":   NotificationType.general.rawValue,
            "userId": ""
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: dailyGoalAlertId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("[NotificationService] Daily goal alert error: \(error)") }
        }
    }


    func rescheduleAll(sessions: [StudySession], deadlines: [Deadline], settings: UserSettings) {
        center.removeAllPendingNotificationRequests()

        rescheduleDailyGoalAlert(settings: settings)

        for session in sessions where session.status == .scheduled {
            scheduleSessionReminder(session: session, settings: settings)
        }

        for deadline in deadlines where deadline.status == .upcoming || deadline.status == .inProgress {
            scheduleDeadlineAlert(deadline: deadline, settings: settings)
        }
    }
}
