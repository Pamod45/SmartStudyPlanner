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
            HStack {
                Spacer()
                if let tag = deadline.tags.first {
                    Text(tag.rawValue.replacingOccurrences(of: "#", with: ""))
                        .font(theme.typography.labelSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Image(systemName: deadline.isHighPriority ? "calendar.badge.exclamationmark" : "doc.text.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text(deadline.name)
                .font(theme.typography.bodyMedium)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(deadline.formattedDate)
                .font(theme.typography.bodySmall)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(theme.spacing.md)
        .frame(width: 160, height: 160)
        .background(
            LinearGradient(
                colors: deadline.isHighPriority
                    ? [Color.red.opacity(0.8), Color.orange.opacity(0.6)]
                    : [theme.colors.primary.opacity(0.8), theme.colors.primary.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }
}
