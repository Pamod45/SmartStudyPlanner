import Foundation
import FirebaseFirestore

// Saves and loads generated study path topics for a subject.
// The cloud copy lives under the subject document, while Core Data keeps the local cache.

class StudyPathService {
    static let shared = StudyPathService()
    private let db = Firestore.firestore()
    private init() {}

    private func collection(for subjectId: String) -> CollectionReference {
        db.collection("subjects").document(subjectId).collection("studyPath")
    }

    // Replaces the subject's existing generated path with the new topics and updates topicCount.
    func saveStudyPath(_ topics: [StudyPathTopic], for subjectId: String) async throws {
        print("[StudyPathService] Saving \(topics.count) topic(s) for subject \(subjectId)")
        topics.forEach { topic in
            print("[StudyPathService] Topic -> order=\(topic.order), title=\(topic.title), weight=\(topic.weightPercent), subtopics=\(topic.subtopics.count)")
        }

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

    // Uses cached topics first for fast workspace loading, then falls back to Firestore.
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
        

        return topics
    }
    
    func updateTopic(_ topic: StudyPathTopic) async throws {
        try await collection(for: topic.subjectId)
            .document(topic.id)
            .setData(topic.firestoreData, merge: true)

        CoreDataService.shared.upsertStudyPathTopic(topic)
    }

    // Removes all generated topics for a subject and resets the subject topic count.
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
        
        if var subject = CoreDataService.shared.getCachedSubject(id: subjectId) {
            subject.topicCount = 0
            CoreDataService.shared.upsertSubject(subject)
        }
    }
}
