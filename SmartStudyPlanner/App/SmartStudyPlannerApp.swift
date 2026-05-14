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
                print("Unknown")
            }
            Task {
                do {
                    let session = LanguageModelSession()
                    let response = try await session.respond(to: "Say hello in one short sentence.")
                    print("Simple FM response:", response.content)
                } catch {
                    print("Simple FM failed:", error)
                }
            }
        }

        // print("--- Listing Bundle Resources ---")
        // if let resourcePath = Bundle.main.resourcePath {
        //     do {
        //         let items = try FileManager.default.subpathsOfDirectory(atPath: resourcePath)
        //         for item in items { print("Resource found: \(item)") }
        //     } catch {
        //         print("Could not list directory: \(error)")
        //     }
        // }
        // print("-------------------------------")

        copySeedAssetsIfNeeded()
        
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

    // Copies bundled demo data files to Documents on first launch so that
    // Firestore resources can resolve their localFilePath immediately.
    private func copySeedAssetsIfNeeded() {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        let demoFiles = [
            "41C4FD8C-F117-4199-A8A5-3D2A8B26AD28.m4a", 
            "B4773C04-4BA6-49CC-A498-E34F0766F563_web_api_concepts.pdf", 
            "F8A8256D-4D72-4D75-8047-6F64800E48B4_Types of Neural Networks.pdf",
            "Scanned REST Basics Lec - 4F08B7.pdf"
        ]

        for filename in demoFiles {
            let destination = docsURL.appendingPathComponent(filename)

            guard !fileManager.fileExists(atPath: destination.path) else { continue }

            let nsFilename = filename as NSString
            let name = nsFilename.deletingPathExtension
            let ext  = nsFilename.pathExtension

            if let source = Bundle.main.url(forResource: name, withExtension: ext) {
                try? fileManager.copyItem(at: source, to: destination)
            }
        }
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
