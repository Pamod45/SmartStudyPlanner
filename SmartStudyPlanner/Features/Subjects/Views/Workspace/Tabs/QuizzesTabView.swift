//
//  QuizzesTabView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//


import SwiftUI

struct QuizzesTabView: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary)
            Text("Quizzes coming soon")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
