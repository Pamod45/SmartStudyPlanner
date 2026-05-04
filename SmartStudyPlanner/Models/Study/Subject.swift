import SwiftUI
import FirebaseFirestore

struct Subject: Identifiable, Hashable, Codable, Syncable {
    var id: String
    var userId: String
    var name: String
    var colorHex: String
    var notes: String
    var iconName: String
    var targetHoursPerWeek: Double
    var totalHoursStudied: Double
    var resourceCount: Int
    var topicCount: Int
    var deadlineIds: [String]
    var resourceIds: [String]
    var sessionIds: [String]
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus
    var noteFilePaths: [String]


    var color: Color {
        Color(hex: colorHex)
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        name: String,
        colorHex: String = "#3B82F6",
        notes: String = "",
        iconName: String = "book.fill",
        targetHoursPerWeek: Double = 0,
        totalHoursStudied: Double = 0,
        resourceCount: Int = 0,
        topicCount: Int = 0,
        deadlineIds: [String] = [],
        resourceIds: [String] = [],
        sessionIds: [String] = [],
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly,
        sessionIds: [String] = []

    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.colorHex = colorHex
        self.notes = notes
        self.iconName = iconName
        self.targetHoursPerWeek = targetHoursPerWeek
        self.totalHoursStudied = totalHoursStudied
        self.resourceCount = resourceCount
        self.topicCount = topicCount
        self.deadlineIds = deadlineIds
        self.resourceIds = resourceIds
        self.sessionIds = sessionIds
        self.noteFilePaths = noteFilePaths
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }

    var firestoreData: [String: Any] {
        let created = Self.clampDate(createdAt, fallback: Date())
        let updated = Self.clampDate(updatedAt, fallback: Date())

        return [
            "id": id,
            "userId": userId,
            "name": name,
            "colorHex": colorHex,
            "notes": notes,
            "iconName": iconName,
            "targetHoursPerWeek": targetHoursPerWeek,
            "totalHoursStudied": totalHoursStudied,
            "resourceCount": resourceCount,
            "topicCount": topicCount,
            "deadlineIds": deadlineIds,
            "resourceIds": resourceIds,
            "sessionIds": sessionIds,
            "noteFilePaths": noteFilePaths,
            "isArchived": isArchived,
            "createdAt": created,
            "updatedAt": updated,
            "syncStatus": syncStatus.rawValue
        ]
    }

    init?(from data: [String: Any], id: String) {
        let userId = data["userId"] as? String ?? ""
        let name = data["name"] as? String ?? ""
        if name.isEmpty { return nil }

        func dateValue(_ key: String, fallback: Date) -> Date {
            if let ts = data[key] as? Timestamp { return ts.dateValue() }
            if let date = data[key] as? Date { return date }
            return fallback
        }

        let createdAt = Self.clampDate(dateValue("createdAt", fallback: Date()), fallback: Date())
        let updatedAt = Self.clampDate(dateValue("updatedAt", fallback: Date()), fallback: Date())

        self.init(
            id: data["id"] as? String ?? id,
            userId: userId,
            name: name,
            colorHex: data["colorHex"] as? String ?? "#3B82F6",
            notes: data["notes"] as? String ?? "",
            iconName: data["iconName"] as? String ?? "book.fill",
            targetHoursPerWeek: data["targetHoursPerWeek"] as? Double ?? 0,
            totalHoursStudied: data["totalHoursStudied"] as? Double ?? 0,
            resourceCount: data["resourceCount"] as? Int ?? Int((data["resourceCount"] as? Int64) ?? 0),
            topicCount: data["topicCount"] as? Int ?? Int((data["topicCount"] as? Int64) ?? 0),
            deadlineIds: data["deadlineIds"] as? [String] ?? [],
            resourceIds: data["resourceIds"] as? [String] ?? [],
            sessionIds: data["sessionIds"] as? [String] ?? [],
            noteFilePaths: data["noteFilePaths"] as? [String] ?? [],
            isArchived: data["isArchived"] as? Bool ?? false,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus(rawValue: data["syncStatus"] as? String ?? "") ?? .localOnly
        )
    }

    private static func clampDate(_ date: Date, fallback: Date) -> Date {
        let seconds = date.timeIntervalSince1970
        if seconds < -62135596800 || seconds >= 253402300800 {
            return fallback
        }
        return date
    }
}

