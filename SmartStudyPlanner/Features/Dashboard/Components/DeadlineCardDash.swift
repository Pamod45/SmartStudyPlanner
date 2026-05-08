//
//  DeadlineCard.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//

import SwiftUI

struct DeadlineCard: View {
    @Environment(\.theme) var theme
    let deadline: Deadline
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.md) {
            VStack {
                Text(deadline.month)
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(deadline.subjectColor)
                Text("\(deadline.day)")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .frame(width: 48, height: 48)
            .cornerRadius(theme.spacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: theme.spacing.sm)
                    .stroke(theme.colors.border.opacity(0.4), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(deadline.name)
                    .font(theme.typography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Text(deadline.formattedDate)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            RoundNavButton(action: action)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.radius.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Deadline: \(deadline.name)")
        .accessibilityValue("Due on \(deadline.month) \(deadline.day), \(deadline.formattedDate)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }
}
