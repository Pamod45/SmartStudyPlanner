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
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: Circle())
        }
    }
}

