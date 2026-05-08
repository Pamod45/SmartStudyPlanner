import Foundation
import FoundationModels

// Message model used by the subject workspace AI assistant chat.

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date = Date()

    enum Role { case user, assistant, error }
}

// Defines which study material the assistant should use for a chat response.

enum ChatContext: Identifiable, Equatable {
    case allDocs
    case resource(Resource)
    case topic(StudyPathTopic)

    var id: String {
        switch self {
        case .allDocs:          return "__all__"
        case .resource(let r): return "r_\(r.id)"
        case .topic(let t):    return "t_\(t.id)"
        }
    }

    var label: String {
        switch self {
        case .allDocs:          return "All Docs"
        case .resource(let r): return r.name
        case .topic(let t):    return t.title
        }
    }

    var icon: String {
        switch self {
        case .allDocs:          return "books.vertical"
        case .resource(let r):
            switch r.type {
            case .pdf:       return "doc.richtext"
            case .note:      return "note.text"
            case .link:      return "link"
            case .recording: return "waveform"
            default:         return "doc"
            }
        case .topic:            return "list.bullet.rectangle"
        }
    }

    static func == (lhs: ChatContext, rhs: ChatContext) -> Bool { lhs.id == rhs.id }
}


// Builds AI assistant context and sends chat prompts to the available model backend.

actor AIAssistantService {
    static let shared = AIAssistantService()
    private init() {}

    private var sessions: [String: LanguageModelSession] = [:]

    private let serverURL = URL(string: "http://192.168.1.21:8080/v1/chat/completions")!
    private let timeoutInterval: TimeInterval = 120

    nonisolated var isUsingOnDeviceModel: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }


    // Converts the selected chat context into plain text that can be included in the prompt.
    func resolveContext(
        _ context: ChatContext,
        allResources: [Resource],
        studyPath: StudyPath?
    ) async -> String {
        switch context {
        case .allDocs:
            let text = (try? await ContentExtractionService.shared.extractText(from: allResources)) ?? ""
            let topicText = (studyPath?.topics ?? []).map { topicSummary($0) }.joined(separator: "\n\n")
            return [text, topicText].filter { !$0.isEmpty }.joined(separator: "\n\n")
        case .resource(let resource):
            return (try? await ContentExtractionService.shared.extractText(from: resource)) ?? resource.name
        case .topic(let topic):
            return topicSummary(topic)
        }
    }


    // Clears an on-device model conversation for one selected context.
    func clearSession(for contextId: String) {
        sessions.removeValue(forKey: contextId)
    }

    // Sends a user message with the resolved study context and recent chat history.
    func send(
        userMessage: String,
        contextText: String,
        subjectName: String,
        contextId: String,
        history: [ChatMessage]
    ) async throws -> String {
//        if case .available = SystemLanguageModel.default.availability {
//            return try await sendViaFoundationModel(
//                userMessage: userMessage,
//                contextText: contextText,
//                subjectName: subjectName,
//                contextId: contextId
//            )
//        }
        return try await sendViaHTTP(
            userMessage: userMessage,
            contextText: contextText,
            subjectName: subjectName,
            history: history
        )
    }


    // Keeps a separate Foundation Models session per context so local conversations can continue naturally.
    private func sendViaFoundationModel(
        userMessage: String,
        contextText: String,
        subjectName: String,
        contextId: String
    ) async throws -> String {

        let session: LanguageModelSession
        if let cached = sessions[contextId] {
            session = cached
        } else {
            session = LanguageModelSession(
                instructions: systemPrompt(subjectName: subjectName, contextText: contextText)
            )
            sessions[contextId] = session
        }

        let response = try await session.respond(to: userMessage)
        return response.content
    }


    // Sends the assistant prompt to the hosted chat-compatible endpoint.
    private func sendViaHTTP(
        userMessage: String,
        contextText: String,
        subjectName: String,
        history: [ChatMessage]
    ) async throws -> String {
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt(subjectName: subjectName, contextText: contextText)]
        ]
        for msg in history.suffix(10) {
            guard msg.role != .error else { continue }
            messages.append(["role": msg.role == .user ? "user" : "assistant", "content": msg.content])
        }
        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = ["messages": messages, "temperature": 0.5, "max_tokens": 1024]

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Server returned \(code)"])
        }
        guard
            let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw URLError(.cannotParseResponse) }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // Creates the guardrails and subject/resource context used by both AI backends.
    private func systemPrompt(subjectName: String, contextText: String) -> String {
        """
        You are a helpful AI study assistant for the subject "\(subjectName)".
        Answer questions clearly and concisely based on the study material provided below.
        If the answer is not in the material, say so honestly rather than guessing.
        Be encouraging and student-friendly.

        --- STUDY MATERIAL ---
        \(String(contextText.prefix(8000)))
        --- END OF MATERIAL ---
        """
    }

    // Turns a generated study path topic into compact text for the assistant context.
    private func topicSummary(_ topic: StudyPathTopic) -> String {
        var parts: [String] = ["Topic: \(topic.title)"]
        if !topic.description.isEmpty { parts.append("Overview: \(topic.description)") }
        if !topic.subtopics.isEmpty   { parts.append("Key concepts: \(topic.subtopics.joined(separator: ", "))") }
        return parts.joined(separator: "\n")
    }
}
