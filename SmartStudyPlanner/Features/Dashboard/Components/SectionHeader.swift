//
//  SectionHeader.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//

import SwiftUI

struct SectionHeader: View {
    @Environment(\.theme) var theme
    let title: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            if let actionTitle, let onAction {
                TextButton(title:actionTitle, style: .bold){
                    onAction()
                }
            } else if let actionTitle {
                Text(actionTitle)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
}

