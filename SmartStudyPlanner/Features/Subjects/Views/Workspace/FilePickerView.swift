import SwiftUI
import UniformTypeIdentifiers

// Wraps the document picker in a dismissing SwiftUI view.
struct FilePickerWrapper: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Resource) -> Void

    var body: some View {
        FilePickerView(onSave: { resource in
            onSave(resource)
            dismiss()
        })
        .ignoresSafeArea()
    }
}

// Imports one PDF into the app sandbox and returns a Resource pointing at the copied file.
struct FilePickerView: UIViewControllerRepresentable {
    var onSave: (Resource) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSave: onSave)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onSave: (Resource) -> Void

        init(onSave: @escaping (Resource) -> Void) {
            self.onSave = onSave
        }

        // Security-scoped access is needed for files outside the sandbox; the selected file is copied into Documents.
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsDirectory.appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)

            do {
                try FileManager.default.copyItem(at: url, to: destinationURL)
            } catch {
                print("Failed to copy file to sandbox: \(error)")
                return
            }

            let fileName = url.deletingPathExtension().lastPathComponent
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
            let sizeMB = fileSize > 0 ? String(format: "%.1f MB", Double(fileSize) / 1_000_000) : ""

            let resource = Resource(
                name: fileName,
                resourceType: .pdf,
                size: sizeMB,
                localFilePath: destinationURL.lastPathComponent
            )
            onSave(resource)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
