//
//  SignUpScreen.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @StateObject private var vm = AuthViewModel()

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                Spacer().frame(height: theme.spacing.xxl)

                VStack(spacing: theme.spacing.md) {
                    InputField(
                        icon: "person",
                        placeholder: "Your Name",
                        fieldType: .text,
                        value: $name
                    )

                    InputField(
                        icon: "envelope",
                        placeholder: "Email Address",
                        fieldType: .email,
                        value: $email
                    )

                    InputField(
                        icon: "lock",
                        placeholder: "Password",
                        fieldType: .password,
                        value: $password
                    )

                    InputField(
                        icon: "lock",
                        placeholder: "Confirm Password",
                        fieldType: .password,
                        value: $confirmPassword
                    )
                }

                if let err = vm.errorMessage {
                    Text(err)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.top, theme.spacing.sm)
                }

                Spacer().frame(height: theme.spacing.lg)

                PrimaryButton(title: vm.isLoading ? "Signing Up..." : "Sign Up") {
                    guard password == confirmPassword else {
                        vm.errorMessage = "Passwords do not match."
                        return
                    }
                    guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                        vm.errorMessage = "All fields are required."
                        return
                    }
                    Task {
                        await vm.signUp(name: name, email: email, password: password) { user in
                            if let user = user {
                                sessionViewModel.signIn(user: user)
                            }
                        }
                    }
                }
                .disabled(vm.isLoading)

                Spacer().frame(height: theme.spacing.lg)

                OrDivider()

                Spacer().frame(height: theme.spacing.lg)

                HStack(spacing: theme.spacing.lg) {
                    RoundedIconButton(icon: "g.circle.fill") {}
//                    RoundedIconButton(icon: "apple.logo") {}
                    RoundedIconButton(icon: "faceid") {}
                }

                Spacer().frame(height: theme.spacing.lg)

                TextButton(title: "Continue as Guest") {
                    sessionViewModel.continueAsGuest()
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.xl)
        }
        .navigationBarHidden(true)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            TextButton(
                title: "Back",
                icon: "arrow.left",
                action: {
                    dismiss()
                }
            )
            
            Text("Create your\nAccount")
                .font(theme.typography.displayMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.lg)
    }
}

#Preview {
    SignUpView()
        .environment(\.theme, AppTheme.defaultTheme)
        .environmentObject(SessionViewModel())
}
