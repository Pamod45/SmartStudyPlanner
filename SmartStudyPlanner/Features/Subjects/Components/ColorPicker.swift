//
//  ColorPicker.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-02.
//

import SwiftUI

struct ColorPickerRow: View {
    @Environment(\.theme) var theme
    @Binding var selectedColor: Color

    let presetColors: [Color] = [.blue, .purple, .green, Color(red: 0.5, green: 0.2, blue: 0.9), .orange]

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            ForEach(presetColors, id: \.self) { color in
                Button {
                    selectedColor = color
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .shadow(color: color.opacity(0.6), radius: 12, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedColor == color ? 1.5 : 0)
                        )
                        .scaleEffect(selectedColor == color ? 1.15 : 1.0)
                        .animation(.spring(duration: 0.2), value: selectedColor == color)
                }
                .buttonStyle(.plain)
            }

            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .stroke(theme.colors.border.opacity(0.5), lineWidth: 1.5)
                )

            Spacer()
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }
}

