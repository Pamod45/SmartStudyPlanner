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
        noteFilePaths: [String] = []

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

        let subjectId = data["id"] as? String ?? id
        let colorHex = data["colorHex"] as? String ?? "#3B82F6"
        let notes = data["notes"] as? String ?? ""
        let iconName = data["iconName"] as? String ?? "book.fill"
        let targetHoursPerWeek = data["targetHoursPerWeek"] as? Double ?? 0
        let totalHoursStudied = data["totalHoursStudied"] as? Double ?? 0
        
        let resourceCount: Int
        if let count = data["resourceCount"] as? Int {
            resourceCount = count
        } else if let count64 = data["resourceCount"] as? Int64 {
            resourceCount = Int(count64)
        } else {
            resourceCount = 0
        }
        
        let topicCount: Int
        if let count = data["topicCount"] as? Int {
            topicCount = count
        } else if let count64 = data["topicCount"] as? Int64 {
            topicCount = Int(count64)
        } else {
            topicCount = 0
        }
        
        let deadlineIds = data["deadlineIds"] as? [String] ?? []
        let resourceIds = data["resourceIds"] as? [String] ?? []
        let sessionIds = data["sessionIds"] as? [String] ?? []
        let noteFilePaths = data["noteFilePaths"] as? [String] ?? []
        let isArchived = data["isArchived"] as? Bool ?? false
        
        let syncStatusRawValue = data["syncStatus"] as? String ?? ""
        let syncStatus = SyncStatus(rawValue: syncStatusRawValue) ?? .localOnly

        self.init(
            id: subjectId,
            userId: userId,
            name: name,
            colorHex: colorHex,
            notes: notes,
            iconName: iconName,
            targetHoursPerWeek: targetHoursPerWeek,
            totalHoursStudied: totalHoursStudied,
            resourceCount: resourceCount,
            topicCount: topicCount,
            deadlineIds: deadlineIds,
            resourceIds: resourceIds,
            sessionIds: sessionIds,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            noteFilePaths: noteFilePaths
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

