import SwiftUI
import PDFKit

struct CapturedPage: Identifiable {
    let id = UUID()
    var image: UIImage
    var recognizedText: String?
}

struct ScannedText: Identifiable {
    let id = UUID()
    let text: String
}

struct ScannerView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onSave: (Resource) -> Void

    @State private var showCamera: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var showSourceSelection: Bool = false
    @State private var showSaveFormatSelection: Bool = false
    @State private var showPDFNameAlert: Bool = false
    @State private var pdfName: String = ""
    @State private var capturedPages: [CapturedPage] = []
    @State private var isProcessing: Bool = false
    @State private var scannedTextToEdit: ScannedText? = nil

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                if capturedPages.isEmpty {
                    emptyStateView
                } else {
                    capturedPagesView
                }

                bottomControls
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)
            }
        }
        .sheet(isPresented: $showCamera) {
            DocumentCameraView(
                onFinish: { images in
                    showCamera = false
                    for image in images {
                        let newPage = CapturedPage(image: image)
                        capturedPages.append(newPage)
                        let index = capturedPages.count - 1
                        processImage(image, at: index)
                    }
                },
                onCancel: {
                    showCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $scannedTextToEdit) { item in
            AddNoteView(existingResource: nil, initialContent: item.text) { resource in
                onSave(resource)
                dismiss()
            }
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                let newPage = CapturedPage(image: image)
                capturedPages.append(newPage)
                let index = capturedPages.count - 1
                processImage(image, at: index)
            }
            .ignoresSafeArea()
        }
        .confirmationDialog("Add Document", isPresented: $showSourceSelection, titleVisibility: .visible) {
            Button("Scan with Camera") {
                showCamera = true
            }
            Button("Choose from Photo Library") {
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Save Scans As", isPresented: $showSaveFormatSelection, titleVisibility: .visible) {
            Button("Extract Text to Note") {
                processCapturedPages()
            }
            Button("Save as PDF Document") {
                showPDFNameAlert = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Name Your PDF", isPresented: $showPDFNameAlert) {
            TextField("Document Name", text: $pdfName)
            Button("Save") {
                saveAsPDF()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for your new PDF document.")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            if !capturedPages.isEmpty {
                Button {
                    showSaveFormatSelection = true
                } label: {
                    Text("Done")
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.primary)
                }
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .overlay(
            Text("Scan Documents")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(theme.colors.textSecondary)

            VStack(spacing: theme.spacing.xs) {
                Text("No scans yet")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Tap the button below to scan or select documents")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var capturedPagesView: some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                ForEach(Array(capturedPages.enumerated()), id: \.element.id) { index, page in
                    pageCard(page: page, index: index)
                }
            }
            .padding(.horizontal, theme.spacing.lg)
        }
        .frame(maxHeight: .infinity)
    }

    private func pageCard(page: CapturedPage, index: Int) -> some View {
        VStack(spacing: theme.spacing.sm) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: page.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.lg)
                            .stroke(theme.colors.border, lineWidth: 1)
                    )

                if isProcessing && page.recognizedText == nil {
                    ZStack {
                        Color.black.opacity(0.6)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                }

                Button {
                    capturedPages.remove(at: index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.5)).padding(4))
                }
                .padding(theme.spacing.sm)
            }

            HStack {
                Text("Page \(index + 1)")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)

                Spacer()

                if let text = page.recognizedText {
                    HStack(spacing: theme.spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(text.count) characters")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: theme.spacing.md) {
            if !capturedPages.isEmpty {
                Button {
                    capturedPages.removeAll()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All")
                    }
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                }
            }

            Button {
                showSourceSelection = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(capturedPages.isEmpty ? "Start Scanning" : "Add Page")
                }
                .font(theme.typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(theme.colors.primary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            }
        }
    }

    private func processImage(_ image: UIImage, at index: Int) {
        isProcessing = true

        TextRecognitionService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                isProcessing = false

                switch result {
                case .success(let text):
                    if index < capturedPages.count {
                        capturedPages[index].recognizedText = text
                    }
                case .failure(let error):
                    print("Text recognition failed: \(error.localizedDescription)")
                    if index < capturedPages.count {
                        capturedPages[index].recognizedText = ""
                    }
                }
            }
        }
    }

    private func processCapturedPages() {
        let text = capturedPages.compactMap { $0.recognizedText }.joined(separator: "\n\n")
        scannedTextToEdit = ScannedText(text: text)
    }

    private func saveAsPDF() {
        let pdfDocument = PDFDocument()
        
        for (index, page) in capturedPages.enumerated() {
            if let pdfPage = PDFPage(image: page.image) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let safeName = pdfName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Scanned Document" : pdfName
        let fileName = "\(safeName) - \(UUID().uuidString.prefix(6)).pdf"
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        if pdfDocument.write(to: destinationURL) {
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
            let sizeMB = fileSize > 0 ? String(format: "%.1f MB", Double(fileSize) / 1_000_000) : ""
            
            let resource = Resource(
                name: safeName,
                resourceType: .pdf,
                size: sizeMB,
                localFilePath: destinationURL.lastPathComponent
            )
            onSave(resource)
            dismiss()
        } else {
            print("Failed to save PDF")
        }
    }
}
