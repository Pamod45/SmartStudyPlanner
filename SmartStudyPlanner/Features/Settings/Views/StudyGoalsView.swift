//
//  StudyGoalsView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

// Updates goal settings used by Progress calculations and reminder scheduling.
struct StudyGoalsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: SettingsViewModel

    private let studyTimes = ["Morning", "Afternoon", "Evening", "Night"]

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
                        FieldSection(title: "STUDY GOALS") {
                            VStack(spacing: 0) {
                                sliderRow
                                rowDivider
                                menuRow
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                            .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
                        }
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
            Text("Study Goals")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon: "chevron.left") {}.opacity(0)
        }
    }

    private var sliderRow: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text("Daily Goal")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text(String(format: "%.1f hrs", vm.settings.dailyStudyGoalHours))
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Slider(value: vm.binding(for: \.dailyStudyGoalHours), in: 0.5...12, step: 0.5)
                .tint(theme.colors.primary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
    }

    private var menuRow: some View {
        HStack {
            Text("Preferred Study Time")
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Menu {
                ForEach(studyTimes, id: \.self) { time in
                    Button(time) { vm.updateSettings { $0.preferredStudyTime = time } }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(vm.settings.preferredStudyTime)
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

    private var rowDivider: some View {
        Divider().background(theme.colors.border.opacity(0.4)).padding(.leading, theme.spacing.md)
    }
}

#Preview {
    NavigationStack { StudyGoalsView() }
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
        .environment(\.theme, AppTheme.defaultTheme)
}
