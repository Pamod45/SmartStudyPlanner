import SwiftUI

struct AddNoteView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onSave: (Resource) -> Void

    @State private var title: String = ""
    @State private var storage: NSAttributedString = NSAttributedString(string: "")
    @FocusState private var titleFocused: Bool

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Divider().background(theme.colors.border.opacity(0.2))

                MarkdownEditorView(storage: $storage)
                    .environment(\.theme, theme)
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(theme.typography.bodyMedium)
            .foregroundColor(theme.colors.primary)

            Spacer()

            TextField(
                "",
                text: $title,
                prompt: Text("New Note")
                    .foregroundColor(theme.colors.textSecondary)
            )
            .font(theme.typography.headingSmall)
            .fontWeight(.bold)
            .foregroundColor(theme.colors.textPrimary)
            .multilineTextAlignment(.center)
            .focused($titleFocused)
            .frame(maxWidth: 180)

            Spacer()

            Button("Done") {
                save()
            }
            .font(theme.typography.bodyMedium)
            .fontWeight(.semibold)
            .foregroundColor(title.isEmpty ? theme.colors.textSecondary : theme.colors.primary)
            .disabled(title.isEmpty)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
    }

    private func save() {
        let resource = Resource(
            name: title,
            type: .note,
            subjectID: UUID(),
            noteContent: storage.string
        )
        onSave(resource)
        dismiss()
    }
}
