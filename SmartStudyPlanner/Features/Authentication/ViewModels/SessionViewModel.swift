import Combine

import Foundation
import SwiftUI

// Owns the app's current session state. Firebase handles authentication, while this
// view model decides whether SwiftUI should show login, guest mode, or the main app.

@MainActor
class SessionViewModel: ObservableObject {
    @Published var session: UserSession = .unauthenticated
    @Published var isLoading: Bool = true

    var isGuest: Bool { session.isGuest }
    var isAuthenticated: Bool { session.isAuthenticated }
    var currentUser: AppUser? { session.currentUser }
    var activeUserId: String? { session.activeUserId }

    // Called on app launch to rebuild the in-app session from Firebase's saved auth state.
    func restoreSession() async {
        isLoading = true
        if let user = await AuthService.shared.getCurrentUser() {
            signIn(user: user)
        } else {
            session = .unauthenticated
        }
        isLoading = false
    }

    func continueAsGuest() {
        session = .guest
    }

    func signIn(user: AppUser) {
        session = UserSession(sessionState: .authenticated(user), lastActiveAt: Date())
    }

    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
        AIMessageStore.shared.clearAll()
        session = .unauthenticated
    }
}
