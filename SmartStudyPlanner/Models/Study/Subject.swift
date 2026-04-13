import SwiftUI

struct Subject: Identifiable, Hashable, Codable, Syncable {
    var id: String
    var userId: String
    var name: String
    var colorHex: String
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

    var color: Color {
        Color(hex: colorHex)
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        name: String,
        colorHex: String = "#3B82F6",
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
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.targetHoursPerWeek = targetHoursPerWeek
        self.totalHoursStudied = totalHoursStudied
        self.resourceCount = resourceCount
        self.topicCount = topicCount
        self.deadlineIds = deadlineIds
        self.resourceIds = resourceIds
        self.sessionIds = sessionIds
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
