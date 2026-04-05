//
//  SubjectCard.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct NotificationCard: View {
    @Environment(\.theme) var theme
    let notification: AppNotification
    var onTap: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            ZStack {
                Rectangle()
                    .fill(notification.color.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .cornerRadius(theme.radius.lg)
                Image(systemName: notification.icon )
                    .font(theme.typography.headingMedium.weight(.semibold))
                    .foregroundColor(notification.color)
            }
            VStack (alignment: .leading, spacing: theme.spacing.sm ) {
                HStack {
                    Text(notification.title)
                        .font(theme.typography.headingMedium.weight(.bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(notification.dateString)
                        .font(theme.typography.label)
                        .foregroundColor(theme.colors.textSecondary)
                }
                Text(notification.message)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
    }
}
