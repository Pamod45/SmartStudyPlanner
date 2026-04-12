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
    @State private var showProfile: Bool = false

    @State private var user = SettingsUser(
        name: "Pubudu Perera",
        email: "pubudu@gmail.com",
        domain: "Software Engineering",
        institute: "NIBM",
        username: "Pubudu@45"
    )


    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.lg)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.md) {
                        profileCard
                        notificationsSection
                        preferencesSection
                        supportSection
                        logOutButton
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
        .background(
            Group {
                NavigationLink(destination: ProfileEditView(user: $user), isActive: $showProfile) { EmptyView() }
                NavigationLink(destination: StudyGoalsView(), isActive: $showStudyGoals) { EmptyView() }
                NavigationLink(destination: NotificationsSettingsView(), isActive: $showGeneralNotifications) { EmptyView() }
                NavigationLink(destination: IntegrationsView(), isActive: $showIntegrations) { EmptyView() }
                NavigationLink(destination: SecurityView(), isActive: $showSecurity) { EmptyView() }
                NavigationLink(destination: AccessibilityView(), isActive: $showAccessibility) { EmptyView() }
            }
            .hidden()
        )
        .alert("Log Out", isPresented: $showLogOutConfirm) {
            Button("Log Out", role: .destructive) { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    private var headerSection: some View {
        HStack {
            EmptyView()
            Spacer()
            Text("Settings")
                .font(theme.typography.headingMedium.weight(.bold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            EmptyView()
        }
    }

    private var profileCard: some View {
        Button {
            showProfile = true
        } label: {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    if let img = user.avatarImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(theme.colors.onSurface)
                            .frame(width: 56, height: 56)
                        Image(systemName: "person.fill")
                            .font(.system(size: 26))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(theme.colors.border.opacity(0.4), lineWidth: 1)
                        .frame(width: 56, height: 56)
                )

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(user.name)
                        .font(theme.typography.headingSmall)
                        .foregroundColor(theme.colors.textPrimary)
                    Text(user.domain)
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
            .background(theme.colors.surface)
            .cornerRadius(theme.radius.xl)
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
