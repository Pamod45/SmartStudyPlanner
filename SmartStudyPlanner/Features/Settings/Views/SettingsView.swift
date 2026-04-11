//
//  SettingsView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-11.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) var theme

    @State private var notificationsEnabled: Bool = true
    @State private var darkModeEnabled: Bool = true
    @State private var showStudyGoals: Bool = false
    @State private var showIntegrations: Bool = false
    @State private var showSecurity: Bool = false
    @State private var showAccessibility: Bool = false
    @State private var showFAQ: Bool = false
    @State private var showTerms: Bool = false
    @State private var showGeneralNotifications: Bool = false
    @State private var showLogOutConfirm: Bool = false

    private let user = SettingsUser(name: "Pubudu Perera", degree: "Software Engineering")

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)
                    .overlay(
                        Rectangle()
                            .fill(theme.colors.border.opacity(0.3))
                            .frame(height: 1),
                        alignment: .bottom
                    )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.md) {
                        profileCard
                        notificationsSection
                        preferencesSection
                        supportSection
                        logOutButton
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Log Out", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
        }
    }

    private var profileCard: some View {
        Button {
        } label: {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(theme.colors.onSurface)
                        .frame(width: 56, height: 56)
                    Image(systemName: user.avatarSystemImage)
                        .font(.system(size: 28))
                        .foregroundColor(theme.colors.textSecondary)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(user.name)
                        .font(theme.typography.headingSmall)
                        .foregroundColor(theme.colors.textPrimary)
                    Text(user.degree)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(theme.typography.bodyMedium.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.xl)
                    .stroke(theme.colors.border.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var notificationsSection: some View {
        settingsGroup(rows: [
            AnyView(settingsToggleRow(
                icon: "bell.badge",
                iconColor: theme.colors.textSecondary,
                title: "Notifications",
                isOn: $notificationsEnabled
            )),
            AnyView(settingsNavRow(
                icon: "gearshape",
                iconColor: theme.colors.textSecondary,
                title: "General notifications"
            ) {
                showGeneralNotifications = true
            }),
            AnyView(settingsToggleRow(
                icon: "moon",
                iconColor: theme.colors.textSecondary,
                title: "Dark mode",
                isOn: $darkModeEnabled
            ))
        ])
    }

    private var preferencesSection: some View {
        settingsGroup(rows: [
            AnyView(settingsNavRow(
                icon: "target",
                iconColor: theme.colors.textSecondary,
                title: "Study Goals"
            ) {
                showStudyGoals = true
            }),
            AnyView(settingsNavRow(
                icon: "puzzlepiece",
                iconColor: theme.colors.textSecondary,
                title: "Integrations & Widgets"
            ) {
                showIntegrations = true
            }),
            AnyView(settingsNavRow(
                icon: "lock",
                iconColor: theme.colors.textSecondary,
                title: "Security"
            ) {
                showSecurity = true
            }),
            AnyView(settingsNavRow(
                icon: "figure.walk",
                iconColor: theme.colors.textSecondary,
                title: "Accessibility"
            ) {
                showAccessibility = true
            })
        ])
    }

    private var supportSection: some View {
        settingsGroup(rows: [
            AnyView(settingsNavRow(
                icon: "questionmark.circle",
                iconColor: theme.colors.textSecondary,
                title: "FAQ"
            ) {
                showFAQ = true
            }),
            AnyView(settingsNavRow(
                icon: "doc.text",
                iconColor: theme.colors.textSecondary,
                title: "Terms of service"
            ) {
                showTerms = true
            })
        ])
    }

    private var logOutButton: some View {
        Button {
            showLogOutConfirm = true
        } label: {
            HStack(spacing: theme.spacing.m) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.error)
                Text("Log out")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.error)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.error.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.colors.error.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func settingsGroup(rows: [AnyView]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                row

                if index < rows.count - 1 {
                    Divider()
                        .background(theme.colors.border.opacity(0.4))
                        .padding(.leading, 56)
                }
            }
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(theme.colors.border.opacity(0.4), lineWidth: 1)
        )
    }

    private func settingsToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: theme.spacing.md) {
            iconBadge(icon: icon, color: iconColor)

            Text(title)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.colors.primary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.m)
    }

    private func settingsNavRow(
        icon: String,
        iconColor: Color,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.md) {
                iconBadge(icon: icon, color: iconColor)

                Text(title)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(theme.typography.bodySmall.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.m)
        }
        .buttonStyle(.plain)
    }

    private func iconBadge(icon: String, color: Color) -> some View {
        ZStack {
//            RoundedRectangle(cornerRadius: theme.radius.sm)
//                .fill(color.opacity(0.15))
//                .frame(width: 34, height: 34)
//            RoundedRectangle(cornerRadius: theme.radius.sm)
//                .stroke(color.opacity(0.3), lineWidth: 1)
//                .frame(width: 34, height: 34)
            Image(systemName: icon)
                .frame(width: 40, height: 30)
                .font(theme.typography.headingSmall)
                .foregroundColor(color)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(ThemeManager())
    .environment(\.theme, AppTheme.defaultTheme)
}
