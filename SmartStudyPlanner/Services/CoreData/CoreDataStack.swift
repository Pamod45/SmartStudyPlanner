import CoreData
import Foundation

@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var email: String
    @NSManaged public var displayName: String
    @NSManaged public var profileImageURL: String?
    @NSManaged public var domain: String?
    @NSManaged public var institute: String?
    @NSManaged public var username: String?
}

@objc(CDUserSettings)
public class CDUserSettings: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var dailyStudyGoalHours: Double
    @NSManaged public var weeklyStudyGoalDays: Int
    @NSManaged public var preferredSessionDurationMinutes: Int
    @NSManaged public var breakDurationMinutes: Int
    @NSManaged public var notificationsEnabled: Bool
    @NSManaged public var dailyGoalAlertsEnabled: Bool
    @NSManaged public var dailyGoalAlertTime: Date
    @NSManaged public var sessionRemindersEnabled: Bool
    @NSManaged public var sessionReminderTime: Date
    @NSManaged public var quizzesPendingReminders: Bool
    @NSManaged public var quizReminderMinutesAfter: Int
    @NSManaged public var deadlineAlertsEnabled: Bool
    @NSManaged public var deadlineAlertTime: Date
    @NSManaged public var preferredStudyTime: String
    @NSManaged public var deadlineReminderDaysBefore: Int
    @NSManaged public var sessionReminderMinutesBefore: Int
    @NSManaged public var theme: String
    @NSManaged public var darkModeEnabled: Bool
    @NSManaged public var widgetConfiguration: String
    @NSManaged public var siriIntegrationEnabled: Bool
    @NSManaged public var accessibilityFontSize: Double
    @NSManaged public var reduceMotionEnabled: Bool
    @NSManaged public var highContrastEnabled: Bool
    @NSManaged public var hapticFeedbackEnabled: Bool
    @NSManaged public var soundEnabled: Bool
    @NSManaged public var calendarSyncEnabled: Bool
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String
}

@objc(CDSubject)
public class CDSubject: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var name: String
    @NSManaged public var colorHex: String
    @NSManaged public var notes: String
    @NSManaged public var iconName: String
    @NSManaged public var targetHoursPerWeek: Double
    @NSManaged public var totalHoursStudied: Double
    @NSManaged public var resourceCount: Int
    @NSManaged public var topicCount: Int
    @NSManaged public var deadlineIds: [String]
    @NSManaged public var resourceIds: [String]
    @NSManaged public var sessionIds: [String]
    @NSManaged public var noteFilePaths: [String]
    @NSManaged public var isArchived: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String
}

@objc(CDResource)
public class CDResource: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var subjectId: String
    @NSManaged public var name: String
    @NSManaged public var resourceType: String
    @NSManaged public var size: String
    @NSManaged public var content: String?
    @NSManaged public var localFilePath: String?
    @NSManaged public var remoteURL: String?
    @NSManaged public var fileSize: Int
    @NSManaged public var mimeType: String?
    @NSManaged public var tags: [String]
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String
}

public class CoreDataStack {
    public static let shared = CoreDataStack()
    
    private func destroyPersistentStore() {
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SmartStudyPlanner.sqlite")
        
        try? FileManager.default.removeItem(at: storeURL)
        try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite-shm"))
        try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite-wal"))
    }
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let model = NSManagedObjectModel()
        
        let userEntity = NSEntityDescription()
        userEntity.name = "CDUserProfile"
        userEntity.managedObjectClassName = NSStringFromClass(CDUserProfile.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false
        
        let emailAttr = NSAttributeDescription()
        emailAttr.name = "email"
        emailAttr.attributeType = .stringAttributeType
        emailAttr.isOptional = false
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "displayName"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        
        let urlAttr = NSAttributeDescription()
        urlAttr.name = "profileImageURL"
        urlAttr.attributeType = .stringAttributeType
        urlAttr.isOptional = true
        
        let domainAttr = NSAttributeDescription()
        domainAttr.name = "domain"
        domainAttr.attributeType = .stringAttributeType
        domainAttr.isOptional = true
        
        let instituteAttr = NSAttributeDescription()
        instituteAttr.name = "institute"
        instituteAttr.attributeType = .stringAttributeType
        instituteAttr.isOptional = true
        
        let usernameAttr = NSAttributeDescription()
        usernameAttr.name = "username"
        usernameAttr.attributeType = .stringAttributeType
        usernameAttr.isOptional = true
        
        userEntity.properties = [idAttr, emailAttr, nameAttr, urlAttr, domainAttr, instituteAttr, usernameAttr]
        
        // CDUserSettings
        let settingsEntity = NSEntityDescription()
        settingsEntity.name = "CDUserSettings"
        settingsEntity.managedObjectClassName = NSStringFromClass(CDUserSettings.self)
        
        let sIdAttr = NSAttributeDescription()
        sIdAttr.name = "id"
        sIdAttr.attributeType = .stringAttributeType
        sIdAttr.isOptional = false
        
        let sUserIdAttr = NSAttributeDescription()
        sUserIdAttr.name = "userId"
        sUserIdAttr.attributeType = .stringAttributeType
        sUserIdAttr.isOptional = false
        
        let sDailyHoursAttr = NSAttributeDescription()
        sDailyHoursAttr.name = "dailyStudyGoalHours"
        sDailyHoursAttr.attributeType = .doubleAttributeType
        sDailyHoursAttr.isOptional = false
        
        let sWeeklyDaysAttr = NSAttributeDescription()
        sWeeklyDaysAttr.name = "weeklyStudyGoalDays"
        sWeeklyDaysAttr.attributeType = .integer64AttributeType
        sWeeklyDaysAttr.isOptional = false
        
        let sPrefSessionAttr = NSAttributeDescription()
        sPrefSessionAttr.name = "preferredSessionDurationMinutes"
        sPrefSessionAttr.attributeType = .integer64AttributeType
        sPrefSessionAttr.isOptional = false
        
        let sBreakDurAttr = NSAttributeDescription()
        sBreakDurAttr.name = "breakDurationMinutes"
        sBreakDurAttr.attributeType = .integer64AttributeType
        sBreakDurAttr.isOptional = false
        
        let sNotifAttr = NSAttributeDescription()
        sNotifAttr.name = "notificationsEnabled"
        sNotifAttr.attributeType = .booleanAttributeType
        sNotifAttr.isOptional = false

        let sDailyGoalAlertsEnabledAttr = NSAttributeDescription()
        sDailyGoalAlertsEnabledAttr.name = "dailyGoalAlertsEnabled"
        sDailyGoalAlertsEnabledAttr.attributeType = .booleanAttributeType
        sDailyGoalAlertsEnabledAttr.isOptional = false

        let sDailyAlertAttr = NSAttributeDescription()
        sDailyAlertAttr.name = "dailyGoalAlertTime"
        sDailyAlertAttr.attributeType = .dateAttributeType
        sDailyAlertAttr.isOptional = false

        let sSessionRemindersEnabledAttr = NSAttributeDescription()
        sSessionRemindersEnabledAttr.name = "sessionRemindersEnabled"
        sSessionRemindersEnabledAttr.attributeType = .booleanAttributeType
        sSessionRemindersEnabledAttr.isOptional = false

        let sSessionReminderTimeAttr = NSAttributeDescription()
        sSessionReminderTimeAttr.name = "sessionReminderTime"
        sSessionReminderTimeAttr.attributeType = .dateAttributeType
        sSessionReminderTimeAttr.isOptional = false

        let sQuizRemAttr = NSAttributeDescription()
        sQuizRemAttr.name = "quizzesPendingReminders"
        sQuizRemAttr.attributeType = .booleanAttributeType
        sQuizRemAttr.isOptional = false

        let sQuizReminderMinutesAfterAttr = NSAttributeDescription()
        sQuizReminderMinutesAfterAttr.name = "quizReminderMinutesAfter"
        sQuizReminderMinutesAfterAttr.attributeType = .integer64AttributeType
        sQuizReminderMinutesAfterAttr.isOptional = false

        let sDeadlineAlertsEnabledAttr = NSAttributeDescription()
        sDeadlineAlertsEnabledAttr.name = "deadlineAlertsEnabled"
        sDeadlineAlertsEnabledAttr.attributeType = .booleanAttributeType
        sDeadlineAlertsEnabledAttr.isOptional = false

        let sDeadlineAlertAttr = NSAttributeDescription()
        sDeadlineAlertAttr.name = "deadlineAlertTime"
        sDeadlineAlertAttr.attributeType = .dateAttributeType
        sDeadlineAlertAttr.isOptional = false
        
        let sPrefTimeAttr = NSAttributeDescription()
        sPrefTimeAttr.name = "preferredStudyTime"
        sPrefTimeAttr.attributeType = .stringAttributeType
        sPrefTimeAttr.isOptional = false
        
        let sDeadRemAttr = NSAttributeDescription()
        sDeadRemAttr.name = "deadlineReminderDaysBefore"
        sDeadRemAttr.attributeType = .integer64AttributeType
        sDeadRemAttr.isOptional = false
        
        let sSessRemAttr = NSAttributeDescription()
        sSessRemAttr.name = "sessionReminderMinutesBefore"
        sSessRemAttr.attributeType = .integer64AttributeType
        sSessRemAttr.isOptional = false
        
        let sThemeAttr = NSAttributeDescription()
        sThemeAttr.name = "theme"
        sThemeAttr.attributeType = .stringAttributeType
        sThemeAttr.isOptional = false
        
        let sDarkModeEnabledAttr = NSAttributeDescription()
        sDarkModeEnabledAttr.name = "darkModeEnabled"
        sDarkModeEnabledAttr.attributeType = .booleanAttributeType
        sDarkModeEnabledAttr.isOptional = false
        
        let sWidgetConfigurationAttr = NSAttributeDescription()
        sWidgetConfigurationAttr.name = "widgetConfiguration"
        sWidgetConfigurationAttr.attributeType = .stringAttributeType
        sWidgetConfigurationAttr.isOptional = false
        
        let sSiriIntegrationEnabledAttr = NSAttributeDescription()
        sSiriIntegrationEnabledAttr.name = "siriIntegrationEnabled"
        sSiriIntegrationEnabledAttr.attributeType = .booleanAttributeType
        sSiriIntegrationEnabledAttr.isOptional = false
        
        let sAccFontAttr = NSAttributeDescription()
        sAccFontAttr.name = "accessibilityFontSize"
        sAccFontAttr.attributeType = .doubleAttributeType
        sAccFontAttr.isOptional = false
        
        let sReduceMotionEnabledAttr = NSAttributeDescription()
        sReduceMotionEnabledAttr.name = "reduceMotionEnabled"
        sReduceMotionEnabledAttr.attributeType = .booleanAttributeType
        sReduceMotionEnabledAttr.isOptional = false
        
        let sHighContrastEnabledAttr = NSAttributeDescription()
        sHighContrastEnabledAttr.name = "highContrastEnabled"
        sHighContrastEnabledAttr.attributeType = .booleanAttributeType
        sHighContrastEnabledAttr.isOptional = false

        let sHapticAttr = NSAttributeDescription()
        sHapticAttr.name = "hapticFeedbackEnabled"
        sHapticAttr.attributeType = .booleanAttributeType
        sHapticAttr.isOptional = false
        
        let sSoundAttr = NSAttributeDescription()
        sSoundAttr.name = "soundEnabled"
        sSoundAttr.attributeType = .booleanAttributeType
        sSoundAttr.isOptional = false
        
        let sCalSyncAttr = NSAttributeDescription()
        sCalSyncAttr.name = "calendarSyncEnabled"
        sCalSyncAttr.attributeType = .booleanAttributeType
        sCalSyncAttr.isOptional = false
        
        let sUpdAttr = NSAttributeDescription()
        sUpdAttr.name = "updatedAt"
        sUpdAttr.attributeType = .dateAttributeType
        sUpdAttr.isOptional = false
        
        let sSyncAttr = NSAttributeDescription()
        sSyncAttr.name = "syncStatus"
        sSyncAttr.attributeType = .stringAttributeType
        sSyncAttr.isOptional = false

        settingsEntity.properties = [
            sIdAttr, sUserIdAttr, sDailyHoursAttr, sWeeklyDaysAttr, sPrefSessionAttr,
            sBreakDurAttr, sNotifAttr, sDailyGoalAlertsEnabledAttr, sDailyAlertAttr,
            sSessionRemindersEnabledAttr, sSessionReminderTimeAttr, sQuizRemAttr,
            sQuizReminderMinutesAfterAttr, sDeadlineAlertsEnabledAttr, sDeadlineAlertAttr,
            sPrefTimeAttr, sDeadRemAttr, sSessRemAttr, sThemeAttr, sDarkModeEnabledAttr,
            sWidgetConfigurationAttr, sSiriIntegrationEnabledAttr, sAccFontAttr,
            sReduceMotionEnabledAttr, sHighContrastEnabledAttr, sHapticAttr, sSoundAttr,
            sCalSyncAttr, sUpdAttr, sSyncAttr
        ]

        let subjectEntity = NSEntityDescription()
        subjectEntity.name = "CDSubject"
        subjectEntity.managedObjectClassName = NSStringFromClass(CDSubject.self)

        let subIdAttr = NSAttributeDescription()
        subIdAttr.name = "id"
        subIdAttr.attributeType = .stringAttributeType
        subIdAttr.isOptional = false

        let subUserIdAttr = NSAttributeDescription()
        subUserIdAttr.name = "userId"
        subUserIdAttr.attributeType = .stringAttributeType
        subUserIdAttr.isOptional = false

        let subNameAttr = NSAttributeDescription()
        subNameAttr.name = "name"
        subNameAttr.attributeType = .stringAttributeType
        subNameAttr.isOptional = false

        let subColorAttr = NSAttributeDescription()
        subColorAttr.name = "colorHex"
        subColorAttr.attributeType = .stringAttributeType
        subColorAttr.isOptional = false

        let subNotesAttr = NSAttributeDescription()
        subNotesAttr.name = "notes"
        subNotesAttr.attributeType = .stringAttributeType
        subNotesAttr.isOptional = false

        let subIconAttr = NSAttributeDescription()
        subIconAttr.name = "iconName"
        subIconAttr.attributeType = .stringAttributeType
        subIconAttr.isOptional = false

        let subTargetHoursAttr = NSAttributeDescription()
        subTargetHoursAttr.name = "targetHoursPerWeek"
        subTargetHoursAttr.attributeType = .doubleAttributeType
        subTargetHoursAttr.isOptional = false

        let subTotalHoursAttr = NSAttributeDescription()
        subTotalHoursAttr.name = "totalHoursStudied"
        subTotalHoursAttr.attributeType = .doubleAttributeType
        subTotalHoursAttr.isOptional = false

        let subResourceCountAttr = NSAttributeDescription()
        subResourceCountAttr.name = "resourceCount"
        subResourceCountAttr.attributeType = .integer64AttributeType
        subResourceCountAttr.isOptional = false

        let subTopicCountAttr = NSAttributeDescription()
        subTopicCountAttr.name = "topicCount"
        subTopicCountAttr.attributeType = .integer64AttributeType
        subTopicCountAttr.isOptional = false

        let subDeadlineIdsAttr = NSAttributeDescription()
        subDeadlineIdsAttr.name = "deadlineIds"
        subDeadlineIdsAttr.attributeType = .transformableAttributeType
        subDeadlineIdsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        subDeadlineIdsAttr.isOptional = false

        let subResourceIdsAttr = NSAttributeDescription()
        subResourceIdsAttr.name = "resourceIds"
        subResourceIdsAttr.attributeType = .transformableAttributeType
        subResourceIdsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        subResourceIdsAttr.isOptional = false

        let subSessionIdsAttr = NSAttributeDescription()
        subSessionIdsAttr.name = "sessionIds"
        subSessionIdsAttr.attributeType = .transformableAttributeType
        subSessionIdsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        subSessionIdsAttr.isOptional = false

        let subNoteFilePathsAttr = NSAttributeDescription()
        subNoteFilePathsAttr.name = "noteFilePaths"
        subNoteFilePathsAttr.attributeType = .transformableAttributeType
        subNoteFilePathsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        subNoteFilePathsAttr.isOptional = false

        let subArchivedAttr = NSAttributeDescription()
        subArchivedAttr.name = "isArchived"
        subArchivedAttr.attributeType = .booleanAttributeType
        subArchivedAttr.isOptional = false

        let subCreatedAtAttr = NSAttributeDescription()
        subCreatedAtAttr.name = "createdAt"
        subCreatedAtAttr.attributeType = .dateAttributeType
        subCreatedAtAttr.isOptional = false

        let subUpdatedAtAttr = NSAttributeDescription()
        subUpdatedAtAttr.name = "updatedAt"
        subUpdatedAtAttr.attributeType = .dateAttributeType
        subUpdatedAtAttr.isOptional = false

        let subSyncAttr = NSAttributeDescription()
        subSyncAttr.name = "syncStatus"
        subSyncAttr.attributeType = .stringAttributeType
        subSyncAttr.isOptional = false

        subjectEntity.properties = [
            subIdAttr, subUserIdAttr, subNameAttr, subColorAttr, subNotesAttr,
            subIconAttr, subTargetHoursAttr, subTotalHoursAttr, subResourceCountAttr,
            subTopicCountAttr, subDeadlineIdsAttr, subResourceIdsAttr, subSessionIdsAttr,
            subNoteFilePathsAttr, subArchivedAttr, subCreatedAtAttr, subUpdatedAtAttr, subSyncAttr
        ]
        
        let resourceEntity = NSEntityDescription()
        resourceEntity.name = "CDResource"
        resourceEntity.managedObjectClassName = NSStringFromClass(CDResource.self)

        let resIdAttr = NSAttributeDescription()
        resIdAttr.name = "id"
        resIdAttr.attributeType = .stringAttributeType
        resIdAttr.isOptional = false

        let resUserIdAttr = NSAttributeDescription()
        resUserIdAttr.name = "userId"
        resUserIdAttr.attributeType = .stringAttributeType
        resUserIdAttr.isOptional = false

        let resSubjectIdAttr = NSAttributeDescription()
        resSubjectIdAttr.name = "subjectId"
        resSubjectIdAttr.attributeType = .stringAttributeType
        resSubjectIdAttr.isOptional = false

        let resNameAttr = NSAttributeDescription()
        resNameAttr.name = "name"
        resNameAttr.attributeType = .stringAttributeType
        resNameAttr.isOptional = false

        let resTypeAttr = NSAttributeDescription()
        resTypeAttr.name = "resourceType"
        resTypeAttr.attributeType = .stringAttributeType
        resTypeAttr.isOptional = false

        let resSizeAttr = NSAttributeDescription()
        resSizeAttr.name = "size"
        resSizeAttr.attributeType = .stringAttributeType
        resSizeAttr.isOptional = false

        let resContentAttr = NSAttributeDescription()
        resContentAttr.name = "content"
        resContentAttr.attributeType = .stringAttributeType
        resContentAttr.isOptional = true

        let resLocalPathAttr = NSAttributeDescription()
        resLocalPathAttr.name = "localFilePath"
        resLocalPathAttr.attributeType = .stringAttributeType
        resLocalPathAttr.isOptional = true

        let resRemoteURLAttr = NSAttributeDescription()
        resRemoteURLAttr.name = "remoteURL"
        resRemoteURLAttr.attributeType = .stringAttributeType
        resRemoteURLAttr.isOptional = true

        let resFileSizeAttr = NSAttributeDescription()
        resFileSizeAttr.name = "fileSize"
        resFileSizeAttr.attributeType = .integer64AttributeType
        resFileSizeAttr.isOptional = false

        let resMimeTypeAttr = NSAttributeDescription()
        resMimeTypeAttr.name = "mimeType"
        resMimeTypeAttr.attributeType = .stringAttributeType
        resMimeTypeAttr.isOptional = true

        let resTagsAttr = NSAttributeDescription()
        resTagsAttr.name = "tags"
        resTagsAttr.attributeType = .transformableAttributeType
        resTagsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        resTagsAttr.isOptional = false

        let resFavoriteAttr = NSAttributeDescription()
        resFavoriteAttr.name = "isFavorite"
        resFavoriteAttr.attributeType = .booleanAttributeType
        resFavoriteAttr.isOptional = false

        let resCreatedAtAttr = NSAttributeDescription()
        resCreatedAtAttr.name = "createdAt"
        resCreatedAtAttr.attributeType = .dateAttributeType
        resCreatedAtAttr.isOptional = false

        let resUpdatedAtAttr = NSAttributeDescription()
        resUpdatedAtAttr.name = "updatedAt"
        resUpdatedAtAttr.attributeType = .dateAttributeType
        resUpdatedAtAttr.isOptional = false

        let resSyncAttr = NSAttributeDescription()
        resSyncAttr.name = "syncStatus"
        resSyncAttr.attributeType = .stringAttributeType
        resSyncAttr.isOptional = false

        resourceEntity.properties = [
            resIdAttr, resUserIdAttr, resSubjectIdAttr, resNameAttr, resTypeAttr,
            resSizeAttr, resContentAttr, resLocalPathAttr, resRemoteURLAttr,
            resFileSizeAttr, resMimeTypeAttr, resTagsAttr, resFavoriteAttr,
            resCreatedAtAttr, resUpdatedAtAttr, resSyncAttr
        ]
        
        model.entities = [userEntity, settingsEntity, subjectEntity, resourceEntity]
        
        let container = NSPersistentContainer(name: "SmartStudyPlanner", managedObjectModel: model)
        
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data load error: \(error)")
                self.destroyPersistentStore()
                
                container.loadPersistentStores { _, reloadError in
                    if let reloadError = reloadError {
                        fatalError("Failed to reload store after reset: \(reloadError)")
                    }
                    print("Store reset and reloaded successfully")
                }
            }
        }
        return container
    }()
    
    public var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
            context.rollback()
        }
    }
}
