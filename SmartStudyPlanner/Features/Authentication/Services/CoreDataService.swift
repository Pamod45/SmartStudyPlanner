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
    
    func clearCache() {
        let context = CoreDataStack.shared.context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDUserProfile")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try? context.execute(deleteRequest)
        CoreDataStack.shared.saveContext()
    }
}
