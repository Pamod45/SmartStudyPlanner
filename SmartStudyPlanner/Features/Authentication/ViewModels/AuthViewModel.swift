import Combine

//
//  AuthViewModel.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-13.
//


import Foundation
import SwiftUI

// Keeps authentication screen state and passes user actions to AuthService.
// Views use the completion closures to update the app session after login or signup.

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func signUp(name: String, email: String, password: String, completion: @escaping (AppUser?) -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signUp(email: email, password: password, name: name)
            isLoading = false
            completion(user)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            completion(nil)
        }
    }

    func signIn(email: String, password: String, completion: @escaping (AppUser?) -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signIn(email: email, password: password)
            UserDefaults.standard.set(email, forKey: "faceId_email")
            UserDefaults.standard.set(password, forKey: "faceId_password")
            
            isLoading = false
            completion(user)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            completion(nil)
        }
    }

    // Face ID only unlocks previously saved email/password credentials here.
    // The actual login still goes through the normal Firebase email/password flow.
    func signInWithFaceID(completion: @escaping (AppUser?) -> Void) async {
        guard let email = UserDefaults.standard.string(forKey: "faceId_email"),
              let password = UserDefaults.standard.string(forKey: "faceId_password") else {
            self.errorMessage = "No saved credentials for Face ID."
            completion(nil)
            return
        }
        await signIn(email: email, password: password, completion: completion)
    }

    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (AppUser?) -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signInWithGoogle(presentingViewController: presentingViewController)
            isLoading = false
            completion(user)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            completion(nil)
        }
    }

    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.resetPassword(email: email)
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
