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
