//
//  DashboardView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct DashboardView: View {
    @Environment(\.theme) var theme
    @StateObject private var vm = DashboardViewModel()

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
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        studySessionsSection
                        upcomingDeadlines
                        shortcutsSection
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.lg)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var headerSection: some View {
        HStack {
            HStack(spacing: theme.spacing.md) {
                Circle()
                    .fill(theme.colors.surface)
                    .frame(width: 44, height: 44)

                Text("Good Evening")
                    .font(theme.typography.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Spacer()

            NavigationLink {
                NotificationListView()
                    .environment(\.theme, theme)
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(theme.colors.primary)
            }
        }
    }

    private var studySessionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Today's Study Sessions", actionTitle: "ACTIVE")

            if vm.todaySessions.isEmpty {
                Text("No sessions scheduled for today")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, theme.spacing.sm)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.md) {
                        ForEach(vm.todaySessions) { session in
                            StudySessionCard(session: session) {}
                        }
                    }
                }
            }
        }
    }

    private var upcomingDeadlines: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Upcoming Deadlines", actionTitle: "View Calendar") {}

            if vm.upcomingDeadlines.isEmpty {
                Text("No upcoming deadlines")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, theme.spacing.sm)
            } else {
                VStack(spacing: theme.spacing.md) {
                    ForEach(vm.upcomingDeadlines) { deadline in
                        DeadlineCard(deadline: deadline, action: {})
                    }
                }
            }
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Smart Shortcuts")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: theme.spacing.md), GridItem(.flexible())], spacing: theme.spacing.md) {
                ForEach(vm.shortcuts) { shortcut in
                    ShortcutCard(shortcut: shortcut) {}
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.theme, AppTheme.defaultTheme)
}
