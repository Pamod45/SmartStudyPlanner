//
//  UserService.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-13.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreData

// Manages the user's app profile and settings in Firestore.
// Every successful fetch or save also updates Core Data so the app has a local cache.

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    func createUserProfile(_ user: AppUser) async throws {
        try await db.collection("users").document(user.id).setData(user.firestoreData)
        CoreDataService.shared.cacheProfile(user)

        var settings = UserSettings.default
        settings.userId = user.id
        settings.id = user.id
        try await createUserSettings(settings)
    }
    
    func fetchUserProfile(userId: String) async throws -> AppUser {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data(), let user = AppUser(from: data, uid: userId) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        CoreDataService.shared.cacheProfile(user)
        return user
    }
    
    func updateProfile(user: AppUser) async throws {
        try await db.collection("users").document(user.id).setData(user.firestoreData, merge: true)
        CoreDataService.shared.cacheProfile(user)
    }

    func createUserSettings(_ settings: UserSettings) async throws {
        try await db.collection("userSettings").document(settings.userId).setData(settings.firestoreData)
        CoreDataService.shared.cacheSettings(settings)
    }

    func fetchUserSettings(userId: String) async throws -> UserSettings {
        let doc = try await db.collection("userSettings").document(userId).getDocument()
        guard let data = doc.data(), let settings = UserSettings(from: data, userId: userId) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User settings not found"])
        }
        CoreDataService.shared.cacheSettings(settings)
        return settings
    }

    func updateSettings(_ settings: UserSettings) async throws {
        try await db.collection("userSettings").document(settings.userId).setData(settings.firestoreData, merge: true)
        CoreDataService.shared.cacheSettings(settings)
    }
}
