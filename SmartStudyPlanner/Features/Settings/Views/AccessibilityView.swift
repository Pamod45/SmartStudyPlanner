//
//  AccessibilityView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct AccessibilityView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var textSizePercent: Double = 100
    @State private var reduceMotion: Bool = true
    @State private var highContrastColors: Bool = true

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.lg)
                    
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.md) {
                        FieldSection(title: "STUDY GOALS") {
                            VStack(spacing: 0) {
                                sliderRow
                                rowDivider
                                toggleRow(title: "Reduce Motion", isOn: $reduceMotion)
                                rowDivider
                                toggleRow(title: "High Contrast Colors", isOn: $highContrastColors)
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                            .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            RoundedIconButton(icon: "chevron.left") { dismiss() }
            Spacer()
            Text("Accessibility")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon: "chevron.left") {}.opacity(0)
        }
    }

    private var sliderRow: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text("Text size")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text("\(Int(textSizePercent))%")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Slider(value: $textSizePercent, in: 75...150, step: 5)
                .tint(theme.colors.primary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(theme.colors.primary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
    }

    private var rowDivider: some View {
        Divider().background(theme.colors.border.opacity(0.4)).padding(.leading, theme.spacing.md)
    }
}

#Preview {
    NavigationStack { AccessibilityView() }
        .environmentObject(ThemeManager())
        .environment(\.theme, AppTheme.defaultTheme)
}
