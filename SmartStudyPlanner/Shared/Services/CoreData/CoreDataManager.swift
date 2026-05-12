import CoreData
import Foundation

// Core Data schema in code instead of using an .xcdatamodeld file.
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
    @NSManaged public var deadlineReminderHoursBefore: Int   
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

public class CoreDataManager {
    public static let shared = CoreDataManager()
    
    // Resets the local cache if the database structure changes drastically during development
    private func destroyPersistentStore() {
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SmartStudyPlanner.sqlite")
        
        try? FileManager.default.removeItem(at: storeURL)
        try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite-shm"))
        try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite-wal"))
    }

    public lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "SmartStudyPlanner")
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("SmartStudyPlanner.sqlite")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
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
    
    // Saves the shared view context and rolls back pending local changes if Core Data rejects the save.
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
