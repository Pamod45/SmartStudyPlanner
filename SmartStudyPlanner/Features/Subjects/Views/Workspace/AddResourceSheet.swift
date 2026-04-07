import SwiftUI

enum ResourceAction: Identifiable {
    case scanNotes
    case liveRecording
    case newNote
    case addLink
    case addPDF
    var id: Self { self }
}

struct AddResourceSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onAdd: (Resource) -> Void

    @State private var activeAction: ResourceAction? = nil

    private struct Option {
        let title: String
        let icon: String
        let action: ResourceAction
    }

    private let options: [[Option]] = [
        [
            Option(title: "New Note",   icon: "note.text.badge.plus", action: .newNote),
            Option(title: "Record",     icon: "mic.fill",             action: .liveRecording),
            Option(title: "Add PDF",    icon: "doc.richtext.fill",    action: .addPDF)
        ],
        [
            Option(title: "Add Link",   icon: "link.circle.fill",     action: .addLink),
            Option(title: "Scan",       icon: "doc.viewfinder.fill",  action: .scanNotes)
        ]
    ]

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                HStack {
                    Text("Add Resource")
                        .font(theme.typography.headingLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(theme.colors.surface)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.xl)

                VStack(spacing: theme.spacing.md) {
                    ForEach(options, id: \.first?.title) { row in
                        HStack(spacing: theme.spacing.md) {
                            ForEach(row, id: \.title) { option in
                                optionTile(option)
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                    }
                }

                Spacer()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(theme.colors.surface.opacity(0.2))
        .sheet(item: $activeAction) { action in
            switch action {
            case .scanNotes:
                ScannerView { resource in onAdd(resource); dismiss() }
                    .environment(\.theme, theme)
            case .liveRecording:
                LiveRecordingView { resource in onAdd(resource); dismiss() }
                    .environment(\.theme, theme)
            case .newNote:
                AddNoteView { resource in onAdd(resource); dismiss() }
                    .environment(\.theme, theme)
            case .addLink:
                AddLinkSheet { resource in onAdd(resource); dismiss() }
                    .environment(\.theme, theme)
            case .addPDF:
                FilePickerWrapper { resource in onAdd(resource); dismiss() }
            }
        }
    }

    private func optionTile(_ option: Option) -> some View {
        Button {
            activeAction = option.action
        } label: {
            VStack(alignment: .center, spacing: theme.spacing.sm) {

                Image(systemName: option.icon)
                    .font(theme.typography.bodyLarge.weight(.bold))
                    .foregroundColor(theme.colors.primary)
                    .frame(width:48, height: 48 )
                    .background(theme.colors.surface)
                    .cornerRadius(theme.radius.lg)

                Text(option.title)
                    .font(theme.typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(.bottom, theme.spacing.sm)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#1A1A1C"), Color(hex: "#141622")],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.xl)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
