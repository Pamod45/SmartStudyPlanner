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

public class CoreDataStack {
    public static let shared = CoreDataStack()
    
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
        model.entities = [userEntity]
        
        let container = NSPersistentContainer(name: "SmartStudyPlanner", managedObjectModel: model)
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data load error: \(error)")
            }
        }
        return container
    }()
    
    public var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
