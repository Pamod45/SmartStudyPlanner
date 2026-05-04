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
    var filteredResources: [Resource]
    var onOpenNote: (Resource) -> Void
    var onEditResource: (Resource) -> Void
    var onRenameResource: (Resource, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if filteredResources.isEmpty {
                VStack(spacing: theme.spacing.md) {
                    Image(systemName: resources.isEmpty ? "tray" : "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(theme.colors.textSecondary)
                    Text(resources.isEmpty ? "No resources yet" : "No results found")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                VStack(spacing: theme.spacing.md) {
                    ForEach(filteredResources) { resource in
                        ResourceCard(
                            resource: resource,
                            onOpen: { onOpenNote(resource) },
                            onEdit: { onEditResource(resource) },
                            onRename: { newName in
                                onRenameResource(resource, newName)
                            },
                            onDelete: {
                                Task {
                                    do {
                                        try await ResourceService.shared.deleteResource(id: resource.id)
                                        await MainActor.run {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                resources.removeAll { $0.id == resource.id }
                                            }
                                        }
                                    } catch {
                                        print("Failed to delete resource: \(error)")
                                    }
                                }
                            }
                        )
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            )
                        )
                    }
                }
            }
        }
        .padding(.bottom, theme.spacing.xl)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: resources.map { $0.id })
    }
}
