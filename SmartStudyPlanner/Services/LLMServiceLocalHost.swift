//import Foundation
//
//class LLMService {
//    static let shared = LLMService()
//    
//    private let serverURL = URL(string: "http://192.168.1.21:8080/v1/chat/completions")!
//    
//    private init() {}
//    
//    private struct ChatMessage: Codable {
//        let role: String
//        let content: String
//    }
//
//    private struct ChatRequest: Codable {
//        let messages: [ChatMessage]
//        let temperature: Double
//    }
//
//    private struct ChatResponse: Codable {
//        struct Choice: Codable {
//            let message: ChatMessage
//        }
//        let choices: [Choice]
//    }
//    
//    func generateStudyPathTopics(from text: String) async throws -> [StudyPathTopic] {
//        var request = URLRequest(url: serverURL)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.timeoutInterval = 300
//        let systemPrompt = """
//        You are an expert tutor. Create a study path from the provided text.
//        Output MUST be ONLY valid JSON matching this exact schema:
//        [
//          {
//            "order": 1,
//            "title": "Topic Title",
//            "description": "Brief description",
//            "subtopics": ["Subtopic 1"],
//            "weightPercent": 20
//          }
//        ]
//        """
//        
//        let payload = ChatRequest(
//            messages: [
//                ChatMessage(role: "system", content: systemPrompt),
//                ChatMessage(role: "user", content: "Text:\n\(text)\n\nReturn ONLY the JSON array.")
//            ],
//            temperature: 0.3
//        )
//        
//        request.httpBody = try JSONEncoder().encode(payload)
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw NSError(domain: "LLMService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad server response"])
//        }
//        
//        // Decode the wrapper from the server
//        let decodedResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
//        guard let jsonContent = decodedResponse.choices.first?.message.content else {
//            throw NSError(domain: "LLMService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty content returned from LLM"])
//        }
//        
//        return try parseTopicsFromJSON(jsonContent)
//    }
//    
//    private func parseTopicsFromJSON(_ jsonString: String) throws -> [StudyPathTopic] {
//        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // Remove markdown formatting if the model wrapped it
//        if cleanJSON.hasPrefix("```json") {
//            cleanJSON = String(cleanJSON.dropFirst(7))
//        } else if cleanJSON.hasPrefix("```") {
//            cleanJSON = String(cleanJSON.dropFirst(3))
//        }
//        if cleanJSON.hasSuffix("```") {
//            cleanJSON = String(cleanJSON.dropLast(3))
//        }
//        
//        cleanJSON = cleanJSON.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        struct GeneratedTopic: Codable {
//            let order: Int
//            let title: String
//            let description: String
//            let subtopics: [String]
//            let weightPercent: Int
//        }
//        
//        guard let data = cleanJSON.data(using: .utf8) else {
//            throw NSError(domain: "LLMService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
//        }
//        
//        do {
//            let generatedTopics = try JSONDecoder().decode([GeneratedTopic].self, from: data)
//            
//            return generatedTopics.map { gt in
//                StudyPathTopic(
//                    id: UUID().uuidString,
//                    order: gt.order,
//                    title: gt.title,
//                    description: gt.description,
//                    subtopics: gt.subtopics,
//                    weightPercent: gt.weightPercent,
//                    resourceIds: [],
//                    completionPercent: 0,
//                    isCompleted: false
//                )
//            }
//        } catch {
//            throw error
//        }
//    }
//}
