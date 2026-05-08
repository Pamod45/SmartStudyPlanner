import Foundation

struct StudyTopic: Identifiable, Equatable, Codable, Syncable {
    var id: String
    var userId: String
    var subjectId: String
    var name: String
    var notes: String?
    var resourceCount: Int
    var estimatedHours: Int
    var isCompleted: Bool
    var completedAt: Date?
    var linkedSessionIds: [String]
    var order: Int
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        subjectId: String = "",
        name: String,
        notes: String? = nil,
        resourceCount: Int = 0,
        estimatedHours: Int = 1,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        linkedSessionIds: [String] = [],
        order: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.subjectId = subjectId
        self.name = name
        self.notes = notes
        self.resourceCount = resourceCount
        self.estimatedHours = estimatedHours
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.linkedSessionIds = linkedSessionIds
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
