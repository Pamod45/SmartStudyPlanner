//
//  DashboardView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct DashboardView: View {
    @Environment(\.theme) var theme

    private let sessions: [StudySession] = {
        let cal = Calendar.current
        let today = Date()
        return [
            StudySession(
                subject: "iOS",
                title: "SwiftUI Layout",
                startTime: cal.date(bySettingHour: 19, minute: 30, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 20, minute: 15, second: 0, of: today)!,
                subjectColor: Color(hex: "#93C5FF")
            ),
            StudySession(
                subject: "Web API",
                title: "REST API",
                startTime: cal.date(bySettingHour: 20, minute: 30, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 21, minute: 0, second: 0, of: today)!,
                subjectColor: Color(hex: "#F9ABFF")
            )
        ]
    }()

    private let deadlines: [Deadline] = Deadline.dashboardSamples

    private let shortcuts: [Shortcut] = [
        Shortcut(title: "SCAN NOTES", icon: "doc.viewfinder", color: .blue),
        Shortcut(title: "IMPORT DOC", icon: "doc.badge.arrow.up", color: .brown),
        Shortcut(title: "RECORD LECTURES", icon: "mic.fill", color: .green),
        Shortcut(title: "TAKE NOTES", icon: "signature", color: .purple)
    ]

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

                Text("Good Evening, Pubudu")
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.md) {
                    ForEach(sessions) { session in
                        StudySessionCard(session: session) {
                        }
                    }
                }
            }
        }
    }

    private var upcomingDeadlines: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Upcoming Exams", actionTitle: "View Calendar") {
            }

            VStack(spacing: theme.spacing.md) {
                ForEach(deadlines) { deadline in
                    DeadlineCard(deadline: deadline,action: {})
                }
            }
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Smart Shortcuts")

            LazyVGrid(columns: [GridItem(.flexible(),spacing: theme.spacing.md), GridItem(.flexible())], spacing: theme.spacing.md) {
                ForEach(shortcuts) { shortcut in
                    ShortcutCard(shortcut: shortcut) {
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.theme, AppTheme.defaultTheme)
}
