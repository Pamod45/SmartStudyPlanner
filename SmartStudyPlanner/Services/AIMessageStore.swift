import Foundation
import Combine

@MainActor
final class AIMessageStore: ObservableObject {
    static let shared = AIMessageStore()
    private init() {}

    @Published private var store: [String: [ChatMessage]] = [:]

    func messages(for contextId: String) -> [ChatMessage] {
        store[contextId] ?? []
    }

    func append(_ message: ChatMessage, for contextId: String) {
        store[contextId, default: []].append(message)
    }

    func clearAll() {
        store = [:]
    }
}
