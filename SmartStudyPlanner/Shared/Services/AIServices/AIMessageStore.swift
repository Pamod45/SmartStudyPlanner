import Foundation
import Combine

// In-memory chat history store keyed by assistant context.
// It is cleared on sign out so one user does not see another user's chat history.

@MainActor
final class AIMessageStore: ObservableObject {
    static let shared = AIMessageStore()
    private init() {}

    @Published private var store: [String: [ChatMessage]] = [:]
    private var selectedContextIds: [String: String] = [:]

    func messages(for contextId: String) -> [ChatMessage] {
        store[contextId] ?? []
    }

    func append(_ message: ChatMessage, for contextId: String) {
        store[contextId, default: []].append(message)
    }

    func savedContextId(for subjectId: String) -> String? {
        selectedContextIds[subjectId]
    }

    func saveContextId(_ contextId: String, for subjectId: String) {
        selectedContextIds[subjectId] = contextId
    }

    func clearAll() {
        store = [:]
        selectedContextIds = [:]
    }
}
