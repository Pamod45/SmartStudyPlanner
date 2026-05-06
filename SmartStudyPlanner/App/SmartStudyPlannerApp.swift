//
//  SmartStudyPlannerApp.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-03-23.
//

import SwiftUI
import FirebaseCore
import FoundationModels

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      if #available(iOS 26.0, *) {
          let model = SystemLanguageModel.default
          print("=== FOUNDATION MODEL STATUS ===")
          print("Availability: \(model.availability)")
          
          switch model.availability {
          case .available:
              print("✅ Model is fully ready")
          case .unavailable(let reason):
              print("❌ Reason: \(reason)")
          @unknown default:
              print("❓ Unknown")
          }
      }
      print("--- Listing Bundle Resources ---")
      if let resourcePath = Bundle.main.resourcePath {
          do {
              let items = try FileManager.default.subpathsOfDirectory(atPath: resourcePath)
              for item in items {
                  print("Resource found: \(item)")
              }
          } catch {
              print("Could not list directory: \(error)")
          }
      }
      print("-------------------------------")
    FirebaseApp.configure()
    return true
  }
}

@main
struct SmartStudyPlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var localSettings = LocalSettingsManager()
    
    var body: some Scene {
        
        WindowGroup {
            
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(sessionViewModel)
                .environmentObject(localSettings)
                .environment(\.theme, themeManager.current)
                .task {
                    await sessionViewModel.restoreSession()
                }
        }
    }
}
