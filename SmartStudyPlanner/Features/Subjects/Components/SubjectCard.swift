//
//  SubjectCard.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct SubjectCard: View {
    @Environment(\.theme) var theme
    let subject: Subject
    var onTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
            HStack (spacing: theme.spacing.lg){
                Circle()
                    .fill(subject.color)
                    .frame(width: 12, height: 12)
                    .shadow(color: subject.color.opacity(0.6), radius: 6, x: 0, y: 0)
                    .shadow(color: subject.color.opacity(0.3), radius: 12, x: 0, y: 0)

                Text(subject.name)
                    .font(theme.typography.headingMedium.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                RoundNavButton(action: {})
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("RESOURCES")
                        .font(theme.typography.label.weight(.semibold))
                        .foregroundColor(theme.colors.textSecondary)
                    Text("\(subject.resources)")
                        .font(theme.typography.headingSmall)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Spacer().frame(width: theme.spacing.xl)

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("TOPICS")
                        .font(theme.typography.label.weight(.semibold))
                        .foregroundColor(theme.colors.textSecondary)
                    Text("\(subject.topics)")
                        .font(theme.typography.headingSmall)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Spacer()

                Text("Last Updated: \(subject.lastUpdated)")
                    .font(theme.typography.label)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
    }
}
