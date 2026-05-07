import Foundation
import EventKit
import Combine

final class CalendarSyncService {
    static let shared = CalendarSyncService()
    private let store = EKEventStore()
    private init() {}

    func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in
                    cont.resume(returning: granted)
                }
            }
        }
    }

    var hasPermission: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess ||
        EKEventStore.authorizationStatus(for: .event) == .authorized
    }
    
    @discardableResult
    func export(_ session: StudySession) async throws -> String {
        if !hasPermission {
            let granted = await requestPermission()
            guard granted else { throw CalendarSyncError.permissionDenied }
        }

        let event = EKEvent(eventStore: store)
        event.title    = "[\(session.subjectName)] \(session.topic.isEmpty ? session.title : session.topic)"
        event.startDate = session.startTime
        event.endDate   = session.endTime
        event.notes     = session.notes
        event.calendar  = store.defaultCalendarForNewEvents

        if let existingId = session.externalCalendarEventId,
           let existing = store.event(withIdentifier: existingId) {
            existing.title     = event.title
            existing.startDate = event.startDate
            existing.endDate   = event.endDate
            existing.notes     = event.notes
            try store.save(existing, span: .thisEvent)
            return existing.eventIdentifier
        }

        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    func exportAll(_ sessions: [StudySession]) async -> [String: String] {
        var mapping: [String: String] = [:]
        for session in sessions {
            guard let eventId = try? await export(session) else { continue }
            mapping[session.id] = eventId
        }
        return mapping
    }

    func removeEvent(id: String) throws {
        guard hasPermission else { return }
        if let event = store.event(withIdentifier: id) {
            try store.remove(event, span: .thisEvent)
        }
    }
    
    enum CalendarSyncError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            "Calendar access was denied. Please enable it in Settings → Privacy → Calendars."
        }
    }
}
