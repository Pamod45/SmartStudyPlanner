//
//  PrimaryButton.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

struct PrimaryButton: View {
    @Environment(\.theme) var theme

    let title: String
    var icon: String? = nil
    let action: () -> Void
    var isLoading: Bool = false
    
    init(title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack {
                    if let iconName = icon {
                        Image(systemName: iconName)
                    }
                    Text(title)
                }
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.textOnPrimary)
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(theme.colors.textOnPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.primary)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }
}

