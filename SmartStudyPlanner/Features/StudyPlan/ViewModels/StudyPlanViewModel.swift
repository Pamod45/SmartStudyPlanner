import Combine
import SwiftUI

// Keeps the study plan screen in sync with Core Data, Firebase, Calendar, and reminders.
// Availability is the source of truth for where sessions are allowed to exist.
@MainActor
class StudyPlanViewModel: ObservableObject {
    @Published var studyPlans: [StudyPlan] = []
    @Published var availabilitySlots: [AvailabilitySlot] = []
    @Published var studySessions: [StudySession] = []
    @Published var deadlines: [Deadline] = []
    @Published var subjects: [Subject] = []
    @Published var studyPathTopics: [String: [StudyPathTopic]] = [:]
    @Published var isLoading: Bool = false
    private(set) var currentUserId: String = ""

    // Loads cached data first so the screen opens quickly, then replaces it with Firebase data.
    // After loading, sessions are checked against availability so deleted or changed slots do not leave orphan sessions behind.
    func load(userId: String?) async {
        guard let userId, !userId.isEmpty else { return }
        currentUserId = userId
        isLoading = true
        defer { isLoading = false }

        let cachedSlots = CoreDataService.shared.getCachedAvailabilitySlots(for: userId)
        if !cachedSlots.isEmpty {
            availabilitySlots = sortedByStartTime(cachedSlots)
        }

        let cachedSessions = CoreDataService.shared.getCachedStudySessions(for: userId)
        if !cachedSessions.isEmpty {
            studySessions = cachedSessions.sorted { $0.startTime < $1.startTime }
        }

        async let fetchedSlots    = try? AvailabilitySlotService.shared.fetchAll(userId: userId)
        async let fetchedSessions = try? StudySessionService.shared.fetchAll(userId: userId)
        async let fetchedSubjects = try? SubjectService.shared.fetchSubjects(userId: userId)

        if let remoteSlots = await fetchedSlots {
            availabilitySlots = sortedByStartTime(remoteSlots)
        }
        if let remoteSessions = await fetchedSessions {
            studySessions = remoteSessions.sorted { $0.startTime < $1.startTime }
        }
        subjects = await fetchedSubjects ?? []
        pruneSessionsOutsideAvailability(removeAllWhenNoSlots: false)

        await loadStudyPathTopics()
    }

    // Fetches study path topics per subject in parallel because generated plans need topic duration and resource IDs.
    private func loadStudyPathTopics() async {
        var map: [String: [StudyPathTopic]] = [:]
        await withTaskGroup(of: (String, [StudyPathTopic]).self) { group in
            for subject in subjects {
                group.addTask {
                    let topics = (try? await StudyPathService.shared.fetchStudyPath(for: subject.id)) ?? []
                    return (subject.id, topics)
                }
            }
            for await (subjectId, topics) in group {
                map[subjectId] = topics
            }
        }
        studyPathTopics = map
    }

    // Date ranges are stored as individual daily slots so each day can be deleted independently later.
    func addAvailabilitySlot(_ slot: AvailabilitySlot) {
        if slot.type == .dateRange {
            addAvailabilitySlots(expandRangeSlot(slot))
            return
        }

        addSingleAvailabilitySlot(slot)
    }

    private func addAvailabilitySlots(_ slots: [AvailabilitySlot]) {
        slots.forEach { addSingleAvailabilitySlot($0) }
    }

    // Adds a slot optimistically to local state/Core Data, then uploads it to Firebase in the background.
    private func addSingleAvailabilitySlot(_ slot: AvailabilitySlot) {
        guard !isPastAvailabilitySlot(slot) else { return }

        var stamped = slot
        stamped.userId     = currentUserId
        stamped.syncStatus = .pendingUpload
        availabilitySlots.append(stamped)
        CoreDataService.shared.upsertAvailabilitySlot(stamped)

        Task {
            do {
                var synced = stamped
                synced.syncStatus = .synced
                try await AvailabilitySlotService.shared.save(synced)
                await MainActor.run {
                    self.updateAvailabilitySlot(synced)
                }
            } catch {
            }
        }
    }

    // Converts a date-range availability into one specific-date slot per valid day.
    // Past dates are dropped here, so old availability cannot be created from the range picker.
    private func expandRangeSlot(_ slot: AvailabilitySlot) -> [AvailabilitySlot] {
        guard let rangeStart = slot.rangeStart, let rangeEnd = slot.rangeEnd else { return [slot] }

        let cal = Calendar.current
        var dates: [Date] = []
        var current = cal.startOfDay(for: rangeStart)
        let last = cal.startOfDay(for: rangeEnd)

        while current <= last {
            dates.append(current)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return dates.filter { !Calendar.current.startOfDay(for: $0).isBeforeToday }.map { date in
            AvailabilitySlot(
                userId: slot.userId,
                type: .specificDate,
                startTime: slot.startTime,
                endTime: slot.endTime,
                date: date,
                rangeStart: nil,
                rangeEnd: nil,
                label: slot.label,
                createdAt: slot.createdAt,
                updatedAt: Date(),
                syncStatus: slot.syncStatus
            )
        }
    }

    // Removing availability also removes sessions inside that slot from UI, Core Data, Firebase, Calendar, and notifications.
    func removeAvailabilitySlot(id: String) {
        guard let slot = availabilitySlots.first(where: { $0.id == id }) else { return }
        let sessionsToDelete = studySessions.filter { sessionBelongs($0, to: slot) }
        let sessionIdsToDelete = sessionsToDelete.map(\.id)

        availabilitySlots.removeAll { $0.id == id }
        studySessions.removeAll { sessionIdsToDelete.contains($0.id) }
        CoreDataService.shared.deleteAvailabilitySlot(id: id)
        CoreDataService.shared.deleteStudySessions(ids: sessionIdsToDelete)
        pruneSessionsOutsideAvailability(removeAllWhenNoSlots: true)

        Task {
            for session in sessionsToDelete {
                if let eventId = session.externalCalendarEventId {
                    try? CalendarSyncService.shared.removeEvent(id: eventId)
                }
            }
            try? await AvailabilitySlotService.shared.delete(id: id)
            try? await StudySessionService.shared.deleteAll(ids: sessionIdsToDelete)
        }
    }

    // Manual sessions are accepted only when they fit inside an availability slot.
    // The local cache updates immediately, then Firebase, Calendar, and reminders are updated asynchronously.
    func addSession(_ session: StudySession) {
        guard sessionFitsAnyAvailabilitySlot(session) else { return }

        var stamped = session
        stamped.userId     = currentUserId
        stamped.syncStatus = .pendingUpload
        studySessions.append(stamped)
        CoreDataService.shared.upsertStudySession(stamped)

        Task {
            do {
                var synced = stamped
                synced.syncStatus = .synced
                try await StudySessionService.shared.save(synced)
                if let eventId = try? await CalendarSyncService.shared.export(synced) {
                    synced.externalCalendarEventId = eventId
                    try? await StudySessionService.shared.update(synced)
                }
                await MainActor.run {
                    self.replaceStudySession(synced)
                    let settings = CoreDataService.shared.getCachedSettings(for: self.currentUserId) ?? .default
                    NotificationService.shared.scheduleSessionReminder(session: synced, settings: settings)
                }
            } catch {
            }
        }
    }

    // Generated plans can contain many sessions, so this filters invalid sessions before doing one bulk cache/upload path.
    func addSessions(_ sessions: [StudySession]) {
        let validSessions = sessions.filter { sessionFitsAnyAvailabilitySlot($0) }
        guard !validSessions.isEmpty else { return }

        let stamped = validSessions.map { s -> StudySession in
            var s = s
            s.userId     = currentUserId
            s.syncStatus = .pendingUpload
            return s
        }
        studySessions.append(contentsOf: stamped)
        CoreDataService.shared.cacheStudySessions(stamped)

        Task {
            do {
                var synced = stamped.map { s -> StudySession in
                    var s = s; s.syncStatus = .synced; return s
                }
                try await StudySessionService.shared.saveAll(synced)
                let mapping = await CalendarSyncService.shared.exportAll(synced)
                for (sessionId, eventId) in mapping {
                    if let idx = synced.firstIndex(where: { $0.id == sessionId }) {
                        synced[idx].externalCalendarEventId = eventId
                        try? await StudySessionService.shared.update(synced[idx])
                    }
                }
                await MainActor.run {
                    synced.forEach { self.replaceStudySession($0) }
                    let settings = CoreDataService.shared.getCachedSettings(for: self.currentUserId) ?? .default
                    synced.forEach { NotificationService.shared.scheduleSessionReminder(session: $0, settings: settings) }
                }
            } catch {
            }
        }
    }

    // Marks the session as pending locally first, then writes the final synced version after Firebase accepts it.
    func updateSession(_ session: StudySession) {
        var stamped = session
        if stamped.userId.isEmpty { stamped.userId = currentUserId }
        stamped.syncStatus = .pendingUpdate
        if let idx = studySessions.firstIndex(where: { $0.id == stamped.id }) {
            studySessions[idx] = stamped
        }
        CoreDataService.shared.upsertStudySession(stamped)

        Task {
            do {
                var synced = stamped
                synced.syncStatus = .synced
                try await StudySessionService.shared.update(synced)
                await MainActor.run {
                    self.replaceStudySession(synced)
                    let settings = CoreDataService.shared.getCachedSettings(for: self.currentUserId) ?? .default
                    NotificationService.shared.scheduleSessionReminder(session: synced, settings: settings)
                }
            } catch {
            }
        }
    }

    // Deletes a session from every place that can keep a copy: screen state, Core Data, Firebase, Calendar, and reminders.
    func removeSession(id: String) {
        let calendarEventId = studySessions.first(where: { $0.id == id })?.externalCalendarEventId

        studySessions.removeAll { $0.id == id }
        CoreDataService.shared.deleteStudySession(id: id)
        NotificationService.shared.cancelNotifications(ids: ["session-\(id)", "quiz-\(id)"])

        Task {
            if let eventId = calendarEventId {
                try? CalendarSyncService.shared.removeEvent(id: eventId)
            }
            try? await StudySessionService.shared.delete(id: id)
        }
    }


    // Pushes sessions without calendar IDs into the user's calendar and stores the event IDs for future updates/removal.
    func syncAllToCalendar() {
        let pending = studySessions.filter { $0.externalCalendarEventId == nil && $0.status == .scheduled }
        Task {
            let mapping = await CalendarSyncService.shared.exportAll(pending)
            for (sessionId, eventId) in mapping {
                if let idx = studySessions.firstIndex(where: { $0.id == sessionId }) {
                    studySessions[idx].externalCalendarEventId = eventId
                    try? await StudySessionService.shared.update(studySessions[idx])
                }
            }
        }
    }

    func slotsForDate(_ date: Date) -> [AvailabilitySlot] {
        let cal = Calendar.current
        return availabilitySlots
            .filter { $0.applies(on: date) }
            .sorted {
                let lh = cal.component(.hour, from: $0.startTime) * 60 + cal.component(.minute, from: $0.startTime)
                let rh = cal.component(.hour, from: $1.startTime) * 60 + cal.component(.minute, from: $1.startTime)
                return lh < rh
            }
    }

    func sessionsForDate(_ date: Date) -> [StudySession] {
        studySessions
            .filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    private func sortedByStartTime(_ slots: [AvailabilitySlot]) -> [AvailabilitySlot] {
        let cal = Calendar.current
        return slots.sorted {
            let lh = cal.component(.hour, from: $0.startTime) * 60 + cal.component(.minute, from: $0.startTime)
            let rh = cal.component(.hour, from: $1.startTime) * 60 + cal.component(.minute, from: $1.startTime)
            return lh < rh
        }
    }

    func deadlinesForDate(_ date: Date) -> [Deadline] {
        deadlines.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: date) }
    }

    private func sessionBelongs(_ session: StudySession, to slot: AvailabilitySlot) -> Bool {
        let cal = Calendar.current
        let sessionDay = session.scheduledDate

        guard slot.applies(on: sessionDay) || slot.applies(on: session.startTime) else {
            return false
        }

        let slotStartMinutes = minutesSinceStartOfDay(slot.startTime, calendar: cal)
        let slotEndMinutes = minutesSinceStartOfDay(slot.endTime, calendar: cal)
        let sessionStartMinutes = minutesSinceStartOfDay(session.startTime, calendar: cal)
        let sessionEndMinutes = minutesSinceStartOfDay(session.endTime, calendar: cal)

        return sessionStartMinutes >= slotStartMinutes
            && sessionEndMinutes <= slotEndMinutes
            && session.endTime > session.startTime
    }

    private func minutesSinceStartOfDay(_ date: Date, calendar: Calendar) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    private func isPastAvailabilitySlot(_ slot: AvailabilitySlot) -> Bool {
        let cal = Calendar.current
        switch slot.type {
        case .specificDate:
            guard let date = slot.date else { return false }
            return cal.startOfDay(for: date).isBeforeToday
        case .dateRange:
            guard let end = slot.rangeEnd else { return false }
            return cal.startOfDay(for: end).isBeforeToday
        }
    }

    private func sessionFitsAnyAvailabilitySlot(_ session: StudySession) -> Bool {
        availabilitySlots.contains { sessionFits(session, in: $0) }
    }

    // Cleans up sessions that no longer fit any availability slot after slots are loaded, edited, or removed.
    private func pruneSessionsOutsideAvailability(removeAllWhenNoSlots: Bool) {
        guard !studySessions.isEmpty else { return }
        guard removeAllWhenNoSlots || !availabilitySlots.isEmpty else { return }

        let invalidSessionIds = studySessions
            .filter { session in
                availabilitySlots.isEmpty || !sessionFitsAnyAvailabilitySlot(session)
            }
            .map(\.id)
        guard !invalidSessionIds.isEmpty else { return }

        studySessions.removeAll { invalidSessionIds.contains($0.id) }
        CoreDataService.shared.deleteStudySessions(ids: invalidSessionIds)
        Task {
            try? await StudySessionService.shared.deleteAll(ids: invalidSessionIds)
        }
    }

    // Compares only the day and time window, which keeps date-range and specific-date slots using the same rule.
    private func sessionFits(_ session: StudySession, in slot: AvailabilitySlot) -> Bool {
        let cal = Calendar.current
        let sessionDay = session.scheduledDate

        guard slot.applies(on: sessionDay) || slot.applies(on: session.startTime) else {
            return false
        }

        let slotStartMinutes = minutesSinceStartOfDay(slot.startTime, calendar: cal)
        let slotEndMinutes = minutesSinceStartOfDay(slot.endTime, calendar: cal)
        let sessionStartMinutes = minutesSinceStartOfDay(session.startTime, calendar: cal)
        let sessionEndMinutes = minutesSinceStartOfDay(session.endTime, calendar: cal)

        return sessionStartMinutes >= slotStartMinutes
            && sessionEndMinutes <= slotEndMinutes
            && session.endTime > session.startTime
    }

    private func updateAvailabilitySlot(_ slot: AvailabilitySlot) {
        if let idx = availabilitySlots.firstIndex(where: { $0.id == slot.id }) {
            availabilitySlots[idx] = slot
        } else {
            availabilitySlots.append(slot)
        }
        CoreDataService.shared.upsertAvailabilitySlot(slot)
    }

    private func replaceStudySession(_ session: StudySession) {
        if let idx = studySessions.firstIndex(where: { $0.id == session.id }) {
            studySessions[idx] = session
        } else {
            studySessions.append(session)
        }
        CoreDataService.shared.upsertStudySession(session)
    }
}

private extension Date {
    var isBeforeToday: Bool {
        self < Calendar.current.startOfDay(for: .now)
    }
}
