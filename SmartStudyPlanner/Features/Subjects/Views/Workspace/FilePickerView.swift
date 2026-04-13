import SwiftUI
import UniformTypeIdentifiers

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

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            let fileName = url.deletingPathExtension().lastPathComponent
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            let sizeMB = fileSize > 0 ? String(format: "%.1f MB", Double(fileSize) / 1_000_000) : ""

            let resource = Resource(
                name: fileName,
                resourceType: .pdf,
                size: sizeMB,
                localFilePath: url.absoluteString
            )
            onSave(resource)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
