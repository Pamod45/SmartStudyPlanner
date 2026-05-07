import SwiftUI

struct ResourceCard: View {
    @Environment(\.theme) var theme
    let resource: Resource
    var onOpen: () -> Void = {}
    var onEdit: () -> Void = {}
    var onRename: (String) -> Void
    var onDelete: () -> Void

    @State private var showDeleteConfirmation: Bool = false
    @State private var showRenameAlert: Bool = false
    @State private var newName: String = ""

    var body: some View {
        Button {
            if resource.type == .note || resource.type == .pdf {
                onOpen()
            }
        } label: {
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
                    if resource.type != .recording {
                        Button {
                            if resource.type == .pdf || resource.type == .link {
                                onEdit()
                            } else {
                                newName = resource.name
                                showRenameAlert = true
                            }
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(theme.colors.textSecondary)
                                .font(theme.typography.bodyMedium)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit")
                    }

                if resource.type == .pdf {
                    Button {
                        onOpen()
                    } label: {
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Open PDF")
                }

                if resource.type == .recording {
                    Button {
                        onOpen()
                    } label: {
                        Image(systemName: "play.circle")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Play Recording")
                }

                if resource.type == .link {
                    Button {
                        if let urlString = resource.remoteURL, let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "safari")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Open Link")
                }

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(theme.typography.bodyMedium)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete")
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Resource: \(resource.name), Type: \(resource.type.rawValue)")
        .alert("Delete Resource", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(resource.name)\" will be permanently removed and cannot be undone.")
        }
        .alert("Rename Resource", isPresented: $showRenameAlert) {
            TextField("Name", text: $newName)
            Button("Rename") {
                if !newName.isEmpty {
                    onRename(newName)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a new name for this resource")
        }
    }
}
