import Combine

import SwiftUI
import SwiftUI

@MainActor
class SubjectsViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var isLoading: Bool = false

    func load(userId: String?) async {
        isLoading = true
        defer { isLoading = false }
    }

    func addSubject(_ subject: Subject) {
        subjects.append(subject)
    }

    func deleteSubject(id: String) {
        subjects.removeAll { $0.id == id }
    }

    func updateSubject(_ subject: Subject) {
        if let idx = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[idx] = subject
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
