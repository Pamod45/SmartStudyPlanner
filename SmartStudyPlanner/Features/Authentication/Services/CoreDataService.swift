import CoreData
import Foundation

class CoreDataService {
    static let shared = CoreDataService()
    private init() {}
    
    func getCachedProfile() -> AppUser? {
        let request = NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
        request.fetchLimit = 1
        
        do {
            if let cdUser = try CoreDataStack.shared.context.fetch(request).first {
                return AppUser(
                    id: cdUser.id,
                    email: cdUser.email,
                    displayName: cdUser.displayName,
                    domain: cdUser.domain,
                    institute: cdUser.institute,
                    username: cdUser.username,
                    profileImageURL: cdUser.profileImageURL
                )
            }
        } catch {
            print("Failed to fetch cached profile: \(error)")
        }
        return nil
    }
    
    func cacheProfile(_ user: AppUser) {
        let context = CoreDataStack.shared.context
        
        let request = NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
        request.fetchLimit = 1
        
        let cdUser: CDUserProfile
        if let existing = try? context.fetch(request).first {
            cdUser = existing
        } else {
            cdUser = CDUserProfile(context: context)
        }
        
        cdUser.id = user.id
        cdUser.email = user.email
        cdUser.displayName = user.displayName
        cdUser.domain = user.domain
        cdUser.institute = user.institute
        cdUser.username = user.username
        cdUser.profileImageURL = user.profileImageURL
        
        CoreDataStack.shared.saveContext()
    }
    
    func getCachedSettings(for userId: String) -> UserSettings? {
        let request = NSFetchRequest<CDUserSettings>(entityName: "CDUserSettings")
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.fetchLimit = 1

        do {
            if let cdSettings = try CoreDataStack.shared.context.fetch(request).first {
                return UserSettings(
                    id: cdSettings.id,
                    userId: cdSettings.userId,
                    dailyStudyGoalHours: cdSettings.dailyStudyGoalHours,
                    weeklyStudyGoalDays: cdSettings.weeklyStudyGoalDays,
                    preferredSessionDurationMinutes: cdSettings.preferredSessionDurationMinutes,
                    breakDurationMinutes: cdSettings.breakDurationMinutes,
                    notificationsEnabled: cdSettings.notificationsEnabled,
                    dailyGoalAlertsEnabled: cdSettings.dailyGoalAlertsEnabled,
                    dailyGoalAlertTime: cdSettings.dailyGoalAlertTime,
                    sessionRemindersEnabled: cdSettings.sessionRemindersEnabled,
                    sessionReminderTime: cdSettings.sessionReminderTime,
                    quizzesPendingReminders: cdSettings.quizzesPendingReminders,
                    quizReminderMinutesAfter: cdSettings.quizReminderMinutesAfter,
                    deadlineAlertsEnabled: cdSettings.deadlineAlertsEnabled,
                    deadlineAlertTime: cdSettings.deadlineAlertTime,
                    preferredStudyTime: cdSettings.preferredStudyTime,
                    deadlineReminderDaysBefore: cdSettings.deadlineReminderDaysBefore,
                    sessionReminderMinutesBefore: cdSettings.sessionReminderMinutesBefore,
                    theme: AppThemePreference(rawValue: cdSettings.theme) ?? .system,
                    darkModeEnabled: cdSettings.darkModeEnabled,
                    widgetConfiguration: cdSettings.widgetConfiguration,
                    siriIntegrationEnabled: cdSettings.siriIntegrationEnabled,
                    accessibilityFontSize: cdSettings.accessibilityFontSize,
                    reduceMotionEnabled: cdSettings.reduceMotionEnabled,
                    highContrastEnabled: cdSettings.highContrastEnabled,
                    hapticFeedbackEnabled: cdSettings.hapticFeedbackEnabled,
                    soundEnabled: cdSettings.soundEnabled,
                    calendarSyncEnabled: cdSettings.calendarSyncEnabled,
                    updatedAt: cdSettings.updatedAt,
                    syncStatus: SyncStatus(rawValue: cdSettings.syncStatus) ?? .localOnly
                )
            }
        } catch {
            print("Failed to fetch cached settings: \(error)")
        }
        return nil
    }

    func cacheSettings(_ settings: UserSettings) {
        let context = CoreDataStack.shared.context

        let request = NSFetchRequest<CDUserSettings>(entityName: "CDUserSettings")
        request.predicate = NSPredicate(format: "userId == %@", settings.userId)
        request.fetchLimit = 1

        let cdSettings: CDUserSettings
        if let existing = try? context.fetch(request).first {
            cdSettings = existing
        } else {
            cdSettings = CDUserSettings(context: context)
        }

        cdSettings.id = settings.id
        cdSettings.userId = settings.userId
        cdSettings.dailyStudyGoalHours = settings.dailyStudyGoalHours
        cdSettings.weeklyStudyGoalDays = settings.weeklyStudyGoalDays
        cdSettings.preferredSessionDurationMinutes = settings.preferredSessionDurationMinutes
        cdSettings.breakDurationMinutes = settings.breakDurationMinutes
        cdSettings.notificationsEnabled = settings.notificationsEnabled
        cdSettings.dailyGoalAlertsEnabled = settings.dailyGoalAlertsEnabled
        cdSettings.dailyGoalAlertTime = settings.dailyGoalAlertTime
        cdSettings.sessionRemindersEnabled = settings.sessionRemindersEnabled
        cdSettings.sessionReminderTime = settings.sessionReminderTime
        cdSettings.quizzesPendingReminders = settings.quizzesPendingReminders
        cdSettings.quizReminderMinutesAfter = settings.quizReminderMinutesAfter
        cdSettings.deadlineAlertsEnabled = settings.deadlineAlertsEnabled
        cdSettings.deadlineAlertTime = settings.deadlineAlertTime
        cdSettings.preferredStudyTime = settings.preferredStudyTime
        cdSettings.deadlineReminderDaysBefore = settings.deadlineReminderDaysBefore
        cdSettings.sessionReminderMinutesBefore = settings.sessionReminderMinutesBefore
        cdSettings.theme = settings.theme.rawValue
        cdSettings.darkModeEnabled = settings.darkModeEnabled
        cdSettings.widgetConfiguration = settings.widgetConfiguration
        cdSettings.siriIntegrationEnabled = settings.siriIntegrationEnabled
        cdSettings.accessibilityFontSize = settings.accessibilityFontSize
        cdSettings.reduceMotionEnabled = settings.reduceMotionEnabled
        cdSettings.highContrastEnabled = settings.highContrastEnabled
        cdSettings.hapticFeedbackEnabled = settings.hapticFeedbackEnabled
        cdSettings.soundEnabled = settings.soundEnabled
        cdSettings.calendarSyncEnabled = settings.calendarSyncEnabled
        cdSettings.updatedAt = settings.updatedAt
        cdSettings.syncStatus = settings.syncStatus.rawValue

        CoreDataStack.shared.saveContext()
    }
    
    func getCachedSubjects(for userId: String) -> [Subject] {
        let request = NSFetchRequest<CDSubject>(entityName: "CDSubject")
        request.predicate = NSPredicate(format: "userId == %@", userId)

        do {
            let results = try CoreDataStack.shared.context.fetch(request)
            return results.map { cdSubject in
                Subject(
                    id: cdSubject.id,
                    userId: cdSubject.userId,
                    name: cdSubject.name,
                    colorHex: cdSubject.colorHex,
                    notes: cdSubject.notes,
                    iconName: cdSubject.iconName,
                    targetHoursPerWeek: cdSubject.targetHoursPerWeek,
                    totalHoursStudied: cdSubject.totalHoursStudied,
                    resourceCount: cdSubject.resourceCount,
                    topicCount: cdSubject.topicCount,
                    deadlineIds: cdSubject.deadlineIds,
                    resourceIds: cdSubject.resourceIds,
                    sessionIds: cdSubject.sessionIds,
                    isArchived: cdSubject.isArchived,
                    createdAt: cdSubject.createdAt,
                    updatedAt: cdSubject.updatedAt,
                    syncStatus: SyncStatus(rawValue: cdSubject.syncStatus) ?? .localOnly,
                    noteFilePaths: cdSubject.noteFilePaths
                )
            }
        } catch {
            print("Failed to fetch cached subjects: \(error)")
            return []
        }
    }

    func getCachedSubject(id: String) -> Subject? {
        let request = NSFetchRequest<CDSubject>(entityName: "CDSubject")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            if let cdSubject = try CoreDataStack.shared.context.fetch(request).first {
                return Subject(
                    id: cdSubject.id,
                    userId: cdSubject.userId,
                    name: cdSubject.name,
                    colorHex: cdSubject.colorHex,
                    notes: cdSubject.notes,
                    iconName: cdSubject.iconName,
                    targetHoursPerWeek: cdSubject.targetHoursPerWeek,
                    totalHoursStudied: cdSubject.totalHoursStudied,
                    resourceCount: cdSubject.resourceCount,
                    topicCount: cdSubject.topicCount,
                    deadlineIds: cdSubject.deadlineIds,
                    resourceIds: cdSubject.resourceIds,
                    sessionIds: cdSubject.sessionIds,
                    isArchived: cdSubject.isArchived,
                    createdAt: cdSubject.createdAt,
                    updatedAt: cdSubject.updatedAt,
                    syncStatus: SyncStatus(rawValue: cdSubject.syncStatus) ?? .localOnly,
                    noteFilePaths: cdSubject.noteFilePaths
                )
            }
        } catch {
            print("Failed to fetch cached subject by id: \(error)")
        }
        return nil
    }

    func upsertSubject(_ subject: Subject) {
        let context = CoreDataStack.shared.context

        let request = NSFetchRequest<CDSubject>(entityName: "CDSubject")
        request.predicate = NSPredicate(format: "id == %@", subject.id)
        request.fetchLimit = 1

        let cdSubject: CDSubject
        if let existing = try? context.fetch(request).first {
            cdSubject = existing
        } else {
            cdSubject = CDSubject(context: context)
        }

        cdSubject.id = subject.id
        cdSubject.userId = subject.userId
        cdSubject.name = subject.name
        cdSubject.colorHex = subject.colorHex
        cdSubject.notes = subject.notes
        cdSubject.iconName = subject.iconName
        cdSubject.targetHoursPerWeek = subject.targetHoursPerWeek
        cdSubject.totalHoursStudied = subject.totalHoursStudied
        cdSubject.resourceCount = subject.resourceCount
        cdSubject.topicCount = subject.topicCount
        cdSubject.deadlineIds = subject.deadlineIds
        cdSubject.resourceIds = subject.resourceIds
        cdSubject.sessionIds = subject.sessionIds
        cdSubject.noteFilePaths = subject.noteFilePaths
        cdSubject.isArchived = subject.isArchived
        cdSubject.createdAt = subject.createdAt
        cdSubject.updatedAt = subject.updatedAt
        cdSubject.syncStatus = subject.syncStatus.rawValue

        CoreDataStack.shared.saveContext()
    }

    func cacheSubjects(_ subjects: [Subject]) {
        subjects.forEach { upsertSubject($0) }
    }

    func deleteSubject(id: String) {
        let context = CoreDataStack.shared.context
        let request = NSFetchRequest<CDSubject>(entityName: "CDSubject")
        request.predicate = NSPredicate(format: "id == %@", id)
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
            CoreDataStack.shared.saveContext()
        }
    }
    
    func getCachedResources(for subjectId: String) -> [Resource] {
        let request = NSFetchRequest<CDResource>(entityName: "CDResource")
        request.predicate = NSPredicate(format: "subjectId == %@", subjectId)

        do {
            let results = try CoreDataStack.shared.context.fetch(request)
            return results.compactMap { cdResource in
                guard let resourceType = ResourceType(rawValue: cdResource.resourceType) else { return nil }
                return Resource(
                    id: cdResource.id,
                    userId: cdResource.userId,
                    subjectId: cdResource.subjectId,
                    name: cdResource.name,
                    resourceType: resourceType,
                    size: cdResource.size,
                    content: cdResource.content,
                    localFilePath: cdResource.localFilePath,
                    remoteURL: cdResource.remoteURL,
                    fileSize: cdResource.fileSize,
                    mimeType: cdResource.mimeType,
                    tags: cdResource.tags,
                    isFavorite: cdResource.isFavorite,
                    createdAt: cdResource.createdAt,
                    updatedAt: cdResource.updatedAt,
                    syncStatus: SyncStatus(rawValue: cdResource.syncStatus) ?? .localOnly
                )
            }
        } catch {
            print("Failed to fetch cached resources: \(error)")
            return []
        }
    }

    func upsertResource(_ resource: Resource) {
        let context = CoreDataStack.shared.context

        let request = NSFetchRequest<CDResource>(entityName: "CDResource")
        request.predicate = NSPredicate(format: "id == %@", resource.id)
        request.fetchLimit = 1

        let cdResource: CDResource
        if let existing = try? context.fetch(request).first {
            cdResource = existing
        } else {
            cdResource = CDResource(context: context)
        }

        cdResource.id = resource.id
        cdResource.userId = resource.userId
        cdResource.subjectId = resource.subjectId
        cdResource.name = resource.name
        cdResource.resourceType = resource.resourceType.rawValue
        cdResource.size = resource.size
        cdResource.content = resource.content
        cdResource.localFilePath = resource.localFilePath
        cdResource.remoteURL = resource.remoteURL
        cdResource.fileSize = resource.fileSize ?? 0
        cdResource.mimeType = resource.mimeType
        cdResource.tags = resource.tags
        cdResource.isFavorite = resource.isFavorite
        cdResource.createdAt = resource.createdAt
        cdResource.updatedAt = resource.updatedAt
        cdResource.syncStatus = resource.syncStatus.rawValue

        CoreDataStack.shared.saveContext()
    }

    func cacheResources(_ resources: [Resource]) {
        resources.forEach { upsertResource($0) }
    }

    func deleteResource(id: String) {
        let context = CoreDataStack.shared.context
        let request = NSFetchRequest<CDResource>(entityName: "CDResource")
        request.predicate = NSPredicate(format: "id == %@", id)
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
            CoreDataStack.shared.saveContext()
        }
    }
    
    func getCachedStudyPath(for subjectId: String) -> [StudyPathTopic] {
        let request = NSFetchRequest<CDStudyPathTopic>(entityName: "CDStudyPathTopic")
        request.predicate = NSPredicate(format: "subjectId == %@", subjectId)
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        do {
            let results = try CoreDataStack.shared.context.fetch(request)
            return results.map { cdTopic in
                StudyPathTopic(
                    id: cdTopic.id,
                    subjectId: cdTopic.subjectId,
                    userId: cdTopic.userId,
                    order: Int(cdTopic.order),
                    title: cdTopic.title,
                    description: cdTopic.description_,
                    subtopics: cdTopic.subtopics,
                    weightPercent: Int(cdTopic.weightPercent),
                    estimatedHours: Int(cdTopic.estimatedHours),
                    resourceIds: cdTopic.resourceIds,
                    completionPercent: cdTopic.completionPercent,
                    isCompleted: cdTopic.isCompleted,
                    generatedAt: cdTopic.generatedAt,
                    syncStatus: SyncStatus(rawValue: cdTopic.syncStatus) ?? .localOnly
                )
            }
        } catch {
            print("Failed to fetch cached study path: \(error)")
            return []
        }
    }

    func upsertStudyPathTopic(_ topic: StudyPathTopic) {
        let context = CoreDataStack.shared.context

        let request = NSFetchRequest<CDStudyPathTopic>(entityName: "CDStudyPathTopic")
        request.predicate = NSPredicate(format: "id == %@", topic.id)
        request.fetchLimit = 1

        let cdTopic: CDStudyPathTopic
        if let existing = try? context.fetch(request).first {
            cdTopic = existing
        } else {
            cdTopic = CDStudyPathTopic(context: context)
        }

        cdTopic.id = topic.id
        cdTopic.subjectId = topic.subjectId
        cdTopic.userId = topic.userId
        cdTopic.order = Int32(topic.order)
        cdTopic.title = topic.title
        cdTopic.description_ = topic.description
        cdTopic.subtopics = topic.subtopics
        cdTopic.weightPercent = Int32(topic.weightPercent)
        cdTopic.estimatedHours = Int32(topic.estimatedHours)
        cdTopic.resourceIds = topic.resourceIds
        cdTopic.completionPercent = topic.completionPercent
        cdTopic.isCompleted = topic.isCompleted
        cdTopic.generatedAt = topic.generatedAt
        cdTopic.syncStatus = topic.syncStatus.rawValue

        CoreDataStack.shared.saveContext()
    }

    func cacheStudyPath(_ topics: [StudyPathTopic]) {
        topics.forEach { upsertStudyPathTopic($0) }
    }

    func deleteStudyPath(for subjectId: String) {
        let context = CoreDataStack.shared.context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStudyPathTopic")
        request.predicate = NSPredicate(format: "subjectId == %@", subjectId)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try? context.execute(deleteRequest)
        CoreDataStack.shared.saveContext()
    }
    
    func clearCache() {
        let context = CoreDataStack.shared.context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDUserProfile")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try? context.execute(deleteRequest)

        let settingsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDUserSettings")
        let settingsDeleteRequest = NSBatchDeleteRequest(fetchRequest: settingsRequest)
        try? context.execute(settingsDeleteRequest)

        let subjectsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDSubject")
        let subjectsDeleteRequest = NSBatchDeleteRequest(fetchRequest: subjectsRequest)
        try? context.execute(subjectsDeleteRequest)

        let resourcesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDResource")
        let resourcesDeleteRequest = NSBatchDeleteRequest(fetchRequest: resourcesRequest)
        try? context.execute(resourcesDeleteRequest)

        let studyPathRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStudyPathTopic")
        let studyPathDeleteRequest = NSBatchDeleteRequest(fetchRequest: studyPathRequest)
        try? context.execute(studyPathDeleteRequest)

        CoreDataStack.shared.saveContext()
    }

    // MARK: - Quiz Attempts

    func getCachedAttempts(for subjectId: String) -> [QuizAttempt] {
        let request = NSFetchRequest<CDQuizAttempt>(entityName: "CDQuizAttempt")
        request.predicate = NSPredicate(format: "subjectId == %@", subjectId)
        let sortDescriptor = NSSortDescriptor(key: "completedAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        do {
            let results = try CoreDataStack.shared.context.fetch(request)
            return results.compactMap { cd -> QuizAttempt? in
                let questions: [QuizQuestion] = (try? JSONDecoder().decode([QuizQuestion].self, from: cd.questionsData)) ?? []
                let selectedAnswers: [String: Int] = (try? JSONDecoder().decode([String: Int].self, from: cd.selectedAnswersData)) ?? [:]

                return QuizAttempt(
                    id: cd.id,
                    userId: cd.userId,
                    quizName: cd.quizName,
                    topicName: cd.topicName,
                    subjectId: cd.subjectId,
                    questions: questions,
                    selectedAnswers: selectedAnswers,
                    timeSpentSeconds: Int(cd.timeSpentSeconds),
                    completedAt: cd.completedAt,
                    syncStatus: SyncStatus(rawValue: cd.syncStatus) ?? .localOnly
                )
            }
        } catch {
            print("Failed to fetch cached quiz attempts: \(error)")
            return []
        }
    }

    func upsertAttempt(_ attempt: QuizAttempt) {
        let context = CoreDataStack.shared.context

        let request = NSFetchRequest<CDQuizAttempt>(entityName: "CDQuizAttempt")
        request.predicate = NSPredicate(format: "id == %@", attempt.id)
        request.fetchLimit = 1

        let cdAttempt: CDQuizAttempt
        if let existing = try? context.fetch(request).first {
            cdAttempt = existing
        } else {
            cdAttempt = CDQuizAttempt(context: context)
        }

        let questionsData  = (try? JSONEncoder().encode(attempt.questions))         ?? Data()
        let answersData    = (try? JSONEncoder().encode(attempt.selectedAnswers))    ?? Data()

        cdAttempt.id                 = attempt.id
        cdAttempt.subjectId          = attempt.subjectId
        cdAttempt.userId             = attempt.userId
        cdAttempt.quizName           = attempt.quizName
        cdAttempt.topicName          = attempt.topicName
        cdAttempt.questionsData      = questionsData
        cdAttempt.selectedAnswersData = answersData
        cdAttempt.scorePercent       = Int32(attempt.scorePercent)
        cdAttempt.timeSpentSeconds   = Int32(attempt.timeSpentSeconds)
        cdAttempt.completedAt        = attempt.completedAt
        cdAttempt.syncStatus         = attempt.syncStatus.rawValue

        CoreDataStack.shared.saveContext()
    }

    func deleteAttempt(id: String) {
        let context = CoreDataStack.shared.context
        let request = NSFetchRequest<CDQuizAttempt>(entityName: "CDQuizAttempt")
        request.predicate = NSPredicate(format: "id == %@", id)
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
            CoreDataStack.shared.saveContext()
        }
    }
}
