import Combine
import SwiftUI

// Builds the dashboard summary from subjects, study sessions, deadlines, and notifications.
// The view model keeps only the small slices needed for the home screen.

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var upcomingSessions: [StudySession] = []
    @Published var upcomingDeadlines: [Deadline] = []
    @Published var recentSubjects: [Subject] = []
    @Published var isLoading: Bool = false

    var notifications: [AppNotification] { NotificationStore.shared.notifications }

    let shortcuts: [Shortcut] = [
        Shortcut(title: "SCAN NOTES",       icon: "doc.viewfinder",      color: .blue),
        Shortcut(title: "IMPORT DOC",        icon: "doc.badge.arrow.up",  color: .brown),
        Shortcut(title: "RECORD LECTURES",   icon: "mic.fill",            color: .green),
        Shortcut(title: "TAKE NOTES",        icon: "signature",           color: .purple)
    ]

    // Loads dashboard data in parallel and filters it down to upcoming sessions/deadlines.
    func load(userId: String?) async {
        guard let userId, !userId.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        async let subjectsFetch  = SubjectService.shared.fetchSubjects(userId: userId)
        async let sessionsFetch  = StudySessionService.shared.fetchAll(userId: userId)
        async let deadlinesFetch = DeadlineService.shared.fetchAllDeadlines(userId: userId)

        let subjects  = (try? await subjectsFetch)  ?? []
        var sessions  = (try? await sessionsFetch)  ?? []
        let deadlines = (try? await deadlinesFetch) ?? []

        let now         = Date()
        let today       = Calendar.current.startOfDay(for: now)
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        recentSubjects = subjects

        sessions = await autoResolvePastSessions(sessions, now: now)

        upcomingSessions = Array(
            sessions
                .filter { session in
                    guard session.status == .scheduled || session.status == .inProgress else { return false }
                    guard session.endTime > now else { return false }
                    if session.status == .inProgress { return true }
                    return session.scheduledDate >= today && session.scheduledDate <= weekFromNow
                }
                .sorted { $0.scheduledDate < $1.scheduledDate }
                .prefix(5)
        )

        upcomingDeadlines = Array(
            deadlines
                .filter { $0.status == .upcoming && $0.dueDate >= today }
                .sorted { $0.dueDate < $1.dueDate }
                .prefix(5)
        )
    }


    // Cleans up past sessions when the dashboard opens so stale sessions do not stay active/upcoming.
    private func autoResolvePastSessions(_ sessions: [StudySession], now: Date) async -> [StudySession] {
        var updated = sessions
        var toSave: [StudySession] = []

        for i in updated.indices {
            guard updated[i].endTime < now else { continue }
            switch updated[i].status {
            case .scheduled:
                updated[i].status = .skipped
                updated[i].updatedAt = now
                toSave.append(updated[i])
            case .inProgress:
                updated[i].status = .completed
                updated[i].updatedAt = now
                toSave.append(updated[i])
            default:
                break
            }
        }

        for session in toSave {
            try? await StudySessionService.shared.update(session)
            if session.status == .completed {
                if let userId = session.userId.isEmpty ? nil : session.userId {
                    let settings = CoreDataService.shared.getCachedSettings(for: userId) ?? .default
                    NotificationService.shared.scheduleQuizReminder(for: session, settings: settings)
                }
            }
        }

        return updated
    }
}
