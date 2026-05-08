import Foundation

enum AuthProvider: String, Codable {
    case email
    case google
    case apple
    case guest
}

struct AppUser: Identifiable, Codable {
    var id: String
    var email: String
    var displayName: String
    var domain: String?
    var institute: String?
    var username: String?
    var profileImageURL: String?
    var createdAt: Date
    var lastLoginAt: Date
    var isEmailVerified: Bool
    var fcmToken: String?
    var authProvider: AuthProvider
    var updatedAt: Date

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "displayName": displayName,
            "createdAt": createdAt,
            "lastLoginAt": lastLoginAt,
            "isEmailVerified": isEmailVerified,
            "authProvider": authProvider.rawValue,
            "updatedAt": updatedAt
        ]
        
        if let domain = domain { data["domain"] = domain }
        if let institute = institute { data["institute"] = institute }
        if let username = username { data["username"] = username }
        if let profileImageURL = profileImageURL { data["profileImageURL"] = profileImageURL }
        if let fcmToken = fcmToken { data["fcmToken"] = fcmToken }
        
        return data
    }

    init?(from data: [String: Any], uid: String) {
        guard
            let email = data["email"] as? String,
            let displayName = data["displayName"] as? String
        else { return nil }

        self.id = uid
        self.email = email
        self.displayName = displayName
        self.domain = data["domain"] as? String
        self.institute = data["institute"] as? String
        self.username = data["username"] as? String
        self.profileImageURL = data["profileImageURL"] as? String
        self.createdAt = (data["createdAt"] as? Date) ?? Date()
        self.lastLoginAt = (data["lastLoginAt"] as? Date) ?? Date()
        self.isEmailVerified = (data["isEmailVerified"] as? Bool) ?? false
        self.fcmToken = data["fcmToken"] as? String
        self.authProvider = AuthProvider(rawValue: data["authProvider"] as? String ?? "") ?? .email
        self.updatedAt = (data["updatedAt"] as? Date) ?? Date()
    }

    init(
        id: String,
        email: String,
        displayName: String,
        domain: String? = nil,
        institute: String? = nil,
        username: String? = nil,
        profileImageURL: String? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        isEmailVerified: Bool = false,
        fcmToken: String? = nil,
        authProvider: AuthProvider = .email,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.domain = domain
        self.institute = institute
        self.username = username
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.isEmailVerified = isEmailVerified
        self.fcmToken = fcmToken
        self.authProvider = authProvider
        self.updatedAt = updatedAt
    }
}
