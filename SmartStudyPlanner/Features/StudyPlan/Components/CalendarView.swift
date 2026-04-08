import SwiftUI

struct CalendarView: UIViewRepresentable {
    @Binding var selectedDate: DateComponents?
    var slots: [AvailabilitySlot]
    @Environment(\.theme) var theme

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendar = UICalendarView()
        calendar.calendar = .current
        calendar.locale = .current
        calendar.fontDesign = .rounded
        calendar.tintColor = UIColor(theme.colors.primary)
        calendar.backgroundColor = .clear
        calendar.wantsDateDecorations = true
        calendar.delegate = context.coordinator

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendar.selectionBehavior = selection

        return calendar
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        uiView.tintColor = UIColor(theme.colors.primary)
        context.coordinator.parent = self

        let allDates = decoratedDates()
        uiView.reloadDecorations(forDateComponents: allDates, animated: true)
    }

    private func decoratedDates() -> [DateComponents] {
        var dates: [DateComponents] = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: i, to: today) else { continue }
            let comps = calendar.dateComponents([.year, .month, .day], from: date)

            let hasSlot = slots.contains { slot in
                switch slot.type {
                case .date:
                    return slot.date.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                case .daily:
                    return true
                case .weekly:
                    return slot.weekday == calendar.component(.weekday, from: date)
                case .range:
                    guard let start = slot.rangeStart, let end = slot.rangeEnd else { return false }
                    return date >= start && date <= end
                }
            }

            if hasSlot { dates.append(comps) }
        }
        return dates
    }

    class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate, UICalendarViewDelegate {
        var parent: CalendarView

        init(_ parent: CalendarView) {
            self.parent = parent
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDate = dateComponents
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let hasSlot = parent.slots.contains { slot in
                guard let date = Calendar.current.date(from: dateComponents) else { return false }
                switch slot.type {
                case .date:
                    return slot.date.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                case .daily:
                    return true
                case .weekly:
                    return slot.weekday == Calendar.current.component(.weekday, from: date)
                case .range:
                    guard let start = slot.rangeStart, let end = slot.rangeEnd else { return false }
                    return date >= start && date <= end
                }
            }

            guard hasSlot else { return nil }
            return .default(color: UIColor(parent.theme.colors.primary), size: .small)
        }
    }
}
