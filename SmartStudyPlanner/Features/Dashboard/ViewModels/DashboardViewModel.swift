import Combine
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var upcomingSessions: [StudySession] = []
    @Published var upcomingDeadlines: [Deadline] = []
    @Published var notifications: [AppNotification] = []
    @Published var recentSubjects: [Subject] = []
    @Published var isLoading: Bool = false

    let shortcuts: [Shortcut] = [
        Shortcut(title: "SCAN NOTES",       icon: "doc.viewfinder",      color: .blue),
        Shortcut(title: "IMPORT DOC",        icon: "doc.badge.arrow.up",  color: .brown),
        Shortcut(title: "RECORD LECTURES",   icon: "mic.fill",            color: .green),
        Shortcut(title: "TAKE NOTES",        icon: "signature",           color: .purple)
    ]

    func load(userId: String?) async {
        guard let userId, !userId.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        async let subjectsFetch  = SubjectService.shared.fetchSubjects(userId: userId)
        async let sessionsFetch  = StudySessionService.shared.fetchAll(userId: userId)
        async let deadlinesFetch = DeadlineService.shared.fetchAllDeadlines(userId: userId)

        let subjects  = (try? await subjectsFetch)  ?? []
        let sessions  = (try? await sessionsFetch)  ?? []
        let deadlines = (try? await deadlinesFetch) ?? []

        let today       = Calendar.current.startOfDay(for: Date())
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        recentSubjects = subjects

        upcomingSessions = Array(
            sessions
                .filter { $0.status != .completed && $0.scheduledDate >= today && $0.scheduledDate <= weekFromNow }
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
}
