//
//  NotificationsSettingsView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: SettingsViewModel

    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    private let sessionMinuteOptions: [(label: String, minutes: Int)] = [
        ("5 min before",  5),
        ("10 min before", 10),
        ("30 min before", 30),
        ("1 hour before", 60)
    ]

    private let quizOptions: [(label: String, minutes: Int)] = [
        ("Immediately", 0),
        ("5 min after",  5),
        ("15 min after", 15),
        ("30 min after", 30)
    ]

    private let deadlineHourOptions: [(label: String, hours: Int)] = [
        ("1 hour before",  1),
        ("3 hours before", 3),
        ("24 hours before (1 day)", 24),
        ("3 days before", 72),
        ("1 week before", 168)
    ]

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

                        if authStatus == .denied {
                            permissionDeniedBanner
                        }

                        FieldSection(title: "STUDY SESSIONS") {
                            settingsCard([
                                AnyView(toggleRow(title: "Session Reminders", isOn: vm.binding(for: \.sessionRemindersEnabled))),
                                AnyView(menuRow(
                                    title: "Remind Me",
                                    options: sessionMinuteOptions.map { $0.label },
                                    selected: sessionReminderLabel
                                ))
                            ])
                        }
                        captionText("Get notified before your session starts")

                        FieldSection(title: "DEADLINE") {
                            settingsCard([
                                AnyView(toggleRow(title: "Deadline Alerts", isOn: vm.binding(for: \.deadlineAlertsEnabled))),
                                AnyView(menuRow(
                                    title: "Alert Me",
                                    options: deadlineHourOptions.map { $0.label },
                                    selected: deadlineHourLabel
                                ))
                            ])
                        }
                        captionText("Don't miss any upcoming exam or assignment")
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            authStatus = await NotificationService.shared.checkAuthorizationStatus()
        }
    }

    private var header: some View {
        HStack {
            RoundedIconButton(icon: "chevron.left") { dismiss() }
            Spacer()
            Text("Notifications")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon: "chevron.left") {}.opacity(0)
        }
    }


    private var permissionDeniedBanner: some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 22))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications Disabled")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Text("Enable notifications in iOS Settings to receive alerts.")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(theme.typography.caption.weight(.semibold))
            .foregroundColor(.orange)
        }
        .padding(theme.spacing.md)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func settingsCard(_ rows: [AnyView]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                row
                if i < rows.count - 1 {
                    Divider().background(theme.colors.border.opacity(0.4)).padding(.leading, theme.spacing.md)
                }
            }
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(theme.colors.primary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
    }

    private func timeRow(title: String, time: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(theme.colors.primary)
                .colorScheme(.dark)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.m)
    }

    private func menuRow(title: String, options: [String], selected: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selected.wrappedValue = opt }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selected.wrappedValue)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
    }

    private func captionText(_ text: String) -> some View {
        Text(text)
            .font(theme.typography.caption)
            .foregroundColor(theme.colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }


    private var sessionReminderLabel: Binding<String> {
        Binding(
            get: {
                sessionMinuteOptions.first(where: { $0.minutes == vm.settings.sessionReminderMinutesBefore })?.label
                    ?? sessionMinuteOptions[2].label  // default: 30 min
            },
            set: { newValue in
                if let minutes = sessionMinuteOptions.first(where: { $0.label == newValue })?.minutes {
                    vm.updateSettings { $0.sessionReminderMinutesBefore = minutes }
                }
            }
        )
    }

    private var quizReminderLabel: Binding<String> {
        Binding(
            get: {
                quizOptions.first(where: { $0.minutes == vm.settings.quizReminderMinutesAfter })?.label ?? quizOptions[0].label
            },
            set: { newValue in
                if let minutes = quizOptions.first(where: { $0.label == newValue })?.minutes {
                    vm.updateSettings { $0.quizReminderMinutesAfter = minutes }
                }
            }
        )
    }

    private var deadlineHourLabel: Binding<String> {
        Binding(
            get: {
                deadlineHourOptions.first(where: { $0.hours == vm.settings.deadlineReminderHoursBefore })?.label
                    ?? deadlineHourOptions[2].label  // default: 24 hours
            },
            set: { newValue in
                if let hours = deadlineHourOptions.first(where: { $0.label == newValue })?.hours {
                    vm.updateSettings { $0.deadlineReminderHoursBefore = hours }
                }
            }
        )
    }
}

#Preview {
    NavigationStack { NotificationsSettingsView() }
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
        .environment(\.theme, AppTheme.defaultTheme)
}
