import SwiftUI

enum AvailabilityType: String, CaseIterable, Identifiable {
    case date    = "Date"
    case daily   = "Daily"
    case weekly  = "Weekly"
    case range   = "C. Range"
    var id: String { rawValue }
}

struct AvailabilitySlot: Identifiable {
    let id: UUID
    var type: AvailabilityType
    var startTime: Date
    var endTime: Date
    var date: Date?
    var weekday: Int?
    var rangeStart: Date?
    var rangeEnd: Date?

    init(
        id: UUID = UUID(),
        type: AvailabilityType = .date,
        startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now,
        endTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: .now) ?? .now,
        date: Date? = .now,
        weekday: Int? = nil,
        rangeStart: Date? = nil,
        rangeEnd: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.date = date
        self.weekday = weekday
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
    }

    var formattedTimeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: startTime)) - \(f.string(from: endTime))"
    }

    static let samples: [AvailabilitySlot] = [
        AvailabilitySlot(
            type: .date,
            startTime: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: .now)!,
            endTime: Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: .now)!,
            date: .now
        ),
        AvailabilitySlot(
            type: .daily,
            startTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!,
            endTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now)!
        )
    ]
}
