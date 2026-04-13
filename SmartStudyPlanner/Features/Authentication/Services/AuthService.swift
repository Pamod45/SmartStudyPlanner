//
//  AuthService.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-13.
//

import Foundation
import FirebaseAuth

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    func signIn(email: String, password: String) async throws -> AppUser {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = authResult.user
        
        do {
            let appUser = try await UserService.shared.fetchUserProfile(userId: user.uid)
            return appUser
        } catch {
            let appUser = AppUser(
                id: user.uid,
                email: email,
                displayName: user.displayName ?? "User"
            )
            CoreDataService.shared.cacheProfile(appUser)
            return appUser
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws -> AppUser {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authResult.user
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        
        let appUser = AppUser(
            id: user.uid,
            email: email,
            displayName: name
        )
        
        try await UserService.shared.createUserProfile(appUser)
        return appUser
    }
    

    func signOut() throws {
        try Auth.auth().signOut()
        CoreDataService.shared.clearCache()
    }
    
    func getCurrentUser() async -> AppUser? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }
        
        if let cachedUser = CoreDataService.shared.getCachedProfile(), cachedUser.id == user.uid {
            return cachedUser
        }
        
        do {
            return try await UserService.shared.fetchUserProfile(userId: user.uid)
        } catch {
            return nil
        }
    }
}
