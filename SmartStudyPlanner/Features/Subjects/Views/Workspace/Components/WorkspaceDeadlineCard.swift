//
//  DeadlineCard.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//

import SwiftUI

struct WorkspaceDeadlineCard: View {
    @Environment(\.theme) var theme
    let deadline: Deadline

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(alignment: .top) {
                ZStack {
                    Rectangle()
                        .fill(deadline.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .cornerRadius(theme.radius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.lg)
                                .stroke(deadline.color.opacity(0.4), lineWidth: 1)
                        )
                    Image(systemName: deadline.icon )
                        .font(theme.typography.headingMedium.weight(.semibold))
                        .foregroundColor(deadline.color)
                }

                Spacer()
                
                Text(deadline.tag.rawValue)
                    .font(theme.typography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xs)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                

            }

            Spacer()
            
            VStack (spacing:theme.spacing.sm){
                Text(deadline.name)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(deadline.formattedDate)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
        }
        .padding(theme.spacing.lg)
        .frame(width: 240, height: 175)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
    }
}
