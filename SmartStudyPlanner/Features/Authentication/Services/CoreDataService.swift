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
                    noteFilePaths: cdSubject.noteFilePaths,
                    isArchived: cdSubject.isArchived,
                    createdAt: cdSubject.createdAt,
                    updatedAt: cdSubject.updatedAt,
                    syncStatus: SyncStatus(rawValue: cdSubject.syncStatus) ?? .localOnly
                )
            }
        } catch {
            print("Failed to fetch cached subjects: \(error)")
            return []
        }
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

        CoreDataStack.shared.saveContext()
    }
}


