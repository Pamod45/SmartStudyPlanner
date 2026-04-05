//
//  ResourceCard.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//


import SwiftUI

struct ResourceCard: View {
    @Environment(\.theme) var theme
    let resource: Resource
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Rectangle()
                    .fill(resource.type.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .cornerRadius(theme.radius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.lg)
                            .stroke(resource.type.color.opacity(0.4), lineWidth: 1)
                    )
                Image(systemName: resource.type.icon )
                    .font(theme.typography.headingMedium.weight(.semibold))
                    .foregroundColor(resource.type.color)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(resource.name)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Text("\(resource.type.rawValue) • \(resource.size)")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }.tint(.red)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(theme.colors.textSecondary)
                    .font(theme.typography.bodyMedium)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
    }
}
