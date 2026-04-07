//
//  ChipPicker.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-03.
//
import SwiftUI
struct ChipPicker<T: Identifiable>: View {
    @Environment(\.theme) var theme
    
    let items: [T]
    @Binding var selection: T
    let labelProvider: (T) -> String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.sm) {
                ForEach(items) { item in
                    Button(action: { selection = item }) {
                        Text(labelProvider(item))
                            .font(theme.typography.bodyMedium.weight(.semibold))
                            .padding(.horizontal, (theme.spacing.md+theme.spacing.lg) / 2)
                            .padding(.vertical, theme.spacing.m)
                            .foregroundColor(selection.id == item.id ? .white : theme.colors.textPrimary)
                            .background(selection.id == item.id ? theme.colors.primary : theme.colors.surface)
                            .cornerRadius(theme.radius.full)
                    }
                }
            }
        }
    }
}
