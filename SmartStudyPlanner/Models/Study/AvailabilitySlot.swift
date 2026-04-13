import Foundation

enum AvailabilityType: String, CaseIterable, Identifiable, Codable {
    case date    = "Date"
    case daily   = "Daily"
    case weekly  = "Weekly"
    case range   = "C. Range"
    var id: String { rawValue }
}

struct AvailabilitySlot: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var type: AvailabilityType
    var startTime: Date
    var endTime: Date
    var date: Date?
    var weekday: Int?
    var rangeStart: Date?
    var rangeEnd: Date?
    var label: String?
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var formattedTimeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: startTime)) - \(f.string(from: endTime))"
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        type: AvailabilityType = .date,
        startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now,
        endTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: .now) ?? .now,
        date: Date? = .now,
        weekday: Int? = nil,
        rangeStart: Date? = nil,
        rangeEnd: Date? = nil,
        label: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.date = date
        self.weekday = weekday
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.label = label
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
