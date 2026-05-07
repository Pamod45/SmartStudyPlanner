//
//  ContentView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        Group {
            if sessionViewModel.isLoading {
                ZStack {
                    themeManager.current.colors.background.ignoresSafeArea()
                    EmptyView()
                }
            } else if sessionViewModel.isAuthenticated || sessionViewModel.isGuest {
                mainTabView
            } else {
                NavigationStack{
                    LoginView()
                }
            }
        }
        .environment(\.theme, themeManager.current)
        .tint(themeManager.current.colors.primary)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }

    private var mainTabView: some View {
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
                ProgressView()
            }
            .tabItem {
                Label(AppTab.progress.title, systemImage: AppTab.progress.icon)
            }
            .tag(AppTab.progress)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
            }
            .tag(AppTab.settings)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(SessionViewModel())
        .environmentObject(LocalSettingsManager())
}
