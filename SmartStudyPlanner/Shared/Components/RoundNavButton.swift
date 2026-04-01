//
//  RoundNavigationButton.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//
import SwiftUI

struct RoundNavButton: View {
    let action: () -> Void
    @Environment(\.theme) var theme: AppTheme
    var body: some View{
        Button(action: action){
            Image(systemName: "chevron.right")
                .font(theme.typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 40, height: 40)
                .background(theme.colors.surface)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(theme.colors.border.opacity(0.6), lineWidth: 1)
                )
        }
    }
}

