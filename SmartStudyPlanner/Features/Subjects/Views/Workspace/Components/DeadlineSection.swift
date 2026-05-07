//
//  DeadlineSection.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//


import SwiftUI

struct DeadlineSection: View {
    @Environment(\.theme) var theme
    @Binding var deadlines: [Deadline]
    @Binding var isExpanded: Bool
    var onAdd: () -> Void
    var onCardTap: (Deadline) -> Void = { _ in }
    var onDelete: (Deadline) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Deadlines")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                HStack(spacing: theme.spacing.md){
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up.2" : "chevron.down.2")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                    }

                    TextButton(title: "Add", icon: "plus", style: .bold, action: onAdd)
                }
                
            }

            if isExpanded {
                if deadlines.isEmpty {
                    Text("No deadlines yet")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, theme.spacing.md)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.md) {
                            ForEach(deadlines) { deadline in
                                WorkspaceDeadlineCard(
                                    deadline: deadline,
                                    onTap: { onCardTap(deadline) },
                                    onDelete: { onDelete(deadline) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical,theme.spacing.md)
    }
}
