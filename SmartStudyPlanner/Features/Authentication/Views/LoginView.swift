//
//  LoginView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var localSettings: LocalSettingsManager
    @StateObject private var vm = AuthViewModel()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp = false
    @State private var showPasswordResetConfirmation = false

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
        .alert("Password Reset", isPresented: $showPasswordResetConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("If an account exists for this email, Firebase will send a password reset link.")
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
            InputField(icon: "envelope", placeholder: "Email Address", fieldType: .email, value: $email)
            
            InputField(icon: "lock", placeholder: "Password", fieldType: .password, value: $password)
        }
    }

    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            TextButton(title: "Forgot the password?") {
                let resetEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                guard resetEmail.contains("@"), resetEmail.contains(".") else {
                    vm.errorMessage = "Please enter your email address first."
                    return
                }

                Task {
                    let didSend = await vm.resetPassword(email: resetEmail)
                    if didSend {
                        showPasswordResetConfirmation = true
                    }
                }
            }
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
            RoundedIconButton(icon: "g.circle.fill"){
                guard let rootVC = Utilities.shared.topViewController() else { return }
                Task {
                    await vm.signInWithGoogle(presentingViewController: rootVC) { user in
                        if let user = user {
                            sessionViewModel.signIn(user: user)
                        }
                    }
                }
            }
            RoundedIconButton(icon: "faceid"){
                guard localSettings.faceIDEnabled else {
                    vm.errorMessage = "Face ID is not enabled in settings."
                    return
                }

                localSettings.authenticateWithBiometrics { success in
                    guard success else {
                        vm.errorMessage = "Face ID authentication failed."
                        return
                    }

                    Task {
                        await vm.signInWithFaceID { user in
                            if let user = user {
                                sessionViewModel.signIn(user: user)
                            }
                        }
                    }
                }
            }
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

class Utilities {
    static let shared = Utilities()
    private init() {}
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let rootVC = controller ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController

        if let navigationController = rootVC as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = rootVC as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = rootVC?.presentedViewController {
            return topViewController(controller: presented)
        }
        return rootVC
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(\.theme, AppTheme.defaultTheme)
            .environmentObject(SessionViewModel())
            .environmentObject(LocalSettingsManager())
    }
}
