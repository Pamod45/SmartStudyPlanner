//
//  IntegrationsView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct IntegrationsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: SettingsViewModel

    private let widgetOptions = ["Default Widget Data", "Progress Summary", "Daily Goals", "Upcoming Sessions"]

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
                        FieldSection(title: "WIDGET CONFIGURATION") {
                            VStack(spacing: 0) {
                                ForEach(Array(widgetOptions.enumerated()), id: \.offset) { i, option in
                                    Button {
                                        vm.updateSettings { $0.widgetConfiguration = option }
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(theme.typography.bodyLarge.weight(.semibold))
                                                .foregroundColor(theme.colors.textPrimary)
                                            Spacer()
                                            if vm.settings.widgetConfiguration == option {
                                                Image(systemName: "checkmark")
                                                    .font(theme.typography.bodyMedium.weight(.semibold))
                                                    .foregroundColor(theme.colors.primary)
                                            }
                                        }
                                        .padding(.horizontal, theme.spacing.md)
                                        .padding(.vertical, theme.spacing.md)
                                    }
                                    .buttonStyle(.plain)
                                    if i < widgetOptions.count - 1 {
                                        Divider().background(theme.colors.border.opacity(0.4)).padding(.leading, theme.spacing.md)
                                    }
                                }
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                            .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
                        }

                        Text("Note: iOS widgets are added from your Home Screen. Select above which data should appear in your default widget.")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 0) {
                            HStack {
                                Text("Siri Integration")
                                    .font(theme.typography.bodyLarge.weight(.semibold))
                                    .foregroundColor(theme.colors.textPrimary)
                                Spacer()
                                Toggle("", isOn: vm.binding(for: \.siriIntegrationEnabled)).labelsHidden().tint(theme.colors.primary)
                            }
                            .padding(.horizontal, theme.spacing.md)
                            .padding(.vertical, theme.spacing.md)
                        }
                        .background(theme.colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
                    }
                    .padding(.horizontal, theme.spacing.sm)
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
            Text("Integrations")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon: "chevron.left") {}.opacity(0)
        }
    }
}

#Preview {
    NavigationStack { IntegrationsView() }
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
        .environment(\.theme, AppTheme.defaultTheme)
}
