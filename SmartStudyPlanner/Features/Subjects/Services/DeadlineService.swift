import Foundation
import FirebaseFirestore

// Manages deadlines for subject workspaces and dashboard summaries.
// Deadline changes are mirrored in Core Data and can schedule/cancel local notifications.

class DeadlineService {
    static let shared = DeadlineService()
    private let db = Firestore.firestore()

    private init() {}

    // Creates a deadline, links it to the subject, updates the local cache, and schedules its alert.
    func createDeadline(_ deadline: Deadline) async throws {
        var data: [String: Any] = [
            "id": deadline.id,
            "userId": deadline.userId,
            "subjectId": deadline.subjectId,
            "subjectColorHex": deadline.subjectColorHex,
            "name": deadline.name,
            "dueDate": deadline.dueDate,
            "hasReminder": deadline.hasReminder,
            "isHighPriority": deadline.isHighPriority,
            "notes": deadline.notes,
            "tag": deadline.tag.rawValue,
            "priority": deadline.priority.rawValue,
            "status": deadline.status.rawValue,
            "linkedSessionIds": deadline.linkedSessionIds,
            "createdAt": deadline.createdAt,
            "updatedAt": deadline.updatedAt,
            "syncStatus": SyncStatus.synced.rawValue
        ]
        if let reminderDate = deadline.reminderDate { data["reminderDate"] = reminderDate }
        if let notificationId = deadline.notificationId { data["notificationId"] = notificationId }

        let batch = db.batch()
        batch.setData(data, forDocument: db.collection("deadlines").document(deadline.id))
        batch.updateData(
            ["deadlineIds": FieldValue.arrayUnion([deadline.id])],
            forDocument: db.collection("subjects").document(deadline.subjectId)
        )
        try await batch.commit()

        var synced = deadline
        synced.syncStatus = .synced
        CoreDataService.shared.upsertDeadline(synced)

        if var subject = CoreDataService.shared.getCachedSubject(id: deadline.subjectId) {
            if !subject.deadlineIds.contains(deadline.id) {
                subject.deadlineIds.append(deadline.id)
                subject.updatedAt = Date()
                CoreDataService.shared.upsertSubject(subject)
            }
        }

        let settings = CoreDataService.shared.getCachedSettings(for: deadline.userId) ?? .default
        NotificationService.shared.scheduleDeadlineAlert(deadline: synced, settings: settings)
    }

    // Loads deadlines for one subject and refreshes the local cache.
    func fetchDeadlines(subjectId: String) async throws -> [Deadline] {
        let snapshot = try await db.collection("deadlines")
            .whereField("subjectId", isEqualTo: subjectId)
            .getDocuments()

        let deadlines: [Deadline] = snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let name = data["name"] as? String,
                  let tag = DeadlineTag(rawValue: data["tag"] as? String ?? "") else { return nil }

            return Deadline(
                id: data["id"] as? String ?? doc.documentID,
                userId: data["userId"] as? String ?? "",
                subjectId: data["subjectId"] as? String ?? subjectId,
                subjectColorHex: data["subjectColorHex"] as? String ?? "#3B82F6",
                name: name,
                dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
                hasReminder: data["hasReminder"] as? Bool ?? false,
                isHighPriority: data["isHighPriority"] as? Bool ?? false,
                notes: data["notes"] as? String ?? "",
                tag: tag,
                priority: DeadlinePriority(rawValue: data["priority"] as? String ?? "") ?? .medium,
                status: DeadlineStatus(rawValue: data["status"] as? String ?? "") ?? .upcoming,
                reminderDate: (data["reminderDate"] as? Timestamp)?.dateValue(),
                linkedSessionIds: data["linkedSessionIds"] as? [String] ?? [],
                notificationId: data["notificationId"] as? String,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                syncStatus: .synced
            )
        }

        CoreDataService.shared.cacheDeadlines(deadlines)
        return deadlines
    }

    // Updates deadline fields and reschedules the deadline alert using the latest settings.
    func updateDeadline(_ deadline: Deadline) async throws {
        var data: [String: Any] = [
            "id": deadline.id,
            "userId": deadline.userId,
            "subjectId": deadline.subjectId,
            "subjectColorHex": deadline.subjectColorHex,
            "name": deadline.name,
            "dueDate": deadline.dueDate,
            "hasReminder": deadline.hasReminder,
            "isHighPriority": deadline.isHighPriority,
            "notes": deadline.notes,
            "tag": deadline.tag.rawValue,
            "priority": deadline.priority.rawValue,
            "status": deadline.status.rawValue,
            "linkedSessionIds": deadline.linkedSessionIds,
            "updatedAt": Date(),
            "syncStatus": SyncStatus.synced.rawValue
        ]
        if let reminderDate = deadline.reminderDate { data["reminderDate"] = reminderDate }
        if let notificationId = deadline.notificationId { data["notificationId"] = notificationId }

        try await db.collection("deadlines").document(deadline.id).setData(data, merge: true)

        var synced = deadline
        synced.syncStatus = .synced
        CoreDataService.shared.upsertDeadline(synced)

        let settings = CoreDataService.shared.getCachedSettings(for: deadline.userId) ?? .default
        NotificationService.shared.scheduleDeadlineAlert(deadline: synced, settings: settings)
    }

    // Loads all user deadlines for dashboard/progress views and refreshes the local cache.
    func fetchAllDeadlines(userId: String) async throws -> [Deadline] {
        let snapshot = try await db.collection("deadlines")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let deadlines: [Deadline] = snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let name = data["name"] as? String,
                  let tag = DeadlineTag(rawValue: data["tag"] as? String ?? "") else { return nil }

            return Deadline(
                id: data["id"] as? String ?? doc.documentID,
                userId: data["userId"] as? String ?? userId,
                subjectId: data["subjectId"] as? String ?? "",
                subjectColorHex: data["subjectColorHex"] as? String ?? "#3B82F6",
                name: name,
                dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
                hasReminder: data["hasReminder"] as? Bool ?? false,
                isHighPriority: data["isHighPriority"] as? Bool ?? false,
                notes: data["notes"] as? String ?? "",
                tag: tag,
                priority: DeadlinePriority(rawValue: data["priority"] as? String ?? "") ?? .medium,
                status: DeadlineStatus(rawValue: data["status"] as? String ?? "") ?? .upcoming,
                reminderDate: (data["reminderDate"] as? Timestamp)?.dateValue(),
                linkedSessionIds: data["linkedSessionIds"] as? [String] ?? [],
                notificationId: data["notificationId"] as? String,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                syncStatus: .synced
            )
        }

        CoreDataService.shared.cacheDeadlines(deadlines)
        return deadlines
    }

    // Removes a deadline, unlinks it from the subject, clears cache, and cancels its notification.
    func deleteDeadline(id: String, subjectId: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection("deadlines").document(id))
        batch.updateData(
            ["deadlineIds": FieldValue.arrayRemove([id])],
            forDocument: db.collection("subjects").document(subjectId)
        )
        try await batch.commit()

        CoreDataService.shared.deleteDeadline(id: id)

        if var subject = CoreDataService.shared.getCachedSubject(id: subjectId) {
            subject.deadlineIds.removeAll { $0 == id }
            subject.updatedAt = Date()
            CoreDataService.shared.upsertSubject(subject)
        }

        NotificationService.shared.cancelNotification(id: "deadline-\(id)")
    }
}
