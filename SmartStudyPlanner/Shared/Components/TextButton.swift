//
//  TextButton.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

enum TextButtonStyle {
    case standard
    case bold
}

struct TextButton: View {
    @Environment(\.theme) var theme

    let title: String
    var icon: String? = nil
    var style: TextButtonStyle = .standard
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        style: TextButtonStyle = .standard,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.xs) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        
                }
                Text(title).font(theme.typography.bodyMedium)
            }
             .fontWeight(style == .bold ? .semibold : .regular)
             .foregroundColor(theme.colors.primary)
            
        }
    }
}
