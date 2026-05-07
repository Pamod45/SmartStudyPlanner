//
//  NotificationStore.swift
//  SmartStudyPlanner
//
//  Persists and publishes the in-app notification history ([AppNotification]).
//  This is the ONLY class that reads/writes the history list.
//  Other parts of the app observe `NotificationStore.shared` via @EnvironmentObject
//  or directly through the singleton.
//

import Foundation
import Combine

final class NotificationStore: ObservableObject {


    static let shared = NotificationStore()
    private init() {}


    @Published private(set) var notifications: [AppNotification] = []

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }


    private let storageKey = "notificationHistory"
    private let maxEntries = 200


    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let decoded = try? decoder.decode([AppNotification].self, from: data) {
            notifications = decoded
        }
    }

    func record(_ notification: AppNotification) {
        var updated = notification
        updated.isRead = false
        notifications.removeAll { $0.id == updated.id }
        notifications.insert(updated, at: 0)
        trim()
        persist()
    }

    func markDelivered(id: String) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[idx].deliveredAt = Date()
        notifications[idx].updatedAt   = Date()
        persist()
    }

    func markRead(id: String) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        guard !notifications[idx].isRead else { return }
        notifications[idx].isRead    = true
        notifications[idx].updatedAt = Date()
        persist()
    }

    func markAllRead() {
        var changed = false
        for idx in notifications.indices where !notifications[idx].isRead {
            notifications[idx].isRead    = true
            notifications[idx].updatedAt = Date()
            changed = true
        }
        if changed { persist() }
    }

    func delete(id: String) {
        notifications.removeAll { $0.id == id }
        persist()
    }

    func delete(ids: Set<AppNotification.ID>) {
        notifications.removeAll { ids.contains($0.id) }
        persist()
    }

    func deleteAll() {
        notifications.removeAll()
        persist()
    }


    private func trim() {
        if notifications.count > maxEntries {
            notifications = Array(notifications.prefix(maxEntries))
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(notifications) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
