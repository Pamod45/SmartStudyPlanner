import Foundation
import FirebaseFirestore
import Combine

final class AvailabilitySlotService {
    static let shared = AvailabilitySlotService()
    private let db = Firestore.firestore()
    private init() {}

    private let collection = "availabilitySlots"

    func save(_ slot: AvailabilitySlot) async throws {
        try await db.collection(collection).document(slot.id).setData(toFirestore(slot))
        CoreDataService.shared.upsertAvailabilitySlot(slot)
    }

    func fetchAll(userId: String) async throws -> [AvailabilitySlot] {
        let snap = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        let slots = snap.documents.compactMap { fromFirestore($0.data(), id: $0.documentID) }
        CoreDataService.shared.cacheAvailabilitySlots(slots)
        return slots
    }

    func delete(id: String) async throws {
        try await db.collection(collection).document(id).delete()
        CoreDataService.shared.deleteAvailabilitySlot(id: id)
    }

    private func toFirestore(_ slot: AvailabilitySlot) -> [String: Any] {
        var data: [String: Any] = [
            "id":         slot.id,
            "userId":     slot.userId,
            "type":       slot.type.rawValue,
            "startTime":  slot.startTime,
            "endTime":    slot.endTime,
            "createdAt":  slot.createdAt,
            "updatedAt":  slot.updatedAt,
            "syncStatus": slot.syncStatus.rawValue
        ]
        if let d  = slot.date       { data["date"]       = d }
        if let rs = slot.rangeStart { data["rangeStart"] = rs }
        if let re = slot.rangeEnd   { data["rangeEnd"]   = re }
        if let lb = slot.label      { data["label"]      = lb }
        return data
    }

    private func fromFirestore(_ data: [String: Any], id: String) -> AvailabilitySlot? {
        guard
            let userId    = data["userId"] as? String,
            let typeRaw   = data["type"] as? String,
            let type      = AvailabilityType(rawValue: typeRaw),
            let startTime = (data["startTime"] as? Timestamp)?.dateValue(),
            let endTime   = (data["endTime"]   as? Timestamp)?.dateValue()
        else { return nil }

        let date       = (data["date"]       as? Timestamp)?.dateValue()
        let rangeStart = (data["rangeStart"] as? Timestamp)?.dateValue()
        let rangeEnd   = (data["rangeEnd"]   as? Timestamp)?.dateValue()
        let label      = data["label"]      as? String
        let createdAt  = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt  = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let syncRaw    = data["syncStatus"] as? String ?? ""

        return AvailabilitySlot(
            id:         id,
            userId:     userId,
            type:       type,
            startTime:  startTime,
            endTime:    endTime,
            date:       date,
            rangeStart: rangeStart,
            rangeEnd:   rangeEnd,
            label:      label,
            createdAt:  createdAt,
            updatedAt:  updatedAt,
            syncStatus: SyncStatus(rawValue: syncRaw) ?? .synced
        )
    }
}
