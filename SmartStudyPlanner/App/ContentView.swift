//
//  ContentView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                SubjectsView()
            }
            .tabItem {
                Label(AppTab.subjects.title, systemImage: AppTab.subjects.icon)
            }
            .tag(AppTab.subjects)

            NavigationStack {
                StudyPlanView()
            }
            .tabItem {
                Label(AppTab.plan.title, systemImage: AppTab.plan.icon)
            }
            .tag(AppTab.plan)

            NavigationStack {
                Text("Progress")
            }
            .tabItem {
                Label(AppTab.progress.title, systemImage: AppTab.progress.icon)
            }
            .tag(AppTab.progress)

            NavigationStack {
                Text("Settings")
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
            }
            .tag(AppTab.settings)
        }
        .environment(\.theme, themeManager.current)
        .tint(themeManager.current.colors.primary)
        .preferredColorScheme(.dark)
        
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
