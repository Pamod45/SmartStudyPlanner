//
//  InputBox.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

enum InputFieldType {
    case password
    case text
}

struct InputField: View {
    @Environment(\.theme) var theme
    
    let icon: String
    let placeholder: String
    let fieldType: InputFieldType
    @Binding var value: String
    
    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 20, height: 20 )

            inputField
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.colors.border, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var inputField: some View {
        switch fieldType {
        case .password:
            SecureField("", text: $value, prompt: Text(placeholder)
                .foregroundColor(theme.colors.textSecondary))
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)

        case .text:
            TextField("", text: $value, prompt: Text(placeholder)
                .foregroundColor(theme.colors.textSecondary))
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
                .autocorrectionDisabled()
        }
    }
    
    
    
}


