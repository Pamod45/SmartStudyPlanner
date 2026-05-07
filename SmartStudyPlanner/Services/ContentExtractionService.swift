import Foundation
import PDFKit
import UIKit
import Combine

class ContentExtractionService {
    static let shared = ContentExtractionService()
    
    private init() {}
    
    func extractText(from resources: [Resource]) async throws -> String {
        return try await withThrowingTaskGroup(of: String.self) { group in
            for resource in resources {
                group.addTask {
                    try await self.extractText(from: resource)
                }
            }
            
            var combinedText = ""
            for try await text in group {
                if !text.isEmpty {
                    combinedText += text + "\n\n"
                }
            }
            return combinedText
        }
    }
    
    func extractText(from resource: Resource) async throws -> String {
        if let content = resource.content, !content.isEmpty {
            return content
        }
        
        switch resource.type {
        case .pdf, .scan:
            return try await extractTextFromPDF(resource: resource)
        case .link:
            return try await extractTextFromLink(resource: resource)
        case .note, .recording:
            return resource.content ?? ""
        default:
            return ""
        }
    }
    
    private func extractTextFromPDF(resource: Resource) async throws -> String {
        guard let fileName = resource.localFilePath else { return "" }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let pdfDocument = PDFDocument(url: fileURL) else {
            print("Could not load PDF document at \(fileURL)")
            return ""
        }
        
        var extractedText = ""
        var needsOCR = false
        
        if let text = pdfDocument.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            extractedText = text
        } else {
            needsOCR = true
        }
        
        if needsOCR {
            for i in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: i) else { continue }
                
                let pageRect = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                let img = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pageRect)
                    ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                
                let pageText = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    TextRecognitionService.shared.recognizeText(from: img) { result in
                        switch result {
                        case .success(let text):
                            continuation.resume(returning: text)
                        case .failure(let error):
                            print("OCR failed on page \(i): \(error)")
                            continuation.resume(returning: "")
                        }
                    }
                }
                
                extractedText += pageText + "\n"
            }
        }
        
        return extractedText
    }
    
    private func extractTextFromLink(resource: Resource) async throws -> String {
        guard let urlString = resource.remoteURL, let url = URL(string: urlString) else { return "" }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return ""
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
                
                if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                    continuation.resume(returning: attributedString.string)
                } else {
                    continuation.resume(returning: String(data: data, encoding: .utf8) ?? "")
                }
            }
        }
    }
}
