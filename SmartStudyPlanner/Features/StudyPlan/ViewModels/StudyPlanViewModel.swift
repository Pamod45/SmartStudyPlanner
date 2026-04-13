import Combine

import SwiftUI

@MainActor
class StudyPlanViewModel: ObservableObject {
    @Published var studyPlans: [StudyPlan] = []
    @Published var availabilitySlots: [AvailabilitySlot] = []
    @Published var studySessions: [StudySession] = []
    @Published var deadlines: [Deadline] = []
    @Published var isLoading: Bool = false

    func load(userId: String?) async {
        isLoading = true
        defer { isLoading = false }
    }

    func addAvailabilitySlot(_ slot: AvailabilitySlot) {
        availabilitySlots.append(slot)
    }

    func removeAvailabilitySlot(id: String) {
        availabilitySlots.removeAll { $0.id == id }
    }

    func addSession(_ session: StudySession) {
        studySessions.append(session)
    }

    func updateSession(_ session: StudySession) {
        if let idx = studySessions.firstIndex(where: { $0.id == session.id }) {
            studySessions[idx] = session
        }
    }

    func removeSession(id: String) {
        studySessions.removeAll { $0.id == id }
    }

    func slotsForDate(_ date: Date) -> [AvailabilitySlot] {
        let cal = Calendar.current
        return availabilitySlots.filter { slot in
            switch slot.type {
            case .date:
                return slot.date.map { cal.isDate($0, inSameDayAs: date) } ?? false
            case .daily:
                return true
            case .weekly:
                return slot.weekday == cal.component(.weekday, from: date)
            case .range:
                guard let s = slot.rangeStart, let e = slot.rangeEnd else { return false }
                return date >= s && date <= e
            }
        }
    }

    func sessionsForDate(_ date: Date) -> [StudySession] {
        Calendar.current.isDateInToday(date)
            ? studySessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
            : studySessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
    }

    func deadlinesForDate(_ date: Date) -> [Deadline] {
        deadlines.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: date) }
    }
}
