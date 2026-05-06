import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
class SubjectsViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var isLoading: Bool = false

    func load(userId: String?) async {
        guard let userId = userId else { return }
        isLoading = true
        defer { isLoading = false }

        let cached = CoreDataService.shared.getCachedSubjects(for: userId)
        if !cached.isEmpty {
            subjects = cached
        }

        do {
            let remote = try await SubjectService.shared.fetchSubjects(userId: userId)
            subjects = remote
        } catch {
        }
    }

    func addSubject(_ subject: Subject, userId: String?) {
        guard let userId = userId else { return }
        var newSubject = subject
        newSubject.userId = userId
        newSubject.updatedAt = Date()
        newSubject.syncStatus = .pendingUpdate
        subjects.append(newSubject)
        CoreDataService.shared.upsertSubject(newSubject)

        Task {
            do {
                try await SubjectService.shared.createSubject(newSubject)
                await MainActor.run {
                    self.updateSubject(newSubject, syncStatus: .synced)
                }
            } catch {
            }
        }
    }

    func deleteSubject(id: String) {
        subjects.removeAll { $0.id == id }
        CoreDataService.shared.deleteSubject(id: id)
        Task {
            try? await SubjectService.shared.deleteSubject(id: id)
        }
    }

    func updateSubject(_ subject: Subject) {
        updateSubject(subject, syncStatus: .pendingUpdate)
        Task {
            do {
                try await SubjectService.shared.updateSubject(subject)
                await MainActor.run {
                    self.updateSubject(subject, syncStatus: .synced)
                }
            } catch {
            }
        }
    }

    private func updateSubject(_ subject: Subject, syncStatus: SyncStatus) {
        if let idx = subjects.firstIndex(where: { $0.id == subject.id }) {
            var updated = subject
            updated.updatedAt = Date()
            updated.syncStatus = syncStatus
            subjects[idx] = updated
            CoreDataService.shared.upsertSubject(updated)
        }
    }
    
    func refreshSubjectCounts(for subjectId: String) {
        Task {
            do {
                let snapshot = try await Firestore.firestore()
                    .collection("subjects")
                    .document(subjectId)
                    .getDocument()
                
                if let data = snapshot.data(),
                   let updatedSubject = Subject(from: data, id: snapshot.documentID) {
                    await MainActor.run {
                        if let idx = subjects.firstIndex(where: { $0.id == subjectId }) {
                            subjects[idx] = updatedSubject
                            CoreDataService.shared.upsertSubject(updatedSubject)
                        }
                    }
                }
            } catch {
                print("Failed to refresh subject counts: \(error)")
            }
        }
    }

    func topics(for subject: Subject) -> [StudyTopic] {
        return []
    }

    func resources(for subject: Subject) -> [Resource] {
        return []
    }

    func deadlines(for subject: Subject) -> [Deadline] {
        return []
    }

    func quizAttempts(for subject: Subject) -> [QuizAttempt] {
        return []
    }
}

