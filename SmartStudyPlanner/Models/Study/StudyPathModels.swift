 import Foundation

struct StudyPathTopic: Identifiable, Codable {
    var id: String
    var order: Int
    var title: String
    var description: String
    var subtopics: [String]
    var weightPercent: Int
    var resourceIds: [String]
    var completionPercent: Int
    var isCompleted: Bool

    init(
        id: String = UUID().uuidString,
        order: Int,
        title: String,
        description: String,
        subtopics: [String] = [],
        weightPercent: Int,
        resourceIds: [String] = [],
        completionPercent: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.description = description
        self.subtopics = subtopics
        self.weightPercent = weightPercent
        self.resourceIds = resourceIds
        self.completionPercent = completionPercent
        self.isCompleted = isCompleted
    }
}

struct PathMilestone: Identifiable, Codable {
    var id: String
    var title: String
    var description: String?
    var targetDate: Date
    var completedDate: Date?
    var isCompleted: Bool
    var linkedSessionIds: [String]
    var linkedDeadlineId: String?
    var order: Int

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        targetDate: Date,
        completedDate: Date? = nil,
        isCompleted: Bool = false,
        linkedSessionIds: [String] = [],
        linkedDeadlineId: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.completedDate = completedDate
        self.isCompleted = isCompleted
        self.linkedSessionIds = linkedSessionIds
        self.linkedDeadlineId = linkedDeadlineId
        self.order = order
    }
}

struct StudyPath: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var subjectId: String
    var title: String
    var description: String?
    var topics: [StudyPathTopic]
    var milestones: [PathMilestone]
    var generatedFromResourceIds: [String]
    var estimatedCompletionDate: Date?
    var actualCompletionDate: Date?
    var status: PlanStatus
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        subjectId: String,
        title: String = "Study Path",
        description: String? = nil,
        topics: [StudyPathTopic] = [],
        milestones: [PathMilestone] = [],
        generatedFromResourceIds: [String] = [],
        estimatedCompletionDate: Date? = nil,
        actualCompletionDate: Date? = nil,
        status: PlanStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.subjectId = subjectId
        self.title = title
        self.description = description
        self.topics = topics
        self.milestones = milestones
        self.generatedFromResourceIds = generatedFromResourceIds
        self.estimatedCompletionDate = estimatedCompletionDate
        self.actualCompletionDate = actualCompletionDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
