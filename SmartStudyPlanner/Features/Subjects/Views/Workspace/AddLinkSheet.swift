import SwiftUI

struct AddLinkSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onSave: (Resource) -> Void

    @State private var name: String = ""
    @State private var url: String = ""

    private var isValid: Bool {
        !name.isEmpty && !url.isEmpty && url.contains(".")
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

                    Text("Add Link")
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
                                .fill(Color.orange.opacity(0.1))
                                .frame(height: 100)
                            VStack(spacing: theme.spacing.sm) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.orange)
                                Text("Save a URL as a resource")
                                    .font(theme.typography.bodySmall)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }

                        FieldSection(title: "RESOURCE NAME") {
                            TextField(
                                "",
                                text: $name,
                                prompt: Text("e.g., Apple Developer Docs")
                                    .foregroundColor(theme.colors.textSecondary)
                            )
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                            .tint(theme.colors.primary)
                            .padding(theme.spacing.md)
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        FieldSection(title: "URL") {
                            HStack(spacing: theme.spacing.sm) {
                                Image(systemName: "link")
                                    .foregroundColor(theme.colors.textSecondary)
                                    .font(.system(size: 14))

                                TextField(
                                    "",
                                    text: $url,
                                    prompt: Text("https://...")
                                        .foregroundColor(theme.colors.textSecondary)
                                )
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                                .tint(theme.colors.primary)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            }
                            .padding(theme.spacing.md)
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }
                    }
                    .padding(theme.spacing.lg)
                }
            }
        }
    }

    private func save() {
        let resource = Resource(
            name: name,
            type: .link,
            subjectID: UUID(),
            url: url.hasPrefix("http") ? url : "https://\(url)"
        )
        onSave(resource)
        dismiss()
    }
}
