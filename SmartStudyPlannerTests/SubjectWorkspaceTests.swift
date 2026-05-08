import XCTest
import FirebaseAuth
import FirebaseCore
@testable import SmartStudyPlanner

final class SubjectWorkspaceTests: XCTestCase {
    private var createdSubjectIds: [String] = []
    private var createdResourceIds: [(id: String, subjectId: String)] = []
    private var createdDeadlineIds: [(id: String, subjectId: String)] = []
    private var createdAttemptIds: [String] = []

    override func setUp() {
        super.setUp()
        configureFirebaseIfNeeded()
    }

    override func tearDown() {
        try? AuthService.shared.signOut()
        createdSubjectIds.removeAll()
        createdResourceIds.removeAll()
        createdDeadlineIds.removeAll()
        createdAttemptIds.removeAll()
        super.tearDown()
    }

    func testResourceCreateFetchDeleteUpdatesSubjectCache() async throws {
        let subject = try await createTemporarySubject()
        let resource = Resource(
            id: "test-resource-\(UUID().uuidString)",
            userId: subject.userId,
            subjectId: subject.id,
            name: "Workspace Resource Test",
            resourceType: .note,
            size: "1 KB",
            content: "Resource content for workspace testing.",
            tags: ["unit-test"]
        )
        createdResourceIds.append((resource.id, subject.id))

        do {
            try await ResourceService.shared.createResource(resource)
            let fetched = try await ResourceService.shared.fetchResources(subjectId: subject.id)
            let cached = CoreDataService.shared.getCachedResources(for: subject.id)
            let cachedSubject = CoreDataService.shared.getCachedSubject(id: subject.id)

            XCTAssertTrue(fetched.contains { $0.id == resource.id })
            XCTAssertTrue(cached.contains { $0.id == resource.id })
            XCTAssertEqual(cachedSubject?.resourceCount, fetched.count)
            XCTAssertTrue(cachedSubject?.resourceIds.contains(resource.id) ?? false)

            try await ResourceService.shared.deleteResource(id: resource.id, subjectId: subject.id)
            createdResourceIds.removeAll { $0.id == resource.id }

            let afterDelete = try await ResourceService.shared.fetchResources(subjectId: subject.id)
            XCTAssertFalse(afterDelete.contains { $0.id == resource.id })
        } catch {
            try? await cleanupTemporaryData()
            throw error
        }

        try await cleanupTemporaryData()
    }

    func testDeadlineCreateFetchDeleteUpdatesSubject() async throws {
        let subject = try await createTemporarySubject()
        let deadline = Deadline(
            id: "test-deadline-\(UUID().uuidString)",
            userId: subject.userId,
            subjectId: subject.id,
            subjectColorHex: subject.colorHex,
            name: "Workspace Deadline Test",
            dueDate: Date().addingTimeInterval(86_400),
            hasReminder: false,
            notes: "Created by tests",
            tag: .submission
        )
        createdDeadlineIds.append((deadline.id, subject.id))

        do {
            try await DeadlineService.shared.createDeadline(deadline)
            let fetched = try await DeadlineService.shared.fetchDeadlines(subjectId: subject.id)
            let cached = CoreDataService.shared.getCachedDeadlines(for: subject.id)
            let cachedSubject = CoreDataService.shared.getCachedSubject(id: subject.id)

            XCTAssertTrue(fetched.contains { $0.id == deadline.id })
            XCTAssertTrue(cached.contains { $0.id == deadline.id })
            XCTAssertTrue(cachedSubject?.deadlineIds.contains(deadline.id) ?? false)

            try await DeadlineService.shared.deleteDeadline(id: deadline.id, subjectId: subject.id)
            createdDeadlineIds.removeAll { $0.id == deadline.id }

            let afterDelete = try await DeadlineService.shared.fetchDeadlines(subjectId: subject.id)
            XCTAssertFalse(afterDelete.contains { $0.id == deadline.id })
        } catch {
            try? await cleanupTemporaryData()
            throw error
        }

        try await cleanupTemporaryData()
    }

    func testStudyPathSaveFetchDeletePreservesOrderAndTopicCount() async throws {
        let subject = try await createTemporarySubject()
        let topics = [
            StudyPathTopic(
                id: "topic-2-\(UUID().uuidString)",
                subjectId: subject.id,
                userId: subject.userId,
                order: 2,
                title: "Second Topic",
                description: "Second generated topic",
                weightPercent: 30,
                estimatedMinutes: 45
            ),
            StudyPathTopic(
                id: "topic-1-\(UUID().uuidString)",
                subjectId: subject.id,
                userId: subject.userId,
                order: 1,
                title: "First Topic",
                description: "First generated topic",
                weightPercent: 70,
                estimatedMinutes: 90
            )
        ]

        do {
            try await StudyPathService.shared.saveStudyPath(topics, for: subject.id)

            let fetched = try await StudyPathService.shared.fetchStudyPath(for: subject.id)
            let cachedSubject = CoreDataService.shared.getCachedSubject(id: subject.id)

            XCTAssertEqual(fetched.map(\.order), [1, 2])
            XCTAssertEqual(fetched.map(\.title), ["First Topic", "Second Topic"])
            XCTAssertEqual(cachedSubject?.topicCount, 2)

            try await StudyPathService.shared.deleteStudyPath(for: subject.id)
            let afterDelete = CoreDataService.shared.getCachedStudyPath(for: subject.id)
            let subjectAfterDelete = CoreDataService.shared.getCachedSubject(id: subject.id)

            XCTAssertTrue(afterDelete.isEmpty)
            XCTAssertEqual(subjectAfterDelete?.topicCount, 0)
        } catch {
            try? await cleanupTemporaryData()
            throw error
        }

        try await cleanupTemporaryData()
    }

    func testQuizAttemptSaveFetchDeletePreservesQuestionsAndScore() async throws {
        let subject = try await createTemporarySubject()
        let firstQuestion = QuizQuestion(
            id: "q1-\(UUID().uuidString)",
            number: 1,
            category: "Workspace",
            questionText: "What is tested?",
            options: ["Layout", "Persistence", "Theme"],
            correctOptionIndex: 1,
            points: 5
        )
        let secondQuestion = QuizQuestion(
            id: "q2-\(UUID().uuidString)",
            number: 2,
            category: "Workspace",
            questionText: "Which layer caches data?",
            options: ["Core Data", "Preview", "Button"],
            correctOptionIndex: 0,
            points: 5
        )
        let attempt = QuizAttempt(
            id: "test-attempt-\(UUID().uuidString)",
            userId: subject.userId,
            quizName: "Workspace Quiz Test",
            topicName: "Workspace Topic",
            subjectId: subject.id,
            questions: [firstQuestion, secondQuestion],
            selectedAnswers: [
                firstQuestion.id: 1,
                secondQuestion.id: 2
            ],
            timeSpentSeconds: 95
        )
        createdAttemptIds.append(attempt.id)

        do {
            try await QuizService.shared.saveAttempt(attempt, userId: subject.userId)

            let fetched = try await QuizService.shared.fetchAttempts(subjectId: subject.id)
            let savedAttempt = try XCTUnwrap(fetched.first { $0.id == attempt.id })

            XCTAssertEqual(savedAttempt.questions.count, 2)
            XCTAssertEqual(savedAttempt.selectedAnswers[firstQuestion.id], 1)
            XCTAssertEqual(savedAttempt.correctCount, 1)
            XCTAssertEqual(savedAttempt.scorePercent, 50)

            try await QuizService.shared.deleteAttempt(id: attempt.id)
            createdAttemptIds.removeAll { $0 == attempt.id }

            let afterDelete = try await QuizService.shared.fetchAttempts(subjectId: subject.id)
            XCTAssertFalse(afterDelete.contains { $0.id == attempt.id })
        } catch {
            try? await cleanupTemporaryData()
            throw error
        }

        try await cleanupTemporaryData()
    }

    func testQuizAttemptHandlesEmptyAndPartialAnswers() {
        let emptyAttempt = QuizAttempt(
            quizName: "Empty Quiz",
            topicName: "No Topic",
            questions: [],
            selectedAnswers: [:],
            timeSpentSeconds: 0
        )

        XCTAssertEqual(emptyAttempt.scorePercent, 0)
        XCTAssertEqual(emptyAttempt.correctCount, 0)

        let firstQuestion = QuizQuestion(number: 1, category: "Math", questionText: "1+1?", options: ["1", "2"], correctOptionIndex: 1)
        let secondQuestion = QuizQuestion(number: 2, category: "Math", questionText: "2+2?", options: ["3", "4"], correctOptionIndex: 1)
        let partialAttempt = QuizAttempt(
            quizName: "Partial Quiz",
            topicName: "Math",
            questions: [firstQuestion, secondQuestion],
            selectedAnswers: [firstQuestion.id: 1],
            timeSpentSeconds: 125
        )

        XCTAssertEqual(partialAttempt.correctCount, 1)
        XCTAssertEqual(partialAttempt.scorePercent, 50)
        XCTAssertEqual(partialAttempt.timeSpentFormatted, "02:05")
        XCTAssertEqual(partialAttempt.durationFormatted, "2m 05s")
    }

    func testSubjectAndStudyPathMappingHandlesCountsAndResourceIds() {
        let subject = Subject(
            id: "subject-map-test",
            userId: "user-map-test",
            name: "Mapping Subject",
            resourceCount: 2,
            topicCount: 3,
            deadlineIds: ["deadline-1"],
            resourceIds: ["resource-1", "resource-2"]
        )

        let subjectData = subject.firestoreData
        let restoredSubject = Subject(from: subjectData, id: subject.id)

        XCTAssertEqual(restoredSubject?.resourceCount, 2)
        XCTAssertEqual(restoredSubject?.topicCount, 3)
        XCTAssertEqual(restoredSubject?.deadlineIds, ["deadline-1"])
        XCTAssertEqual(restoredSubject?.resourceIds, ["resource-1", "resource-2"])

        let topic = StudyPathTopic(
            id: "topic-map-test",
            subjectId: subject.id,
            userId: subject.userId,
            order: 1,
            title: "Mapping Topic",
            description: "Topic mapping",
            weightPercent: 20,
            estimatedMinutes: 40,
            difficultyLevel: 20,
            resourceIds: ["resource-1"]
        )

        let topicData = topic.firestoreData
        let restoredTopic = StudyPathTopic(from: topicData, id: topic.id)

        XCTAssertEqual(restoredTopic?.resourceIds, ["resource-1"])
        XCTAssertEqual(restoredTopic?.estimatedMinutes, 40)
        XCTAssertEqual(restoredTopic?.difficultyLevel, 10)
    }

    private func createTemporarySubject() async throws -> Subject {
        let user = try await signedInTestUser()
        let subject = Subject(
            id: "test-subject-\(UUID().uuidString)",
            userId: user.id,
            name: "Workspace Test Subject",
            colorHex: "#3B82F6",
            syncStatus: .synced
        )
        createdSubjectIds.append(subject.id)
        try await SubjectService.shared.createSubject(subject)
        return subject
    }

    private func signedInTestUser() async throws -> AppUser {
        let credentials = try testCredentials()
        return try await AuthService.shared.signIn(
            email: credentials.email,
            password: credentials.password
        )
    }

    private func cleanupTemporaryData() async throws {
        for attemptId in createdAttemptIds {
            try? await QuizService.shared.deleteAttempt(id: attemptId)
        }

        for deadline in createdDeadlineIds {
            try? await DeadlineService.shared.deleteDeadline(id: deadline.id, subjectId: deadline.subjectId)
        }

        for resource in createdResourceIds {
            try? await ResourceService.shared.deleteResource(id: resource.id, subjectId: resource.subjectId)
        }

        for subjectId in createdSubjectIds {
            try? await StudyPathService.shared.deleteStudyPath(for: subjectId)
            try? await SubjectService.shared.deleteSubject(id: subjectId)
        }

        createdAttemptIds.removeAll()
        createdDeadlineIds.removeAll()
        createdResourceIds.removeAll()
        createdSubjectIds.removeAll()
    }

    private func configureFirebaseIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    private func testCredentials() throws -> (email: String, password: String) {
        let environment = ProcessInfo.processInfo.environment
        guard let email = environment["AUTH_TEST_EMAIL"], !email.isEmpty,
              let password = environment["AUTH_TEST_PASSWORD"], !password.isEmpty else {
            throw XCTSkip("Set AUTH_TEST_EMAIL and AUTH_TEST_PASSWORD to run subject workspace tests.")
        }
        return (email, password)
    }
}
