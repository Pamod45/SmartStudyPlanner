//
//  SecurityView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct SecurityView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var faceIDEnabled: Bool = true
    @State private var showSignOutAllConfirm: Bool = false

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
                                Toggle("", isOn: $faceIDEnabled).labelsHidden().tint(theme.colors.primary)
                            }
                            .padding(.horizontal, theme.spacing.md)
                            .padding(.vertical, theme.spacing.md)

                            rowDivider

                            navRow(title: "Change Password") {}

                            rowDivider

                            navRow(title: "Manage Active Devices") {}

                            rowDivider

                            Button {
                                showSignOutAllConfirm = true
                            } label: {
                                HStack {
                                    Text("Sign out from all devices")
                                        .font(theme.typography.bodyLarge.weight(.semibold))
                                        .foregroundColor(theme.colors.error)
                                    Spacer()
                                }
                                .padding(.horizontal, theme.spacing.md)
                                .padding(.vertical, theme.spacing.md)
                            }
                            .buttonStyle(.plain)
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
        .confirmationDialog("Sign Out All Devices", isPresented: $showSignOutAllConfirm, titleVisibility: .visible) {
            Button("Sign Out All", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be signed out from all devices.")
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
}

#Preview {
    NavigationStack { SecurityView() }
        .environmentObject(ThemeManager())
        .environment(\.theme, AppTheme.defaultTheme)
}
