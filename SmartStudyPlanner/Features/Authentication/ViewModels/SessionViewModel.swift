import Combine

import Foundation
import SwiftUI

@MainActor
class SessionViewModel: ObservableObject {
    @Published var session: UserSession = .unauthenticated
    @Published var isLoading: Bool = true

    var isGuest: Bool { session.isGuest }
    var isAuthenticated: Bool { session.isAuthenticated }
    var currentUser: AppUser? { session.currentUser }
    var activeUserId: String? { session.activeUserId }

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
