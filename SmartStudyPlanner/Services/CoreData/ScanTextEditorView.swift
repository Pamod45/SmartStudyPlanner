
import SwiftUI
import Combine

struct ScanTextEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var recognizedText: String
    var theme: AppTheme
    var onSave: (String) -> Void
    
    @State private var title: String = ""
    @State private var storage: NSAttributedString
    @FocusState private var titleFocused: Bool
    
    init(recognizedText: String, theme: AppTheme, onSave: @escaping (String) -> Void) {
        self.recognizedText = recognizedText
        self.theme = theme
        self.onSave = onSave
        _storage = State(initialValue: NSAttributedString(string: recognizedText))
        _title = State(initialValue: "Scanned Note")
    }
    
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
                prompt: Text("Scanned Note")
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
            .foregroundColor(theme.colors.primary)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
    }
    
    private func save() {
        onSave(storage.string)
        dismiss()
    }
}
