import SwiftUI
import Combine

// Builds all data shown in the Progress tab from completed sessions, subjects, quiz attempts, resources, and settings.
// The views stay mostly display-only; this view model does the progress calculations in memory after loading user data.
@MainActor
class ProgressViewModel: ObservableObject {

    @Published var weeklySnapshots: [WeeklyProgressSnapshot] = []
    @Published var streak: StudyStreak = StudyStreak()
    @Published var completedSessions: [StudySession] = []
    @Published var isLoading: Bool = false

    @Published private var allSessions: [StudySession] = []
    @Published private var subjects: [Subject] = []
    @Published private var allAttempts: [QuizAttempt] = []
    @Published private var allResources: [Resource] = []

    private var userId: String = ""
    private var userSettings: UserSettings?

    private var thisWeekSessions: [StudySession] {
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return completedSessions.filter { $0.scheduledDate >= weekStart }
    }

    private var perSubjectWeeklyTargetHours: Double {
        let daily = userSettings?.dailyStudyGoalHours ?? 3.0
        let count = max(subjects.filter { !$0.isArchived }.count, 1)
        return (daily * 7.0) / Double(count)
    }

    // Summary cards are calculated from completed sessions in the current week.
    // Study time uses actualDurationMinutes when a completed session has it, otherwise it falls back to the planned duration.
    var stats: [StatItem] {
        let weekly = thisWeekSessions
        let totalMinutes = weekly.reduce(0) {
            $0 + ($1.actualDurationMinutes ?? $1.durationMinutes)
        }
        let totalHours = Double(totalMinutes) / 60.0
        let sessionCount = weekly.count
        let goalHours = (userSettings?.dailyStudyGoalHours ?? 3.0) * 7.0
        let ratedSessions = weekly.compactMap(\.rating)
        let avgRating = ratedSessions.isEmpty
            ? nil
            : Double(ratedSessions.reduce(0, +)) / Double(ratedSessions.count)

        return [
            StatItem(
                icon: "clock.fill",
                iconColor: .blue,
                value: String(format: "%.1f", totalHours),
                label: "HRS THIS WEEK",
                badge: String(format: "/ %.0fh goal", goalHours),
                badgeColor: totalHours >= goalHours ? .green : .blue
            ),
            StatItem(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                value: "\(sessionCount)",
                label: "SESSIONS DONE"
            ),
            StatItem(
                icon: "flame.fill",
                iconColor: .orange,
                value: "\(streak.currentStreak)",
                label: "DAY STREAK",
                badge: streak.currentStreak >= 3 ? "\(streak.currentStreak) days" : nil,
                badgeColor: .orange
            ),
            StatItem(
                icon: "star.fill",
                iconColor: Color(hex: "#F59E0B"),
                value: avgRating.map { String(format: "%.1f/5", $0) } ?? "N/A",
                label: "AVG RATING"
            )
        ]
    }

    // Subject mastery combines this week's study time and quiz scores.
    // 70% comes from progress toward the subject's weekly target hours, and 30% comes from average quiz score when attempts exist.
    var subjectProgressItems: [SubjectProgress] {
        let weeklyTarget = perSubjectWeeklyTargetHours
        return subjects.filter { !$0.isArchived }.map { subject in
            let weekSessions = thisWeekSessions.filter { $0.subjectId == subject.id }
            let hoursStudied = Double(weekSessions.reduce(0) {
                $0 + ($1.actualDurationMinutes ?? $1.durationMinutes)
            }) / 60.0

            let sessionComponent = min(hoursStudied / max(weeklyTarget, 1.0), 1.0)

            let subjectAttempts = allAttempts.filter { $0.subjectId == subject.id }
            let mastery: Double
            if subjectAttempts.isEmpty {
                mastery = sessionComponent
            } else {
                let quizComponent = Double(subjectAttempts.reduce(0) { $0 + $1.scorePercent })
                    / Double(subjectAttempts.count) / 100.0
                mastery = (sessionComponent * 0.7) + (quizComponent * 0.3)
            }

            let status: SubjectStatus
            switch mastery {
            case 0.75...: status = .excellent
            case 0.40...: status = .good
            default:      status = .needsFocus
            }

            let subtitle = String(format: "%.1fh / %.0fh this week and %d quiz attempts", hoursStudied, weeklyTarget, subjectAttempts.count)

            return SubjectProgress(
                name: subject.name,
                subtitle: subtitle,
                mastery: mastery,
                status: status,
                color: Color(hex: subject.colorHex)
            )
        }
        .sorted { $0.mastery > $1.mastery }
    }

    // Insights are simple human-readable patterns from the user's data:
    // peak day = weekday with the most completed study minutes across all completed sessions,
    // top subject = subject with the most completed study minutes this week,
    // trend = this week's completed session count compared with last week's count,
    // weak quiz area = subject with the lowest average quiz score.
    var insights: [InsightItem] {
        var items: [InsightItem] = []
        let cal = Calendar.current
        let byWeekday = Dictionary(grouping: completedSessions) {
            cal.component(.weekday, from: $0.scheduledDate)
        }
        if let best = byWeekday.max(by: {
            let minsA = $0.value.reduce(0) { $0 + ($1.actualDurationMinutes ?? $1.durationMinutes) }
            let minsB = $1.value.reduce(0) { $0 + ($1.actualDurationMinutes ?? $1.durationMinutes) }
            return minsA < minsB
        }) {
            let totalMins = best.value.reduce(0) { $0 + ($1.actualDurationMinutes ?? $1.durationMinutes) }
            let avgHours = Double(totalMins) / 60.0 / Double(best.value.count)
            let dayName = cal.weekdaySymbols[best.key - 1]
            items.append(InsightItem(
                tag: "PEAK DAY",
                tagColor: .blue,
                title: "\(dayName)s are your strongest",
                body: String(format: "You average %.1fh of study on \(dayName)s. Consider scheduling harder topics on this day.", avgHours),
                icon: "calendar.badge.clock"
            ))
        }

        let bySubject = Dictionary(grouping: thisWeekSessions, by: \.subjectId)
        if let topEntry = bySubject.max(by: {
            let minsA = $0.value.reduce(0) { $0 + ($1.actualDurationMinutes ?? $1.durationMinutes) }
            let minsB = $1.value.reduce(0) { $0 + ($1.actualDurationMinutes ?? $1.durationMinutes) }
            return minsA < minsB
        }), let firstSession = topEntry.value.first {
            let hours = Double(topEntry.value.reduce(0) { $0 + ($1.actualDurationMinutes ?? $1.durationMinutes) }) / 60.0
            items.append(InsightItem(
                tag: "TOP SUBJECT",
                tagColor: .green,
                title: "\(firstSession.subjectName) leading this week",
                body: String(format: "You've put in %.1fh on \(firstSession.subjectName) this week - your most studied subject.", hours),
                icon: "star.fill"
            ))
        }

        let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? Date()
        let thisWeekCount = completedSessions.filter { $0.scheduledDate >= thisWeekStart }.count
        let lastWeekCount = completedSessions.filter {
            $0.scheduledDate >= lastWeekStart && $0.scheduledDate < thisWeekStart
        }.count
        if lastWeekCount > 0 {
            let diff = thisWeekCount - lastWeekCount
            let trend = diff >= 0 ? "up \(abs(diff))" : "down \(abs(diff))"
            items.append(InsightItem(
                tag: diff >= 0 ? "IMPROVING" : "WATCH OUT",
                tagColor: diff >= 0 ? .green : .orange,
                title: "Sessions are \(trend) this week",
                body: "\(thisWeekCount) sessions this week vs \(lastWeekCount) last week.",
                icon: diff >= 0 ? "arrow.up.right" : "arrow.down.right"
            ))
        }

        if !allAttempts.isEmpty {
            let bySubject = Dictionary(grouping: allAttempts, by: \.subjectId)
            if let weakest = bySubject.min(by: {
                let avgA = $0.value.reduce(0) { $0 + $1.scorePercent } / $0.value.count
                let avgB = $1.value.reduce(0) { $0 + $1.scorePercent } / $1.value.count
                return avgA < avgB
            }) {
                let avg = weakest.value.reduce(0) { $0 + $1.scorePercent } / weakest.value.count
                let name = subjects.first(where: { $0.id == weakest.key })?.name ?? "a subject"
                items.append(InsightItem(
                    tag: "NEEDS WORK",
                    tagColor: .orange,
                    title: "Quiz scores low in \(name)",
                    body: "Average quiz score of \(avg)% suggests \(name) needs more focused review sessions.",
                    icon: "exclamationmark.triangle"
                ))
            }
        }

        return items
    }

    var dailyActivity: [DailyActivity] {
        buildActivity(sessions: completedSessions, lookbackDays: 7, grouping: .day)
    }

    var monthActivity: [DailyActivity] {
        buildActivity(sessions: completedSessions, lookbackDays: 30, grouping: .day)
    }

    var quarterActivity: [DailyActivity] {
        buildActivity(sessions: completedSessions, lookbackDays: 90, grouping: .week)
    }
    
    var weekDistribution: [SubjectDistribution] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let filtered = completedSessions.filter { $0.scheduledDate >= cutoff }
        return Self.subjectDistribution(from: filtered)
    }

    var monthDistribution: [SubjectDistribution] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let filtered = completedSessions.filter { $0.scheduledDate >= cutoff }
        return Self.subjectDistribution(from: filtered)
    }

    var allDistribution: [SubjectDistribution] {
        Self.subjectDistribution(from: completedSessions)
    }

    static func subjectDistribution(from completedSessions: [StudySession]) -> [SubjectDistribution] {
        let total = Double(completedSessions.reduce(0) {
            $0 + ($1.actualDurationMinutes ?? $1.durationMinutes)
        })
        guard total > 0 else { return [] }

        let bySubject = Dictionary(grouping: completedSessions, by: \.subjectId)
        return bySubject.compactMap { (_, sessions) -> SubjectDistribution? in
            guard let first = sessions.first else { return nil }
            let minutes = Double(sessions.reduce(0) {
                $0 + ($1.actualDurationMinutes ?? $1.durationMinutes)
            })
            return SubjectDistribution(
                name: first.subjectName,
                percentage: minutes / total,
                color: Color(hex: first.subjectColorHex)
            )
        }
        .sorted { $0.percentage > $1.percentage }
    }

    // Resource utilization counts saved resources by type so the charts can show what material the user has added.
    var resourceUtilization: [ResourceUtilization] {
        let typeMapping: [(display: String, type: ResourceType, icon: String)] = [
            ("PDFs",       .pdf,       "doc.richtext.fill"),
            ("Notes",      .note,      "note.text"),
            ("Links",      .link,      "link"),
            ("Recordings", .recording, "waveform"),
            ("Slides",     .ppt,       "arrow.up.doc.fill")
        ]
        return typeMapping.compactMap { mapping in
            let count = allResources.filter { $0.resourceType == mapping.type }.count
            guard count > 0 else { return nil }
            return ResourceUtilization(
                type: mapping.display,
                icon: mapping.icon,
                count: count,
                color: mapping.type.color
            )
        }
    }

    var subjectNames: [String] {
        subjects.filter { !$0.isArchived }.map(\.name).sorted()
    }
    
    var subjectColors: [(name: String, color: Color)] {
        subjects.filter { !$0.isArchived }.map { ($0.name, Color(hex: $0.colorHex)) }
    }

    // Loads the progress inputs from Firebase-backed services, including per-subject quiz attempts and resources.
    // Only completed sessions are used for progress calculations because scheduled/skipped sessions should not count as study done.
    func load(userId: String?) async {
        guard let uid = userId, !uid.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        self.userId = uid
        userSettings = CoreDataService.shared.getCachedSettings(for: uid)

        async let sessionsFetch = StudySessionService.shared.fetchAll(userId: uid)
        async let subjectsFetch = SubjectService.shared.fetchSubjects(userId: uid)

        let fetchedSessions = (try? await sessionsFetch) ?? []
        let fetchedSubjects = (try? await subjectsFetch) ?? []

        var fetchedAttempts: [QuizAttempt] = []
        var fetchedResources: [Resource] = []

        await withTaskGroup(of: ([QuizAttempt], [Resource]).self) { group in
            for subject in fetchedSubjects {
                group.addTask {
                    async let attempts  = QuizService.shared.fetchAttempts(subjectId: subject.id)
                    async let resources = ResourceService.shared.fetchResources(subjectId: subject.id)
                    return ((try? await attempts) ?? [], (try? await resources) ?? [])
                }
            }
            for await (a, r) in group {
                fetchedAttempts.append(contentsOf: a)
                fetchedResources.append(contentsOf: r)
            }
        }

        allSessions  = fetchedSessions
        subjects     = fetchedSubjects
        allAttempts  = fetchedAttempts
        allResources = fetchedResources

        let completed = fetchedSessions.filter { $0.status == .completed }
        completedSessions = completed
        streak = ProgressViewModel.computeStreak(from: completed)

        Task { await updateSubjectHours(subjects: fetchedSubjects, sessions: completed, userId: uid) }
    }

    // Counts unique study days, finds the longest consecutive run, and then checks backwards from today for the current streak.
    static func computeStreak(from sessions: [StudySession]) -> StudyStreak {
        let cal = Calendar.current
        let studyDays = Set(sessions.map { cal.startOfDay(for: $0.scheduledDate) })
        let sortedDays = studyDays.sorted()
        guard !sortedDays.isEmpty else { return StudyStreak() }

        var longestRun = 1, currentRun = 1
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i - 1]
            let curr = sortedDays[i]
            if let expected = cal.date(byAdding: .day, value: 1, to: prev),
               cal.isDate(expected, inSameDayAs: curr) {
                currentRun += 1
                longestRun = max(longestRun, currentRun)
            } else {
                currentRun = 1
            }
        }

        let today = cal.startOfDay(for: Date())
        var current = 0
        var checkDay = today
        while studyDays.contains(checkDay) {
            current += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prev
        }

        let streakStart = current > 0
            ? cal.date(byAdding: .day, value: -(current - 1), to: today)
            : nil

        return StudyStreak(
            currentStreak: current,
            longestStreak: longestRun,
            lastStudyDate: sortedDays.last,
            streakStartDate: streakStart
        )
    }

    private enum ActivityGrouping { case day, week }

    // Builds chart points from completed sessions by grouping minutes into days or weeks, then splitting those totals by subject.
    private func buildActivity(sessions: [StudySession],
                               lookbackDays: Int,
                               grouping: ActivityGrouping) -> [DailyActivity] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -lookbackDays, to: Date()) ?? Date()
        let recent = sessions.filter { $0.scheduledDate >= cutoff }

        switch grouping {
        case .day:
            let dayLabels = ["SUN","MON","TUE","WED","THU","FRI","SAT"]
            let byDay = Dictionary(grouping: recent) { cal.startOfDay(for: $0.scheduledDate) }
            var result: [DailyActivity] = []
            for (day, daySessions) in byDay {
                let bySubject = Dictionary(grouping: daySessions, by: \.subjectId)
                for (_, subSessions) in bySubject {
                    guard let first = subSessions.first else { continue }
                    let hours = Double(subSessions.reduce(0) {
                        $0 + ($1.actualDurationMinutes ?? $1.durationMinutes)
                    }) / 60.0
                    let label: String
                    if lookbackDays <= 7 {
                        let weekdayIdx = cal.component(.weekday, from: day)
                        label = dayLabels[weekdayIdx - 1]
                    } else {
                        label = "\(cal.component(.day, from: day))"
                    }
                    result.append(DailyActivity(
                        day: label,
                        date: day,
                        hours: hours,
                        subject: first.subjectName,
                        color: Color(hex: first.subjectColorHex)
                    ))
                }
            }
            return result

        case .week:
            var result: [DailyActivity] = []
            for weekIndex in 0..<13 {
                guard let weekStart = cal.date(byAdding: .day, value: weekIndex * 7, to: cutoff),
                      let weekEnd   = cal.date(byAdding: .day, value: 7, to: weekStart) else { continue }
                let weekSessions = recent.filter { $0.scheduledDate >= weekStart && $0.scheduledDate < weekEnd }
                guard !weekSessions.isEmpty else { continue }
                let bySubject = Dictionary(grouping: weekSessions, by: \.subjectId)
                for (_, subSessions) in bySubject {
                    guard let first = subSessions.first else { continue }
                    let hours = Double(subSessions.reduce(0) {
                        $0 + ($1.actualDurationMinutes ?? $1.durationMinutes)
                    }) / 60.0
                    result.append(DailyActivity(
                        day: "W\(weekIndex + 1)",
                        date: weekStart,
                        hours: hours,
                        subject: first.subjectName,
                        color: Color(hex: first.subjectColorHex)
                    ))
                }
            }
            return result
        }
    }

    // Keeps each subject's stored totalHoursStudied aligned with completed session history.
    private func updateSubjectHours(subjects: [Subject], sessions: [StudySession], userId: String) async {
        for subject in subjects {
            let subjectSessions = sessions.filter { $0.subjectId == subject.id }
            let totalHours = Double(subjectSessions.reduce(0) {
                $0 + ($1.actualDurationMinutes ?? $1.durationMinutes)
            }) / 60.0
            guard abs(subject.totalHoursStudied - totalHours) > 0.01 else { continue }
            var updated = subject
            updated.totalHoursStudied = totalHours
            updated.updatedAt = Date()
            try? await SubjectService.shared.updateSubject(updated)
        }
    }
}
