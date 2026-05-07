import Foundation
import FirebaseFirestore
import Combine

class ResourceService {
    static let shared = ResourceService()
    private let db = Firestore.firestore()

    private init() {}

    func createResource(_ resource: Resource) async throws {
        var firestoreData: [String: Any] = [
            "id": resource.id,
            "userId": resource.userId,
            "subjectId": resource.subjectId,
            "name": resource.name,
            "resourceType": resource.resourceType.rawValue,
            "size": resource.size,
            "tags": resource.tags,
            "isFavorite": resource.isFavorite,
            "createdAt": resource.createdAt,
            "updatedAt": resource.updatedAt,
            "syncStatus": resource.syncStatus.rawValue
        ]
        
        if let content = resource.content {
            firestoreData["content"] = content
        }
        if let localFilePath = resource.localFilePath {
            firestoreData["localFilePath"] = localFilePath
        }
        if let remoteURL = resource.remoteURL {
            firestoreData["remoteURL"] = remoteURL
        }
        if let fileSize = resource.fileSize {
            firestoreData["fileSize"] = fileSize
        }
        if let mimeType = resource.mimeType {
            firestoreData["mimeType"] = mimeType
        }
        
        let batch = db.batch()
        
        let resourceRef = db.collection("resources").document(resource.id)
        batch.setData(firestoreData, forDocument: resourceRef)
        
        let subjectRef = db.collection("subjects").document(resource.subjectId)
        batch.updateData(["resourceCount": FieldValue.increment(Int64(1))], forDocument: subjectRef)
        
        try await batch.commit()
        
        CoreDataService.shared.upsertResource(resource)
        
        if var subject = CoreDataService.shared.getCachedSubject(id: resource.subjectId) {
            subject.resourceCount += 1
            CoreDataService.shared.upsertSubject(subject)
        }
    }

    func fetchResources(subjectId: String) async throws -> [Resource] {
        let snapshot = try await db.collection("resources").whereField("subjectId", isEqualTo: subjectId).getDocuments()
        let resources = snapshot.documents.compactMap { doc -> Resource? in
            let data = doc.data()
            guard let resourceTypeRaw = data["resourceType"] as? String,
                  let resourceType = ResourceType(rawValue: resourceTypeRaw),
                  let name = data["name"] as? String else {
                return nil
            }
            
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            return Resource(
                id: data["id"] as? String ?? doc.documentID,
                userId: data["userId"] as? String ?? "",
                subjectId: data["subjectId"] as? String ?? subjectId,
                name: name,
                resourceType: resourceType,
                size: data["size"] as? String ?? "",
                content: data["content"] as? String,
                localFilePath: data["localFilePath"] as? String,
                remoteURL: data["remoteURL"] as? String,
                fileSize: data["fileSize"] as? Int,
                mimeType: data["mimeType"] as? String,
                tags: data["tags"] as? [String] ?? [],
                isFavorite: data["isFavorite"] as? Bool ?? false,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: SyncStatus(rawValue: data["syncStatus"] as? String ?? "") ?? .localOnly
            )
        }
        CoreDataService.shared.cacheResources(resources)
        updateCachedSubjectResourceCount(subjectId: subjectId, resources: resources)
        return resources
    }

    private func updateCachedSubjectResourceCount(subjectId: String, resources: [Resource]) {
        guard var subject = CoreDataService.shared.getCachedSubject(id: subjectId) else { return }
        subject.resourceCount = resources.count
        subject.resourceIds = Array(Set(resources.map(\.id)))
        subject.updatedAt = Date()
        CoreDataService.shared.upsertSubject(subject)
    }

    func updateResource(_ resource: Resource) async throws {
        var firestoreData: [String: Any] = [
            "id": resource.id,
            "userId": resource.userId,
            "subjectId": resource.subjectId,
            "name": resource.name,
            "resourceType": resource.resourceType.rawValue,
            "size": resource.size,
            "tags": resource.tags,
            "isFavorite": resource.isFavorite,
            "createdAt": resource.createdAt,
            "updatedAt": resource.updatedAt,
            "syncStatus": resource.syncStatus.rawValue
        ]
        
        if let content = resource.content {
            firestoreData["content"] = content
        }
        if let localFilePath = resource.localFilePath {
            firestoreData["localFilePath"] = localFilePath
        }
        if let remoteURL = resource.remoteURL {
            firestoreData["remoteURL"] = remoteURL
        }
        if let fileSize = resource.fileSize {
            firestoreData["fileSize"] = fileSize
        }
        if let mimeType = resource.mimeType {
            firestoreData["mimeType"] = mimeType
        }
        
        try await db.collection("resources").document(resource.id).setData(firestoreData, merge: true)
        CoreDataService.shared.upsertResource(resource)
    }

    func deleteResource(id: String, subjectId: String) async throws {
        let batch = db.batch()
        
        let resourceRef = db.collection("resources").document(id)
        batch.deleteDocument(resourceRef)
        
        let subjectRef = db.collection("subjects").document(subjectId)
        batch.updateData(["resourceCount": FieldValue.increment(Int64(-1))], forDocument: subjectRef)
        
        try await batch.commit()
        
        CoreDataService.shared.deleteResource(id: id)
        
        if var subject = CoreDataService.shared.getCachedSubject(id: subjectId) {
            subject.resourceCount = max(0, subject.resourceCount - 1)
            CoreDataService.shared.upsertSubject(subject)
        }
    }
}
