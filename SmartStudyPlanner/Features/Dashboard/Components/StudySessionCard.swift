//
//  StudySessionCard.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//

import SwiftUI

struct StudySessionCard: View {
    @Environment(\.theme) var theme
    let session: StudySession
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(session.subjectName)
                .font(theme.typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(session.subjectColor)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs)
                .background(session.subjectColor.opacity(0.2))
                .clipShape(Rectangle())
                .cornerRadius(theme.spacing.xs)
                
            
            VStack(alignment: .leading, spacing: theme.spacing.xs){
                Text(session.title)
                    .font(theme.typography.headingMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)

                Text(session.timeRange)
                    .font(theme.typography.caption)
                    .foregroundColor(session.subjectColor)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                           .font(theme.typography.caption)
                       Text(session.duration)
                           .font(theme.typography.bodyMedium)
                }
                .foregroundColor(theme.colors.textSecondary)
            }.padding(.bottom, theme.spacing.sm)

            PrimaryButton(title:"Start",icon:"play.fill", action: onStart)
        }
        .padding(theme.spacing.md)
        .frame(width: 270)
        .background(theme.colors.surface)
        .cornerRadius(theme.radius.xl)
    }
}
