//
//  SecurityView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

// Handles security preferences that are local to this device, like Face ID unlock.
struct SecurityView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localSettings: LocalSettingsManager

    @State private var showChangePassword: Bool = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var securityMessage: SecurityMessage? = nil

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.lg)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.md) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Face ID Authentication")
                                    .font(theme.typography.bodyLarge.weight(.semibold))
                                    .foregroundColor(theme.colors.textPrimary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { localSettings.faceIDEnabled },
                                    set: { newValue in
                                        if newValue {
                                            // Turning Face ID on requires a successful biometric check first.
                                            localSettings.requestBiometricAuth { success in
                                                if success {
                                                    localSettings.faceIDEnabled = true
                                                }
                                            }
                                        } else {
                                            localSettings.faceIDEnabled = false
                                        }
                                    }
                                ))
                                    .labelsHidden()
                                    .tint(theme.colors.primary)
                            }
                            .padding(.horizontal, theme.spacing.md)
                            .padding(.vertical, theme.spacing.md)

                            rowDivider

                            navRow(title: "Change Password") {
                                showChangePassword = true
                            }

                        }
                        .background(theme.colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Change Password", isPresented: $showChangePassword) {
            SecureField("New password", text: $newPassword)
            SecureField("Confirm password", text: $confirmPassword)
            Button("Update") {
                Task { await submitPasswordChange() }
            }
            Button("Cancel", role: .cancel) {
                clearPasswordFields()
            }
        } message: {
            Text("Enter a new password with at least 6 characters.")
        }
        .alert(item: $securityMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.body),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var header: some View {
        HStack {
            RoundedIconButton(icon: "chevron.left") { dismiss() }
            Spacer()
            Text("Security")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon: "chevron.left") {}.opacity(0)
        }
    }

    private func navRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(theme.typography.bodySmall.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Divider().background(theme.colors.border.opacity(0.4)).padding(.leading, theme.spacing.md)
    }

    private func submitPasswordChange() async {
        let password = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmation = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard password.count >= 6 else {
            securityMessage = SecurityMessage(title: "Password Too Short", body: "Please use at least 6 characters.")
            return
        }

        guard password == confirmation else {
            securityMessage = SecurityMessage(title: "Passwords Do Not Match", body: "Please confirm the same password.")
            return
        }

        do {
            try await AuthService.shared.changePassword(newPassword: password)
            clearPasswordFields()
            securityMessage = SecurityMessage(title: "Password Updated", body: "Your password has been changed successfully.")
        } catch {
            securityMessage = SecurityMessage(
                title: "Could Not Change Password",
                body: "\(error.localizedDescription)\n\nIf Firebase asks for a recent login, log out, sign in again, and retry."
            )
        }
    }

    private func clearPasswordFields() {
        newPassword = ""
        confirmPassword = ""
    }
}

private struct SecurityMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

#Preview {
    NavigationStack { SecurityView() }
        .environmentObject(ThemeManager())
        .environmentObject(LocalSettingsManager())
        .environment(\.theme, AppTheme.defaultTheme)
}
