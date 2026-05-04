import Foundation
import FirebaseFirestore

class SubjectService {
    static let shared = SubjectService()
    private let db = Firestore.firestore()

    private init() {}

    func createSubject(_ subject: Subject) async throws {
        try await db.collection("subjects").document(subject.id).setData(subject.firestoreData)
        CoreDataService.shared.upsertSubject(subject)
    }

    func fetchSubjects(userId: String) async throws -> [Subject] {
        let snapshot = try await db.collection("subjects").whereField("userId", isEqualTo: userId).getDocuments()
        let subjects = snapshot.documents.compactMap { doc in
            Subject(from: doc.data(), id: doc.documentID)
        }
        CoreDataService.shared.cacheSubjects(subjects)
        return subjects
    }

    func updateSubject(_ subject: Subject) async throws {
        try await db.collection("subjects").document(subject.id).setData(subject.firestoreData, merge: true)
        CoreDataService.shared.upsertSubject(subject)
    }

    func deleteSubject(id: String) async throws {
        try await db.collection("subjects").document(id).delete()
        CoreDataService.shared.deleteSubject(id: id)
    }
    
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
