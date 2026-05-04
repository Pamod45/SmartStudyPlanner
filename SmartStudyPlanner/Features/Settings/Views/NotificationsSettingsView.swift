//
//  NotificationsSettingsView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct NotificationsSettingsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: SettingsViewModel

    private let quizOptions: [(label: String, minutes: Int)] = [
        ("Immediately", 0),
        ("5 min after", 5),
        ("15 min after", 15),
        ("30 min after", 30)
    ]
    private let deadlineOptions: [(label: String, days: Int)] = [
        ("Same Day", 0),
        ("1 Day Before", 1),
        ("2 Days Before", 2),
        ("1 Week Before", 7)
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
                        FieldSection(title: "DAILY GOALS") {
                            settingsCard([
                                AnyView(toggleRow(title: "Daily Goal Alerts", isOn: vm.binding(for: \.dailyGoalAlertsEnabled))),
                                AnyView(timeRow(title: "Preferred Alert Time", time: vm.binding(for: \.dailyGoalAlertTime)))
                            ])
                        }
                        captionText("Receive a daily reminder to complete your study goals")

                        FieldSection(title: "STUDY SESSIONS") {
                            settingsCard([
                                AnyView(toggleRow(title: "Session Reminders", isOn: vm.binding(for: \.sessionRemindersEnabled))),
                                AnyView(timeRow(title: "Reminder Time", time: vm.binding(for: \.sessionReminderTime)))
                            ])
                        }
                        captionText("Get notified before when you need to start studying")

                        FieldSection(title: "QUIZZES") {
                            settingsCard([
                                AnyView(toggleRow(title: "Pending Quiz Reminders", isOn: vm.binding(for: \.quizzesPendingReminders))),
                                AnyView(menuRow(title: "Remind Me", options: quizOptions.map { $0.label }, selected: quizReminderLabel))
                            ])
                        }
                        captionText("Reminders to test your knowledge after a study session")

                        FieldSection(title: "DEADLINE") {
                            settingsCard([
                                AnyView(toggleRow(title: "Deadline Alerts", isOn: vm.binding(for: \.deadlineAlertsEnabled))),
                                AnyView(menuRow(title: "Alert Time", options: deadlineOptions.map { $0.label }, selected: deadlineReminderLabel))
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

    private var deadlineReminderLabel: Binding<String> {
        Binding(
            get: {
                deadlineOptions.first(where: { $0.days == vm.settings.deadlineReminderDaysBefore })?.label ?? deadlineOptions[0].label
            },
            set: { newValue in
                if let days = deadlineOptions.first(where: { $0.label == newValue })?.days {
                    vm.updateSettings { $0.deadlineReminderDaysBefore = days }
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
