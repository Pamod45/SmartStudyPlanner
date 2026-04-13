//
//  LoginView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @StateObject private var vm = AuthViewModel()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                
                logoSection

                Spacer().frame(height: theme.spacing.xxl)

                inputSection

                if let err = vm.errorMessage {
                    Text(err)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.top, theme.spacing.sm)
                }

                Spacer().frame(height: theme.spacing.md)

                forgotPasswordButton

                Spacer().frame(height: theme.spacing.lg)

                loginButton

                Spacer().frame(height: theme.spacing.xl)

                OrDivider()

                Spacer().frame(height: theme.spacing.xl)

                socialButtons

                Spacer().frame(height: theme.spacing.xl)

                continueAsGuestButton

                Spacer()

                signupPrompt
                    .padding(.bottom, theme.spacing.xl)
            }
            .padding(.horizontal, theme.spacing.xl)
        }
        .navigationDestination(isPresented: $showSignUp){
            SignUpView()
        }
        .navigationBarHidden(true)
        
    }

    private var logoSection: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "book.pages")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .foregroundColor(theme.colors.primary)

            VStack(spacing: theme.spacing.xs) {
                Text("Hi ! Welcome to")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textSecondary)

                Text("StudyPilot")
                    .font(theme.typography.displayMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineSpacing(4)
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: theme.spacing.md) {
            InputField(icon: "envelope", placeholder: "Email Address", fieldType: .text, value: $email)
            
            InputField(icon: "lock", placeholder: "Password", fieldType: .password, value: $password)
        }
    }

    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            TextButton(title: "Forgot the password?", ){}
        }
    }

    private var loginButton: some View {
        PrimaryButton(title: vm.isLoading ? "Logging in..." : "Login") {
            guard !email.isEmpty, !password.isEmpty else {
                vm.errorMessage = "Please enter email and password."
                return
            }
            Task {
                await vm.signIn(email: email, password: password) { user in
                    if let user = user {
                        sessionViewModel.signIn(user: user)
                    }
                }
            }
        }
        .disabled(vm.isLoading)
    }

    private var socialButtons: some View {
        HStack(spacing: theme.spacing.lg) {
            RoundedIconButton(icon: "g.circle.fill"){}
            RoundedIconButton(icon: "apple.logo"){}
            RoundedIconButton(icon: "faceid"){}
        }
    }

    private var continueAsGuestButton: some View {
        TextButton(title:"Continue as Guest") {
            sessionViewModel.continueAsGuest()
        }
    }

    private var signupPrompt: some View {
        HStack(spacing: theme.spacing.xs) {
            Text("Don't Have an Account?")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)

            TextButton(title: "Sign Up", style: .bold){
                showSignUp = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(\.theme, AppTheme.defaultTheme)
            .environmentObject(SessionViewModel())
    }
}
