import SwiftUI

struct AddNoteView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var existingResource: Resource? = nil
    var initialContent: String? = nil
    var onSave: (Resource) -> Void

    @State private var title: String = ""
    @State private var storage: NSAttributedString = NSAttributedString(string: "")
    @FocusState private var titleFocused: Bool
    @StateObject private var ttsManager = TextToSpeechManager.shared


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
        .onAppear {
            ttsManager.stop()

            if let existing = existingResource {
                title = existing.name
                if let content = existing.content {
                    storage = NSAttributedString(string: content)
                }
            } else if let initial = initialContent {
                storage = NSAttributedString(string: initial)
                title = "Scanned Note"
            }
        }
        .onDisappear {
            ttsManager.stop()
        }
    }

    private var topBar: some View {
        HStack {
            Button("Cancel") {
                ttsManager.stop()
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

            if !storage.string.isEmpty {
                Button {
                    if ttsManager.isSpeaking {
                        if ttsManager.isPaused {
                            ttsManager.resume()
                        } else {
                            ttsManager.pause()
                        }
                    } else {
                        ttsManager.speak(text: storage.string)
                    }
                } label: {
                    Image(systemName: ttsManager.isSpeaking && !ttsManager.isPaused ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.colors.primary)
                }
                .padding(.trailing, theme.spacing.sm)
            }

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
        let resource: Resource
        
        if let existing = existingResource {
            resource = Resource(
                id: existing.id,
                userId: existing.userId,
                subjectId: existing.subjectId,
                name: title.isEmpty ? "Untitled" : title,
                resourceType: .note,
                size: existing.size,
                content: storage.string,
                localFilePath: existing.localFilePath,
                remoteURL: existing.remoteURL,
                fileSize: existing.fileSize,
                mimeType: existing.mimeType,
                tags: existing.tags,
                isFavorite: existing.isFavorite,
                createdAt: existing.createdAt,
                updatedAt: Date(),
                syncStatus: .pendingUpdate
            )
        } else {
            resource = Resource(
                id: UUID().uuidString,
                userId: "",
                subjectId: "",
                name: title.isEmpty ? "Untitled" : title,
                resourceType: .note,
                content: storage.string,
                createdAt: Date(),
                updatedAt: Date(),
                syncStatus: .localOnly
            )
        }
        
        onSave(resource)
        ttsManager.stop()
        dismiss()
    }
}
