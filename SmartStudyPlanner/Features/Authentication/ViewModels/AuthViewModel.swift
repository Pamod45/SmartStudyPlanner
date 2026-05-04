import Combine

//
//  AuthViewModel.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-13.
//


import Foundation
import SwiftUI

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
            
            // Save credentials for Face ID
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

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
    }
}
