import Foundation
import FirebaseFirestore

// Handles subject profile data in Firestore and keeps the local Core Data cache aligned.

class SubjectService {
    static let shared = SubjectService()
    private let db = Firestore.firestore()

    private init() {}

    // Creates a subject remotely, then stores the same subject locally for offline/fast loading.
    func createSubject(_ subject: Subject) async throws {
        try await db.collection("subjects").document(subject.id).setData(subject.firestoreData)
        CoreDataService.shared.upsertSubject(subject)
    }

    // Loads all subjects for a user and refreshes the local subject cache.
    func fetchSubjects(userId: String) async throws -> [Subject] {
        let snapshot = try await db.collection("subjects").whereField("userId", isEqualTo: userId).getDocuments()
        let subjects = snapshot.documents.compactMap { doc in
            Subject(from: doc.data(), id: doc.documentID)
        }
        CoreDataService.shared.cacheSubjects(subjects)
        return subjects
    }

    // Updates the cloud copy and local cache with the latest subject fields/counts.
    func updateSubject(_ subject: Subject) async throws {
        try await db.collection("subjects").document(subject.id).setData(subject.firestoreData, merge: true)
        CoreDataService.shared.upsertSubject(subject)
    }

    func deleteSubject(id: String) async throws {
        try await db.collection("subjects").document(id).delete()
        CoreDataService.shared.deleteSubject(id: id)
    }
    
    // Keeps locally saved note files linked to the subject without adding duplicates.
    func addNoteFilePath(to subject: Subject, filePath: String) async throws {
        var updatedSubject = subject
        if !updatedSubject.noteFilePaths.contains(filePath) {
            updatedSubject.noteFilePaths.append(filePath)
            updatedSubject.updatedAt = Date()
            try await updateSubject(updatedSubject)
        }
    }
    
    func removeNoteFilePath(from subject: Subject, filePath: String) async throws {
        var updatedSubject = subject
        updatedSubject.noteFilePaths.removeAll { $0 == filePath }
        updatedSubject.updatedAt = Date()
        try await updateSubject(updatedSubject)
    }
}
