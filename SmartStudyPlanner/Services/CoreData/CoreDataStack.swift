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

@objc(CDStudyPathTopic)
public class CDStudyPathTopic: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var subjectId: String
    @NSManaged public var userId: String
    @NSManaged public var order: Int32
    @NSManaged public var title: String
    @NSManaged public var description_: String
    @NSManaged public var subtopics: [String]
    @NSManaged public var weightPercent: Int32
    @NSManaged public var estimatedHours: Int32
    @NSManaged public var resourceIds: [String]
    @NSManaged public var completionPercent: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var generatedAt: Date
    @NSManaged public var syncStatus: String
}

@objc(CDQuizAttempt)
public class CDQuizAttempt: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var subjectId: String
    @NSManaged public var userId: String
    @NSManaged public var quizName: String
    @NSManaged public var topicName: String
    @NSManaged public var questionsData: Data
    @NSManaged public var selectedAnswersData: Data
    @NSManaged public var scorePercent: Int32
    @NSManaged public var timeSpentSeconds: Int32
    @NSManaged public var completedAt: Date
    @NSManaged public var syncStatus: String
}

@objc(CDAvailabilitySlot)
public class CDAvailabilitySlot: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var type: String
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date
    @NSManaged public var date: Date?
    @NSManaged public var rangeStart: Date?
    @NSManaged public var rangeEnd: Date?
    @NSManaged public var label: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String
}

@objc(CDDeadline)
public class CDDeadline: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var subjectId: String
    @NSManaged public var subjectColorHex: String
    @NSManaged public var name: String
    @NSManaged public var dueDate: Date
    @NSManaged public var hasReminder: Bool
    @NSManaged public var isHighPriority: Bool
    @NSManaged public var notes: String
    @NSManaged public var tag: String
    @NSManaged public var priority: String
    @NSManaged public var status: String
    @NSManaged public var reminderDate: Date?
    @NSManaged public var linkedSessionIds: [String]
    @NSManaged public var notificationId: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String
}

@objc(CDStudySession)
public class CDStudySession: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var subjectId: String
    @NSManaged public var subjectName: String
    @NSManaged public var subjectColorHex: String
    @NSManaged public var title: String
    @NSManaged public var topic: String
    @NSManaged public var notes: String?
    @NSManaged public var scheduledDate: Date
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date
    @NSManaged public var actualDurationMinutes: NSNumber?
    @NSManaged public var status: String
    @NSManaged public var sessionType: String
    @NSManaged public var hasReminder: Bool
    @NSManaged public var linkedDeadlineId: String?
    @NSManaged public var linkedPlanId: String?
    @NSManaged public var resourceIds: [String]
    @NSManaged public var topicIds: [String]
    @NSManaged public var rating: NSNumber?
    @NSManaged public var externalCalendarEventId: String?
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

        func attr(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            return attribute
        }

        func transformableAttr(_ name: String, optional: Bool = false) -> NSAttributeDescription {
            let attribute = attr(name, .transformableAttributeType, optional: optional)
            attribute.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
            return attribute
        }
        
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
        
        let pathTopicEntity = NSEntityDescription()
        pathTopicEntity.name = "CDStudyPathTopic"
        pathTopicEntity.managedObjectClassName = NSStringFromClass(CDStudyPathTopic.self)

        let ptIdAttr = NSAttributeDescription()
        ptIdAttr.name = "id"
        ptIdAttr.attributeType = .stringAttributeType
        ptIdAttr.isOptional = false

        let ptSubjectIdAttr = NSAttributeDescription()
        ptSubjectIdAttr.name = "subjectId"
        ptSubjectIdAttr.attributeType = .stringAttributeType
        ptSubjectIdAttr.isOptional = false

        let ptUserIdAttr = NSAttributeDescription()
        ptUserIdAttr.name = "userId"
        ptUserIdAttr.attributeType = .stringAttributeType
        ptUserIdAttr.isOptional = false

        let ptOrderAttr = NSAttributeDescription()
        ptOrderAttr.name = "order"
        ptOrderAttr.attributeType = .integer32AttributeType
        ptOrderAttr.isOptional = false

        let ptTitleAttr = NSAttributeDescription()
        ptTitleAttr.name = "title"
        ptTitleAttr.attributeType = .stringAttributeType
        ptTitleAttr.isOptional = false

        let ptDescAttr = NSAttributeDescription()
        ptDescAttr.name = "description_"
        ptDescAttr.attributeType = .stringAttributeType
        ptDescAttr.isOptional = false

        let ptSubtopicsAttr = NSAttributeDescription()
        ptSubtopicsAttr.name = "subtopics"
        ptSubtopicsAttr.attributeType = .transformableAttributeType
        ptSubtopicsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        ptSubtopicsAttr.isOptional = false

        let ptWeightAttr = NSAttributeDescription()
        ptWeightAttr.name = "weightPercent"
        ptWeightAttr.attributeType = .integer32AttributeType
        ptWeightAttr.isOptional = false

        let ptHoursAttr = NSAttributeDescription()
        ptHoursAttr.name = "estimatedHours"
        ptHoursAttr.attributeType = .integer32AttributeType
        ptHoursAttr.isOptional = false

        let ptResourceIdsAttr = NSAttributeDescription()
        ptResourceIdsAttr.name = "resourceIds"
        ptResourceIdsAttr.attributeType = .transformableAttributeType
        ptResourceIdsAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        ptResourceIdsAttr.isOptional = false

        let ptCompletionAttr = NSAttributeDescription()
        ptCompletionAttr.name = "completionPercent"
        ptCompletionAttr.attributeType = .doubleAttributeType
        ptCompletionAttr.isOptional = false

        let ptCompletedAttr = NSAttributeDescription()
        ptCompletedAttr.name = "isCompleted"
        ptCompletedAttr.attributeType = .booleanAttributeType
        ptCompletedAttr.isOptional = false

        let ptGeneratedAtAttr = NSAttributeDescription()
        ptGeneratedAtAttr.name = "generatedAt"
        ptGeneratedAtAttr.attributeType = .dateAttributeType
        ptGeneratedAtAttr.isOptional = false

        let ptSyncAttr = NSAttributeDescription()
        ptSyncAttr.name = "syncStatus"
        ptSyncAttr.attributeType = .stringAttributeType
        ptSyncAttr.isOptional = false

        pathTopicEntity.properties = [
            ptIdAttr, ptSubjectIdAttr, ptUserIdAttr, ptOrderAttr, ptTitleAttr,
            ptDescAttr, ptSubtopicsAttr, ptWeightAttr, ptHoursAttr, ptResourceIdsAttr,
            ptCompletionAttr, ptCompletedAttr, ptGeneratedAtAttr, ptSyncAttr
        ]
        
        // CDQuizAttempt
        let quizAttemptEntity = NSEntityDescription()
        quizAttemptEntity.name = "CDQuizAttempt"
        quizAttemptEntity.managedObjectClassName = NSStringFromClass(CDQuizAttempt.self)

        let qaIdAttr = NSAttributeDescription()
        qaIdAttr.name = "id"
        qaIdAttr.attributeType = .stringAttributeType
        qaIdAttr.isOptional = false

        let qaSubjectIdAttr = NSAttributeDescription()
        qaSubjectIdAttr.name = "subjectId"
        qaSubjectIdAttr.attributeType = .stringAttributeType
        qaSubjectIdAttr.isOptional = false

        let qaUserIdAttr = NSAttributeDescription()
        qaUserIdAttr.name = "userId"
        qaUserIdAttr.attributeType = .stringAttributeType
        qaUserIdAttr.isOptional = false

        let qaQuizNameAttr = NSAttributeDescription()
        qaQuizNameAttr.name = "quizName"
        qaQuizNameAttr.attributeType = .stringAttributeType
        qaQuizNameAttr.isOptional = false

        let qaTopicNameAttr = NSAttributeDescription()
        qaTopicNameAttr.name = "topicName"
        qaTopicNameAttr.attributeType = .stringAttributeType
        qaTopicNameAttr.isOptional = false

        let qaQuestionsDataAttr = NSAttributeDescription()
        qaQuestionsDataAttr.name = "questionsData"
        qaQuestionsDataAttr.attributeType = .binaryDataAttributeType
        qaQuestionsDataAttr.isOptional = false

        let qaSelectedAnswersDataAttr = NSAttributeDescription()
        qaSelectedAnswersDataAttr.name = "selectedAnswersData"
        qaSelectedAnswersDataAttr.attributeType = .binaryDataAttributeType
        qaSelectedAnswersDataAttr.isOptional = false

        let qaScorePercentAttr = NSAttributeDescription()
        qaScorePercentAttr.name = "scorePercent"
        qaScorePercentAttr.attributeType = .integer32AttributeType
        qaScorePercentAttr.isOptional = false

        let qaTimeSpentAttr = NSAttributeDescription()
        qaTimeSpentAttr.name = "timeSpentSeconds"
        qaTimeSpentAttr.attributeType = .integer32AttributeType
        qaTimeSpentAttr.isOptional = false

        let qaCompletedAtAttr = NSAttributeDescription()
        qaCompletedAtAttr.name = "completedAt"
        qaCompletedAtAttr.attributeType = .dateAttributeType
        qaCompletedAtAttr.isOptional = false

        let qaSyncStatusAttr = NSAttributeDescription()
        qaSyncStatusAttr.name = "syncStatus"
        qaSyncStatusAttr.attributeType = .stringAttributeType
        qaSyncStatusAttr.isOptional = false

        quizAttemptEntity.properties = [
            qaIdAttr, qaSubjectIdAttr, qaUserIdAttr, qaQuizNameAttr, qaTopicNameAttr,
            qaQuestionsDataAttr, qaSelectedAnswersDataAttr, qaScorePercentAttr,
            qaTimeSpentAttr, qaCompletedAtAttr, qaSyncStatusAttr
        ]

        let availabilitySlotEntity = NSEntityDescription()
        availabilitySlotEntity.name = "CDAvailabilitySlot"
        availabilitySlotEntity.managedObjectClassName = NSStringFromClass(CDAvailabilitySlot.self)
        availabilitySlotEntity.properties = [
            attr("id", .stringAttributeType),
            attr("userId", .stringAttributeType),
            attr("type", .stringAttributeType),
            attr("startTime", .dateAttributeType),
            attr("endTime", .dateAttributeType),
            attr("date", .dateAttributeType, optional: true),
            attr("rangeStart", .dateAttributeType, optional: true),
            attr("rangeEnd", .dateAttributeType, optional: true),
            attr("label", .stringAttributeType, optional: true),
            attr("createdAt", .dateAttributeType),
            attr("updatedAt", .dateAttributeType),
            attr("syncStatus", .stringAttributeType)
        ]

        let studySessionEntity = NSEntityDescription()
        studySessionEntity.name = "CDStudySession"
        studySessionEntity.managedObjectClassName = NSStringFromClass(CDStudySession.self)
        studySessionEntity.properties = [
            attr("id", .stringAttributeType),
            attr("userId", .stringAttributeType),
            attr("subjectId", .stringAttributeType),
            attr("subjectName", .stringAttributeType),
            attr("subjectColorHex", .stringAttributeType),
            attr("title", .stringAttributeType),
            attr("topic", .stringAttributeType),
            attr("notes", .stringAttributeType, optional: true),
            attr("scheduledDate", .dateAttributeType),
            attr("startTime", .dateAttributeType),
            attr("endTime", .dateAttributeType),
            attr("actualDurationMinutes", .integer64AttributeType, optional: true),
            attr("status", .stringAttributeType),
            attr("sessionType", .stringAttributeType),
            attr("hasReminder", .booleanAttributeType),
            attr("linkedDeadlineId", .stringAttributeType, optional: true),
            attr("linkedPlanId", .stringAttributeType, optional: true),
            transformableAttr("resourceIds"),
            transformableAttr("topicIds"),
            attr("rating", .integer64AttributeType, optional: true),
            attr("externalCalendarEventId", .stringAttributeType, optional: true),
            attr("createdAt", .dateAttributeType),
            attr("updatedAt", .dateAttributeType),
            attr("syncStatus", .stringAttributeType)
        ]

        let deadlineEntity = NSEntityDescription()
        deadlineEntity.name = "CDDeadline"
        deadlineEntity.managedObjectClassName = NSStringFromClass(CDDeadline.self)
        deadlineEntity.properties = [
            attr("id", .stringAttributeType),
            attr("userId", .stringAttributeType),
            attr("subjectId", .stringAttributeType),
            attr("subjectColorHex", .stringAttributeType),
            attr("name", .stringAttributeType),
            attr("dueDate", .dateAttributeType),
            attr("hasReminder", .booleanAttributeType),
            attr("isHighPriority", .booleanAttributeType),
            attr("notes", .stringAttributeType),
            attr("tag", .stringAttributeType),
            attr("priority", .stringAttributeType),
            attr("status", .stringAttributeType),
            attr("reminderDate", .dateAttributeType, optional: true),
            transformableAttr("linkedSessionIds"),
            attr("notificationId", .stringAttributeType, optional: true),
            attr("createdAt", .dateAttributeType),
            attr("updatedAt", .dateAttributeType),
            attr("syncStatus", .stringAttributeType)
        ]

        model.entities = [
            userEntity,
            settingsEntity,
            subjectEntity,
            resourceEntity,
            pathTopicEntity,
            quizAttemptEntity,
            availabilitySlotEntity,
            studySessionEntity,
            deadlineEntity
        ]
        
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
