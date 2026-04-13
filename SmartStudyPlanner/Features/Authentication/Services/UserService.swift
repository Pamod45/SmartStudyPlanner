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

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    func createUserProfile(_ user: AppUser) async throws {
        try await db.collection("users").document(user.id).setData(user.firestoreData)
        CoreDataService.shared.cacheProfile(user)
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
}
