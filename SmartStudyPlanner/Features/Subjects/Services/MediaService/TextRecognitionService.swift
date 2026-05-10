
import UIKit
import Vision
import Combine

// OCR helper used by scanning and PDF text extraction to turn images into editable text.
class TextRecognitionService {
    static let shared = TextRecognitionService()
    
    private init() {}
    
    // Vision OCR runs off the main thread and returns the best recognized line from each observation.
    func recognizeText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "TextRecognitionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "TextRecognitionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No text found"])))
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            if recognizedText.isEmpty {
                completion(.failure(NSError(domain: "TextRecognitionService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No text recognized"])))
            } else {
                completion(.success(recognizedText))
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "TextRecognitionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = [Locale.Language(identifier: "en-US")]
        request.usesLanguageCorrection = true

        let handler = ImageRequestHandler(cgImage)
        let observations = try await request.perform(on: cgImage)
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")

        if recognizedText.isEmpty {
            throw NSError(domain: "TextRecognitionService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No text recognized"])
        }

        return recognizedText
    }
}
