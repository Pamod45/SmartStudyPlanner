//
//  ResourcesTab.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//


import SwiftUI

struct ResourcesTabView: View {
    @Environment(\.theme) var theme
    @Binding var resources: [Resource]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if resources.isEmpty {
                VStack(spacing: theme.spacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(theme.colors.textSecondary)
                    Text("No resources yet")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                VStack(spacing: theme.spacing.md) {
                    ForEach(resources) { resource in
                        ResourceCard(resource: resource) {
                            resources.removeAll { $0.id == resource.id }
                        }
                    }
                }
            }
        }
        .padding(.bottom, theme.spacing.xl)
    }
}
