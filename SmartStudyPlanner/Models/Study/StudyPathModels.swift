import Foundation
import FirebaseFirestore

struct StudyPathTopic: Identifiable, Codable {
    var id: String
    var subjectId: String
    var userId: String
    var order: Int
    var title: String
    var description: String
    var subtopics: [String]
    var weightPercent: Int
    var estimatedHours: Int
    var resourceIds: [String]
    var completionPercent: Double
    var isCompleted: Bool
    var generatedAt: Date
    var syncStatus: SyncStatus

    init(
        id: String = UUID().uuidString,
        subjectId: String = "",
        userId: String = "",
        order: Int,
        title: String,
        description: String,
        subtopics: [String] = [],
        weightPercent: Int,
        estimatedHours: Int? = nil,
        resourceIds: [String] = [],
        completionPercent: Double = 0.0,
        isCompleted: Bool = false,
        generatedAt: Date = Date(),
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.subjectId = subjectId
        self.userId = userId
        self.order = order
        self.title = title
        self.description = description
        self.subtopics = subtopics
        self.weightPercent = weightPercent
        self.estimatedHours = estimatedHours ?? max(1, weightPercent / 10)
        self.resourceIds = resourceIds
        self.completionPercent = completionPercent
        self.isCompleted = isCompleted
        self.generatedAt = generatedAt
        self.syncStatus = syncStatus
    }
    
    var firestoreData: [String: Any] {
        let generated = Self.clampDate(generatedAt, fallback: Date())

        return [
            "id": id,
            "subjectId": subjectId,
            "userId": userId,
            "order": order,
            "title": title,
            "description": description,
            "subtopics": subtopics,
            "weightPercent": weightPercent,
            "estimatedHours": estimatedHours,
            "resourceIds": resourceIds,
            "completionPercent": completionPercent,
            "isCompleted": isCompleted,
            "generatedAt": generated,
            "syncStatus": syncStatus.rawValue
        ]
    }

    init?(from data: [String: Any], id: String) {
        let subjectId = data["subjectId"] as? String ?? ""
        let userId = data["userId"] as? String ?? ""
        let order = data["order"] as? Int ?? 0
        let title = data["title"] as? String ?? ""
        let description = data["description"] as? String ?? ""
        let subtopics = data["subtopics"] as? [String] ?? []
        let weightPercent = data["weightPercent"] as? Int ?? 0
        let estimatedHours = data["estimatedHours"] as? Int ?? max(1, weightPercent / 10)
        let resourceIds = data["resourceIds"] as? [String] ?? []
        let completionPercent = data["completionPercent"] as? Double ?? 0.0
        let isCompleted = data["isCompleted"] as? Bool ?? false
        
        let generatedAt: Date
        if let ts = data["generatedAt"] as? FirebaseFirestore.Timestamp {
            generatedAt = Self.clampDate(ts.dateValue(), fallback: Date())
        } else if let d = data["generatedAt"] as? Date {
            generatedAt = Self.clampDate(d, fallback: Date())
        } else {
            generatedAt = Self.clampDate(Date(), fallback: Date())
        }
        
        let syncStatusRawValue = data["syncStatus"] as? String ?? ""
        let syncStatus = SyncStatus(rawValue: syncStatusRawValue) ?? .localOnly

        self.init(
            id: id,
            subjectId: subjectId,
            userId: userId,
            order: order,
            title: title,
            description: description,
            subtopics: subtopics,
            weightPercent: weightPercent,
            estimatedHours: estimatedHours,
            resourceIds: resourceIds,
            completionPercent: completionPercent,
            isCompleted: isCompleted,
            generatedAt: generatedAt,
            syncStatus: syncStatus
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
