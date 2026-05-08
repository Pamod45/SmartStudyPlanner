//
//  SmartStudyPlannerApp.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-23.
//

import SwiftUI
import FirebaseCore
import FoundationModels
import UserNotifications


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // Sets up Firebase and notification handling before any SwiftUI screens start using those services.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            print("=== FOUNDATION MODEL STATUS ===")
            print("Availability: \(model.availability)")
            switch model.availability {
            case .available:
                print("Model is fully ready")
            case .unavailable(let reason):
                print("Reason: \(reason)")
            @unknown default:
                print("❓ Unknown")
            }
        }

        print("--- Listing Bundle Resources ---")
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let items = try FileManager.default.subpathsOfDirectory(atPath: resourcePath)
                for item in items { print("Resource found: \(item)") }
            } catch {
                print("Could not list directory: \(error)")
            }
        }
        print("-------------------------------")

        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self

        NotificationService.shared.requestAuthorisation()
        NotificationStore.shared.load()

        return true
    }


    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Keep foreground notifications visible and also store them for the in-app notification list.
        recordDelivered(notification.request)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // A tapped notification is also recorded so the notification history stays consistent.
        recordDelivered(response.notification.request)
        completionHandler()
    }


    // Converts the system notification payload back into the app's notification model.
    private func recordDelivered(_ request: UNNotificationRequest) {
        let content    = request.content
        let id         = request.identifier
        let typeRaw    = content.userInfo["type"]        as? String ?? ""
        let userId     = content.userInfo["userId"]      as? String ?? ""
        let refId      = content.userInfo["referenceId"] as? String

        let notifType  = NotificationType(rawValue: typeRaw) ?? .general

        let notif = AppNotification(
            id: id,
            userId: userId,
            title: content.title,
            message: content.body,
            notificationType: notifType,
            referenceId: refId,
            isRead: false,
            scheduledAt: Date(),
            deliveredAt: Date()
        )

        NotificationStore.shared.record(notif)
    }
}


@main
struct SmartStudyPlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var themeManager      = ThemeManager()
    @StateObject private var sessionViewModel  = SessionViewModel()
    @StateObject private var localSettings     = LocalSettingsManager()
    @StateObject private var notificationStore = NotificationStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(sessionViewModel)
                .environmentObject(localSettings)
                .environmentObject(notificationStore)
                .environment(\.theme, themeManager.current)
                .task {
                    // Restore Firebase/local session first, then load user-specific settings and reminder schedules.
                    await sessionViewModel.restoreSession()

                    if let userId = sessionViewModel.activeUserId, !userId.isEmpty {
                        let sessions  = (try? await StudySessionService.shared.fetchAll(userId: userId)) ?? []
                        let deadlines = (try? await DeadlineService.shared.fetchAllDeadlines(userId: userId)) ?? []
                        let settings  = CoreDataService.shared.getCachedSettings(for: userId) ?? .default
                        
                        themeManager.update(
                            highContrast: settings.highContrastEnabled,
                            darkMode: settings.darkModeEnabled,
                            fontSize: settings.accessibilityFontSize
                        )
                        
                        NotificationService.shared.rescheduleAll(
                            sessions: sessions,
                            deadlines: deadlines,
                            settings: settings
                        )
                    }
                }
        }
    }
}
