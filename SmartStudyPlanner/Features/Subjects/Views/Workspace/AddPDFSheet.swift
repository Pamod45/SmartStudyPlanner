import SwiftUI
import UniformTypeIdentifiers

struct AddPDFSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var existingResource: Resource? = nil
    var onSave: (Resource) -> Void
    var onUpdate: ((Resource) -> Void)? = nil

    @State private var name: String = ""
    @State private var filePath: String = ""
    @State private var fileSize: String = ""
    @State private var showFilePicker: Bool = false

    private var isEditing: Bool { existingResource != nil }

    private var isValid: Bool {
        !name.isEmpty && !filePath.isEmpty
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.surface)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(isEditing ? "Edit PDF" : "Add PDF")
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Button("Save") {
                        save()
                    }
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? theme.colors.primary : theme.colors.textSecondary)
                    .disabled(!isValid)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.lg)
                .padding(.bottom, theme.spacing.md)

                Divider().background(theme.colors.border.opacity(0.3))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        ZStack {
                            RoundedRectangle(cornerRadius: theme.radius.xl)
                                .fill(Color.red.opacity(0.1))
                                .frame(height: 100)
                            VStack(spacing: theme.spacing.sm) {
                                Image(systemName: "doc.richtext.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.red)
                                Text(isEditing ? "Update your PDF resource" : "Import a PDF as a resource")
                                    .font(theme.typography.bodySmall)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }

                        FieldSection(title: "RESOURCE NAME") {
                            TextField(
                                "",
                                text: $name,
                                prompt: Text("e.g., Lecture Slides Week 1")
                                    .foregroundColor(theme.colors.textSecondary)
                            )
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                            .tint(theme.colors.primary)
                            .padding(theme.spacing.md)
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        FieldSection(title: "PDF FILE") {
                            Button {
                                showFilePicker = true
                            } label: {
                                HStack(spacing: theme.spacing.sm) {
                                    Image(systemName: filePath.isEmpty ? "doc.badge.plus" : "doc.richtext.fill")
                                        .foregroundColor(filePath.isEmpty ? theme.colors.textSecondary : .red)
                                        .font(.system(size: 16))

                                    Text(filePath.isEmpty ? "Select PDF file..." : (name.isEmpty ? "File selected" : name))
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(filePath.isEmpty ? theme.colors.textSecondary : theme.colors.textPrimary)

                                    Spacer()

                                    if !fileSize.isEmpty {
                                        Text(fileSize)
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.colors.textSecondary)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                .padding(theme.spacing.md)
                                .background(theme.colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(theme.spacing.lg)
                }
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePickerView { resource in
                filePath = resource.filePath ?? ""
                fileSize = resource.size
                if name.isEmpty { name = resource.name }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            if let existing = existingResource {
                name = existing.name
                filePath = existing.filePath ?? ""
                fileSize = existing.size
            }
        }
    }

    private func save() {
        let resource = Resource(
            id: existingResource?.id ?? UUID(),
            name: name,
            type: .pdf,
            size: fileSize,
            subjectID: existingResource?.subjectID ?? UUID(),
            filePath: filePath
        )
        if isEditing {
            onUpdate?(resource)
        } else {
            onSave(resource)
        }
        dismiss()
    }
}
