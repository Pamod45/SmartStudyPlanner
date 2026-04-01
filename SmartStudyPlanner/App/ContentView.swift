//
//  ContentView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
                LoginView()
        }
        .environment(\.theme, themeManager.current)
        .background(themeManager.current.colors.background.ignoresSafeArea())
        .toolbarBackground(themeManager.current.colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
