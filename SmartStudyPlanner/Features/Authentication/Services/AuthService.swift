//
//  AuthService.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-13.
//

import Foundation
import FirebaseAuth
import UIKit
import GoogleSignIn
import FirebaseCore

// Handles authentication with Firebase Auth and Google Sign-In.
// Firestore/Core Data profile work is delegated to UserService.

struct ActiveDeviceSession: Identifiable {
    let id: String
    let userId: String
    let deviceName: String
    let osVersion: String
    let lastActive: Date
    let isCurrentDevice: Bool
}

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    // Signs in with Firebase Auth, then loads the matching app profile.
    // If the Auth user exists but the Firestore profile is missing, a basic profile is created.
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
            try await UserService.shared.createUserProfile(appUser)
            return appUser
        }
    }
    
    // Creates a Firebase Auth account and then creates the app profile used by the rest of the app.
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
    
    @MainActor
    // Opens the Google Sign-In UI, converts the Google tokens into a Firebase credential,
    // then loads or creates the app profile for that Firebase user.
    func signInWithGoogle(presentingViewController: UIViewController) async throws -> AppUser {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Client ID found"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token"])
        }
        let accessToken = user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user
        
        do {
            let appUser = try await UserService.shared.fetchUserProfile(userId: firebaseUser.uid)
            return appUser
        } catch {
            let appUser = AppUser(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName ?? user.profile?.name ?? "User"
            )
            try await UserService.shared.createUserProfile(appUser)
            return appUser
        }
    }

    // Ends the Firebase session and clears local cached data for the signed-out user.
    func signOut() throws {
        try Auth.auth().signOut()
        CoreDataService.shared.clearCache()
    }
        
    func changePassword(newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        try await user.updatePassword(to: newPassword)
    }

    // Sends Firebase's reset-password email. The actual password change happens from the link in that email.
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // Currently returns only this device. A real multi-device list would need saved
    // session records in Firestore.
    func fetchActiveSessions() async throws -> [ActiveDeviceSession] {
        guard let user = Auth.auth().currentUser else { return [] }
        return [
            ActiveDeviceSession(
                id: UUID().uuidString,
                userId: user.uid,
                deviceName: UIDevice.current.name,
                osVersion: UIDevice.current.systemVersion,
                lastActive: Date(),
                isCurrentDevice: true
            )
        ]
    }
    
    func revokeAllSessions() async throws {
        try signOut()
    }
    
    // Restores the app user from Firebase's current local auth session.
    // The profile is read from Core Data first, then Firestore if the cache is missing.
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
