import Foundation
import FirebaseFirestore

class StudyPathService {
    static let shared = StudyPathService()
    private let db = Firestore.firestore()
    private init() {}

    private func collection(for subjectId: String) -> CollectionReference {
        db.collection("subjects").document(subjectId).collection("studyPath")
    }

    func saveStudyPath(_ topics: [StudyPathTopic], for subjectId: String) async throws {
        let batch = db.batch()
        
        let subjectRef = db.collection("subjects").document(subjectId)
        batch.updateData(["topicCount": topics.count], forDocument: subjectRef)

        let pathRef = db.collection("subjects").document(subjectId).collection("studyPath")
        let existing = try await pathRef.getDocuments()
        for doc in existing.documents {
            batch.deleteDocument(doc.reference)
        }

        for topic in topics {
            let userTopic = topic
            let topicRef = pathRef.document(userTopic.id)
            batch.setData(userTopic.firestoreData, forDocument: topicRef)
        }

        try await batch.commit()

        CoreDataService.shared.deleteStudyPath(for: subjectId)
        CoreDataService.shared.cacheStudyPath(topics)

        if var subject = CoreDataService.shared.getCachedSubject(id: subjectId) {
            subject.topicCount = topics.count
            CoreDataService.shared.upsertSubject(subject)
        }

        print("[StudyPathService] Saved \(topics.count) topics for subject \(subjectId)")
    }

    func fetchStudyPath(for subjectId: String) async throws -> [StudyPathTopic] {
        let cached = CoreDataService.shared.getCachedStudyPath(for: subjectId)
        if !cached.isEmpty {
            print("[StudyPathService] Loaded \(cached.count) topics from cache")
            return cached.sorted { $0.order < $1.order }
        }
        let snapshot = try await collection(for: subjectId).getDocuments()
        let topics = snapshot.documents.compactMap { doc in
            StudyPathTopic(from: doc.data(), id: doc.documentID)
        }.sorted { $0.order < $1.order }

        CoreDataService.shared.deleteStudyPath(for: subjectId)
        CoreDataService.shared.cacheStudyPath(topics)

        print("[StudyPathService] Fetched \(topics.count) topics from Firestore")
        return topics
    }
    
    func updateTopic(_ topic: StudyPathTopic) async throws {
        try await collection(for: topic.subjectId)
            .document(topic.id)
            .setData(topic.firestoreData, merge: true)

        CoreDataService.shared.upsertStudyPathTopic(topic)
    }

    func deleteStudyPath(for subjectId: String) async throws {
        let ref = collection(for: subjectId)
        let docs = try await ref.getDocuments()
        for doc in docs.documents {
            try await doc.reference.delete()
        }
        
        let batch = db.batch()
        let subjectRef = db.collection("subjects").document(subjectId)
        batch.updateData(["topicCount": 0], forDocument: subjectRef)
        try await batch.commit()

        CoreDataService.shared.deleteStudyPath(for: subjectId)
        
        // Update local subject topicCount
        if var subject = CoreDataService.shared.getCachedSubject(id: subjectId) {
            subject.topicCount = 0
            CoreDataService.shared.upsertSubject(subject)
        }
    }
}
