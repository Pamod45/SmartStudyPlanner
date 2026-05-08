import Foundation

enum UserSessionState {
    case unauthenticated
    case guest
    case authenticated(AppUser)
}

struct UserSession {
    var sessionState: UserSessionState
    var guestId: String?
    var lastActiveAt: Date

    var isGuest: Bool {
        if case .guest = sessionState { return true }
        return false
    }

    var isAuthenticated: Bool {
        if case .authenticated = sessionState { return true }
        return false
    }

    var currentUser: AppUser? {
        if case .authenticated(let user) = sessionState { return user }
        return nil
    }

    var activeUserId: String? {
        return currentUser?.id ?? guestId
    }

    init(sessionState: UserSessionState = .unauthenticated, guestId: String? = nil, lastActiveAt: Date = Date()) {
        self.sessionState = sessionState
        self.guestId = guestId
        self.lastActiveAt = lastActiveAt
    }

    static var guest: UserSession {
        UserSession(sessionState: .guest, guestId: UUID().uuidString, lastActiveAt: Date())
    }

    static var unauthenticated: UserSession {
        UserSession(sessionState: .unauthenticated)
    }
}
