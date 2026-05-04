import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}

struct PDFViewerSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    let resource: Resource

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

                    Text(resource.name)
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.lg)
                .padding(.bottom, theme.spacing.md)

                Divider().background(theme.colors.border.opacity(0.3))

                if let url = getPDFURL(), FileManager.default.fileExists(atPath: url.path) {
                    PDFKitView(url: url)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(theme.colors.textSecondary)
                        Text("PDF file not found or path is invalid")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .padding(.top, theme.spacing.sm)
                        Spacer()
                    }
                }
            }
        }
    }

    private func getPDFURL() -> URL? {
        guard let path = resource.localFilePath else { return nil }
        
        if path.starts(with: "file://") || path.contains("var/mobile/Containers") || path.contains("CoreSimulator") {
            let tempUrl = URL(string: path) ?? URL(fileURLWithPath: path)
            let filename = tempUrl.lastPathComponent
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(filename)
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(path)
        }
    }
}
