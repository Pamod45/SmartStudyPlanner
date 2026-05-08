//
//  PrimaryButton.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

struct SecondaryButton: View {
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
                HStack(spacing: theme.spacing.xs) {
                    if let iconName = icon {
                        Image(systemName: iconName)
                    }
                    Text(title)
                }
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.primary)

                if isLoading {
                    SwiftUI.ProgressView()
                        .tint(theme.colors.textOnPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.secondary)
            .clipShape(Capsule())
            
            
        }
        .disabled(isLoading)
    }
}
