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
                        fieldType: .text,
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

                Spacer().frame(height: theme.spacing.lg)

                PrimaryButton(title: "Sign Up") {}

                Spacer().frame(height: theme.spacing.lg)

                OrDivider()

                Spacer().frame(height: theme.spacing.lg)

                HStack(spacing: theme.spacing.lg) {
                    RoundedIconButton(icon: "g.circle.fill") {}
                    RoundedIconButton(icon: "apple.logo") {}
                    RoundedIconButton(icon: "faceid") {}
                }

                Spacer().frame(height: theme.spacing.lg)

                TextButton(title: "Continue as Guest") {}

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
}
