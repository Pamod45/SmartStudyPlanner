import Combine
import SwiftUI
import FirebaseFirestore

// Owns the subject list shown outside the workspace.
// It loads cached subjects first, then refreshes Firestore data and derived resource counts.

@MainActor
class SubjectsViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var isLoading: Bool = false

    // Loads subjects for the signed-in user and refreshes resource counts from actual resources.
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
            await refreshResourceCountsFromResources(for: remote)
        } catch {
        }
    }

    // Resource counts are derived from resource documents so the list stays correct
    // even if the stored subject count is stale.
    private func refreshResourceCountsFromResources(for loadedSubjects: [Subject]) async {
        await withTaskGroup(of: (String, Int, [String]).self) { group in
            for subject in loadedSubjects {
                group.addTask {
                    let resources = (try? await ResourceService.shared.fetchResources(subjectId: subject.id)) ?? []
                    return (subject.id, resources.count, resources.map(\.id))
                }
            }

            for await (subjectId, count, resourceIds) in group {
                setResourceCount(count, for: subjectId, resourceIds: resourceIds)
            }
        }
    }

    // Optimistically adds the subject locally, then syncs it to Firestore.
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

    // Updates the UI and local cache immediately, then marks the subject synced after Firestore succeeds.
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
    
    // Pulls the latest count fields from Firestore after related workspace data changes.
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

    // Keeps the subject list and Core Data cache in sync after resources are loaded or changed.
    func setResourceCount(_ count: Int, for subjectId: String, resourceIds: [String]? = nil) {
        guard let idx = subjects.firstIndex(where: { $0.id == subjectId }) else { return }

        var updated = subjects[idx]
        updated.resourceCount = count
        updated.resourceIds = resourceIds ?? Array(Set(CoreDataService.shared.getCachedResources(for: subjectId).map(\.id)))
        updated.updatedAt = Date()
        subjects[idx] = updated
        CoreDataService.shared.upsertSubject(updated)
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
