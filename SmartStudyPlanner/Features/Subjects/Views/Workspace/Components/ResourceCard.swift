import SwiftUI

struct ResourceCard: View {
    @Environment(\.theme) var theme
    let resource: Resource
    var onOpen: () -> Void = {}
    var onDelete: () -> Void

    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Rectangle()
                    .fill(resource.type.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .cornerRadius(theme.radius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.lg)
                            .stroke(resource.type.color.opacity(0.4), lineWidth: 1)
                    )
                Image(systemName: resource.type.icon)
                    .font(theme.typography.headingSmall.weight(.semibold))
                    .foregroundColor(resource.type.color)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(resource.name)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(resource.type == .note
                     ? "Note"
                     : "\(resource.type.rawValue) • \(resource.size)")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            HStack(spacing: theme.spacing.xs) {
                if resource.type == .note {
                    Button {
                        onOpen()
                    } label: {
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }
                }

                if resource.type == .pdf {
                    Button {
                        if let path = resource.filePath,
                           let url = URL(string: path) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "eye")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }

                    Button {
                        onOpen()
                    } label: {
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }
                }

                if resource.type == .link {
                    Button {
                        if let urlString = resource.url, let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "link")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }

                    Button {
                        onOpen()
                    } label: {
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }
                }

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(theme.typography.bodyMedium)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .alert("Delete Resource", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(resource.name)\" will be permanently removed and cannot be undone.")
        }
    }
}
