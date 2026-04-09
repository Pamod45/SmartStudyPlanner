import SwiftUI

struct CalendarView: UIViewRepresentable {
    @Binding var selectedDate: DateComponents?
    var slots: [AvailabilitySlot]
    var sessions: [StudySession] = []
    var deadlines: [Deadline] = []
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

        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            if selection.selectedDate != selectedDate {
                selection.setSelected(selectedDate, animated: false)
            }
        }

        let allDates = decoratedDates()
        uiView.reloadDecorations(forDateComponents: allDates, animated: true)
    }

    private func decoratedDates() -> [DateComponents] {
        var dates: Set<DateComponents> = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: i, to: today) else { continue }
            let comps = calendar.dateComponents([.year, .month, .day], from: date)
            let hasSlot = slots.contains { slot in
                switch slot.type {
                case .date:   return slot.date.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                case .daily:  return true
                case .weekly: return slot.weekday == calendar.component(.weekday, from: date)
                case .range:
                    guard let s = slot.rangeStart, let e = slot.rangeEnd else { return false }
                    return date >= s && date <= e
                }
            }
            if hasSlot { dates.insert(comps) }
        }

        for session in sessions {
            let comps = calendar.dateComponents([.year, .month, .day], from: session.startTime)
            dates.insert(comps)
        }

        for deadline in deadlines {
            let comps = calendar.dateComponents([.year, .month, .day], from: deadline.date)
            dates.insert(comps)
        }

        return Array(dates)
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
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            let cal = Calendar.current

            let hasSlot = parent.slots.contains { slot in
                switch slot.type {
                case .date:   return slot.date.map { cal.isDate($0, inSameDayAs: date) } ?? false
                case .daily:  return true
                case .weekly: return slot.weekday == cal.component(.weekday, from: date)
                case .range:
                    guard let s = slot.rangeStart, let e = slot.rangeEnd else { return false }
                    return date >= s && date <= e
                }
            }

            let hasSession = parent.sessions.contains { cal.isDate($0.startTime, inSameDayAs: date) }
            let hasDeadline = parent.deadlines.contains { cal.isDate($0.date, inSameDayAs: date) }

            guard hasSlot || hasSession || hasDeadline else { return nil }

            return .customView {
                let dotSize: CGFloat = 6
                let gap: CGFloat = 3
                var dotColors: [UIColor] = []
                if hasSlot     { dotColors.append(UIColor(self.parent.theme.colors.primary)) }
                if hasSession  { dotColors.append(.systemGreen) }
                if hasDeadline { dotColors.append(.systemRed) }

                let totalWidth = CGFloat(dotColors.count) * dotSize + CGFloat(max(dotColors.count - 1, 0)) * gap

                final class DotContainerView: UIView {
                    var dotSize: CGSize = .zero
                    override var intrinsicContentSize: CGSize { dotSize }
                }

                let container = DotContainerView()
                container.dotSize = CGSize(width: totalWidth, height: dotSize)
                container.frame = CGRect(x: 0, y: 0, width: totalWidth, height: dotSize)

                var xOffset: CGFloat = 0
                for color in dotColors {
                    let v = UIView(frame: CGRect(x: xOffset, y: 0, width: dotSize, height: dotSize))
                    v.backgroundColor = color
                    v.layer.cornerRadius = dotSize / 2
                    container.addSubview(v)
                    xOffset += dotSize + gap
                }
                return container
            }
        }
    }
}
