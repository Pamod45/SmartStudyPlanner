import Combine

import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var todaySessions: [StudySession] = []
    @Published var upcomingDeadlines: [Deadline] = []
    @Published var notifications: [AppNotification] = []
    @Published var recentSubjects: [Subject] = []
    @Published var isLoading: Bool = false

    let shortcuts: [Shortcut] = [
        Shortcut(title: "SCAN NOTES", icon: "doc.viewfinder", color: .blue),
        Shortcut(title: "IMPORT DOC", icon: "doc.badge.arrow.up", color: .brown),
        Shortcut(title: "RECORD LECTURES", icon: "mic.fill", color: .green),
        Shortcut(title: "TAKE NOTES", icon: "signature", color: .purple)
    ]

    func load(userId: String?) async {
        isLoading = true
        defer { isLoading = false }
    }
}
