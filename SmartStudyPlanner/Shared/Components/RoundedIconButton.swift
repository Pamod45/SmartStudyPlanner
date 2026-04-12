//
//  RoundIconButton.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-31.
//

import SwiftUI

struct RoundedIconButton: View {
    @Environment(\.theme) var theme

    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: Circle())
        }
    }
}
