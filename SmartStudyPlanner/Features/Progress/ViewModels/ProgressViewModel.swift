import Combine

import SwiftUI
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var weeklySnapshots: [WeeklyProgressSnapshot] = []
    @Published var streak: StudyStreak = StudyStreak()
    @Published var completedSessions: [StudySession] = []
    @Published var isLoading: Bool = false

    var stats: [StatItem] { [] }
    var subjectProgressItems: [SubjectProgress] { [] }
    var insights: [InsightItem] { [] }
    var dailyActivity: [DailyActivity] { [] }
    var monthActivity: [DailyActivity] { [] }
    var quarterActivity: [DailyActivity] { [] }
    var subjectDistribution: [SubjectDistribution] { [] }
    var resourceUtilization: [ResourceUtilization] { [] }
    var subjectNames: [String] { [] }

    func load(userId: String?) async {
        isLoading = true
        defer { isLoading = false }
    }
}
