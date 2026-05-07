import Foundation
import FirebaseFirestore

final class StudySessionService {
    static let shared = StudySessionService()
    private let db = Firestore.firestore()
    private init() {}

    private let collection = "studySessions"

    func save(_ session: StudySession) async throws {
        try await db.collection(collection).document(session.id).setData(toFirestore(session))
        CoreDataService.shared.upsertStudySession(session)
    }

    func saveAll(_ sessions: [StudySession]) async throws {
        let batch = db.batch()
        for session in sessions {
            let ref = db.collection(collection).document(session.id)
            batch.setData(toFirestore(session), forDocument: ref)
        }
        try await batch.commit()
        CoreDataService.shared.cacheStudySessions(sessions)
    }

    func fetchAll(userId: String) async throws -> [StudySession] {
        let snap = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        let sessions = snap.documents.compactMap { fromFirestore($0.data(), id: $0.documentID) }
        CoreDataService.shared.cacheStudySessions(sessions)
        return sessions
    }

    func update(_ session: StudySession) async throws {
        try await db.collection(collection).document(session.id).setData(toFirestore(session), merge: true)
        CoreDataService.shared.upsertStudySession(session)
    }

    func delete(id: String) async throws {
        try await db.collection(collection).document(id).delete()
        CoreDataService.shared.deleteStudySession(id: id)
    }

    func deleteAll(ids: [String]) async throws {
        guard !ids.isEmpty else { return }

        let batch = db.batch()
        for id in ids {
            let ref = db.collection(collection).document(id)
            batch.deleteDocument(ref)
        }
        try await batch.commit()
        CoreDataService.shared.deleteStudySessions(ids: ids)
    }

    // MARK: - Conversion helpers

    private func toFirestore(_ s: StudySession) -> [String: Any] {
        var data: [String: Any] = [
            "id":              s.id,
            "userId":          s.userId,
            "subjectId":       s.subjectId,
            "subjectName":     s.subjectName,
            "subjectColorHex": s.subjectColorHex,
            "title":           s.title,
            "topic":           s.topic,
            "scheduledDate":   s.scheduledDate,
            "startTime":       s.startTime,
            "endTime":         s.endTime,
            "status":          s.status.rawValue,
            "sessionType":     s.sessionType.rawValue,
            "hasReminder":     s.hasReminder,
            "resourceIds":     s.resourceIds,
            "topicIds":        s.topicIds,
            "createdAt":       s.createdAt,
            "updatedAt":       s.updatedAt,
            "syncStatus":      s.syncStatus.rawValue
        ]
        if let n  = s.notes                    { data["notes"]                  = n }
        if let d  = s.actualDurationMinutes    { data["actualDurationMinutes"]  = d }
        if let dl = s.linkedDeadlineId         { data["linkedDeadlineId"]       = dl }
        if let pl = s.linkedPlanId             { data["linkedPlanId"]           = pl }
        if let r  = s.rating                   { data["rating"]                 = r }
        if let ec = s.externalCalendarEventId  { data["externalCalendarEventId"] = ec }
        return data
    }

    private func fromFirestore(_ data: [String: Any], id: String) -> StudySession? {
        guard
            let userId          = data["userId"]      as? String,
            let subjectId       = data["subjectId"]   as? String,
            let subjectName     = data["subjectName"] as? String,
            let title           = data["title"]       as? String,
            let startTime       = (data["startTime"]     as? Timestamp)?.dateValue(),
            let endTime         = (data["endTime"]       as? Timestamp)?.dateValue(),
            let scheduledDate   = (data["scheduledDate"] as? Timestamp)?.dateValue()
        else { return nil }

        let statusRaw      = data["status"]      as? String ?? ""
        let sessionTypeRaw = data["sessionType"] as? String ?? ""
        let syncRaw        = data["syncStatus"]  as? String ?? ""

        return StudySession(
            id:                      id,
            userId:                  userId,
            subjectId:               subjectId,
            subjectName:             subjectName,
            subjectColorHex:         data["subjectColorHex"]      as? String ?? "#3B82F6",
            title:                   title,
            topic:                   data["topic"]                as? String ?? "",
            notes:                   data["notes"]                as? String,
            scheduledDate:           scheduledDate,
            startTime:               startTime,
            endTime:                 endTime,
            actualDurationMinutes:   data["actualDurationMinutes"] as? Int,
            status:                  SessionStatus(rawValue: statusRaw)      ?? .scheduled,
            sessionType:             SessionType(rawValue: sessionTypeRaw)   ?? .focused,
            hasReminder:             data["hasReminder"]   as? Bool ?? false,
            linkedDeadlineId:        data["linkedDeadlineId"] as? String,
            linkedPlanId:            data["linkedPlanId"]    as? String,
            resourceIds:             data["resourceIds"]     as? [String] ?? [],
            topicIds:                data["topicIds"]        as? [String] ?? [],
            rating:                  data["rating"]          as? Int,
            externalCalendarEventId: data["externalCalendarEventId"] as? String,
            createdAt:               (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt:               (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            syncStatus:              SyncStatus(rawValue: syncRaw) ?? .synced
        )
    }
}
