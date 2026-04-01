//
//  SearchBar.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//

import SwiftUI

struct SearchBar: View {
    @Environment(\.theme) var theme
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textSecondary)

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundColor(theme.colors.textSecondary)
                    .font(theme.typography.bodyLarge.weight(.medium))
            )
            .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
                .tint(theme.colors.primary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
    }
}
