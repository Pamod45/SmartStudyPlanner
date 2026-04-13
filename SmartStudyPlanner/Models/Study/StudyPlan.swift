import SwiftUI

enum PlanType: String, Codable {
    case deadline
    case habit
    case custom
}

enum PlanStatus: String, Codable {
    case active
    case completed
    case paused
    case cancelled
}

struct StudyPlan: Identifiable, Codable, Syncable {
    var id: String
    var userId: String
    var title: String
    var subjectId: String
    var sessionIds: [String]
    var availabilitySlotIds: [String]
    var startDate: Date
    var endDate: Date
    var targetHours: Double
    var completedHours: Double
    var planType: PlanType
    var status: PlanStatus
    var isAIGenerated: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    var progressPercentage: Double {
        guard targetHours > 0 else { return 0 }
        return min((completedHours / targetHours) * 100, 100)
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        title: String,
        subjectId: String = "",
        sessionIds: [String] = [],
        availabilitySlotIds: [String] = [],
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
        targetHours: Double = 0,
        completedHours: Double = 0,
        planType: PlanType = .custom,
        status: PlanStatus = .active,
        isAIGenerated: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.subjectId = subjectId
        self.sessionIds = sessionIds
        self.availabilitySlotIds = availabilitySlotIds
        self.startDate = startDate
        self.endDate = endDate
        self.targetHours = targetHours
        self.completedHours = completedHours
        self.planType = planType
        self.status = status
        self.isAIGenerated = isAIGenerated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
