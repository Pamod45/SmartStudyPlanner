//
//  OrDivider.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//
import SwiftUI

struct OrDivider : View{
    @Environment(\.theme) var theme
    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(theme.colors.border)

            Text("Or")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)

            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(theme.colors.border)
        }
    }
}
