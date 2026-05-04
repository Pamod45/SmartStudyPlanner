
import Foundation
import FirebaseFirestore

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
        
        try await db.collection("resources").document(resource.id).setData(firestoreData)
        CoreDataService.shared.upsertResource(resource)
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
        return resources
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

    func deleteResource(id: String) async throws {
        try await db.collection("resources").document(id).delete()
        CoreDataService.shared.deleteResource(id: id)
    }
}
