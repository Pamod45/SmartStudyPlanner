//
//  StudyPathTabView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//


import SwiftUI

struct StudyPathTabView: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary)
            Text("Study Path coming soon")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
