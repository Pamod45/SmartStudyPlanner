import Foundation

enum AvailabilityType: String, CaseIterable, Identifiable, Codable {
    case specificDate = "Date"
    case dateRange    = "Date Range"
    var id: String { rawValue }
}

struct AvailabilitySlot: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var type: AvailabilityType
    var startTime: Date     
    var endTime: Date
    var date: Date?
    var rangeStart: Date?
    var rangeEnd: Date?
    var label: String?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    var formattedTimeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: startTime)) – \(f.string(from: endTime))"
    }

    /// Returns true if this slot is active on the given calendar day.
    func applies(on day: Date) -> Bool {
        let cal = Calendar.current
        switch type {
        case .specificDate:
            return date.map { cal.isDate($0, inSameDayAs: day) } ?? false
        case .dateRange:
            guard let s = rangeStart, let e = rangeEnd else { return false }
            let d   = cal.startOfDay(for: day)
            let s0  = cal.startOfDay(for: s)
            let e0  = cal.startOfDay(for: e)
            return d >= s0 && d <= e0
        }
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        type: AvailabilityType = .specificDate,
        startTime: Date = Calendar.current.date(bySettingHour: 9,  minute: 0, second: 0, of: .now) ?? .now,
        endTime: Date   = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: .now) ?? .now,
        date: Date? = .now,
        rangeStart: Date? = nil,
        rangeEnd: Date? = nil,
        label: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id         = id
        self.userId     = userId
        self.type       = type
        self.startTime  = startTime
        self.endTime    = endTime
        self.date       = date
        self.rangeStart = rangeStart
        self.rangeEnd   = rangeEnd
        self.label      = label
        self.createdAt  = createdAt
        self.updatedAt  = updatedAt
        self.syncStatus = syncStatus
    }
}
