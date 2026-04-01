//
//  ShortcutCard.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//

import SwiftUI

struct ShortcutCard: View {
    @Environment(\.theme) var theme
    let shortcut: Shortcut
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: theme.spacing.md) {
                ZStack {
                    Rectangle()
                        .fill(shortcut.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .cornerRadius(theme.radius.lg)
                    Image(systemName: shortcut.icon)
                        .font(theme.typography.headingMedium.weight(.semibold))
                        .foregroundColor(shortcut.color)
                }

                Text(shortcut.title)
                    .font(theme.typography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 136)
            .background(theme.colors.surface)
            .cornerRadius(theme.radius.xl)
        }
    }
}

