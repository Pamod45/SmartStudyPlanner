//
//  AppUser.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-13.
//

import Foundation

struct AppUser {
    let uid: String
    let name: String
    let email: String
    let createdAt: Date
    
    init(uid: String, name: String, email: String, createdAt: Date = Date()) {
        self.uid = uid
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }
}

extension AppUser {
    
    var firestoreData: [String: Any] {
        return [
            "uid": uid,
            "name": name,
            "email": email,
            "createdAt": createdAt
        ]
    }
    
    init?(from data: [String: Any], uid: String) {
        guard
            let name = data["name"] as? String,
            let email = data["email"] as? String
        else { return nil }
        
        self.uid = uid
        self.name = name
        self.email = email
        self.createdAt = (data["createdAt"] as? Date) ?? Date()
    }
}

