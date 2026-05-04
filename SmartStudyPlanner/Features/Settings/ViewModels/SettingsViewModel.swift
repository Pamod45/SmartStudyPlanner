import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: UserSettings = .default
    @Published var settingsUser: SettingsUser = SettingsUser(
        name: "",
        email: "",
        domain: "",
        institute: "",
        username: ""
    )
    @Published var isLoading: Bool = false
    
    @Published var localSettings = LocalSettingsManager()

    init() {
        if let user = CoreDataService.shared.getCachedProfile() {
            var avatarImage: UIImage? = nil
            if let path = user.profileImageURL, let url = Self.localImageURL(for: path), let data = try? Data(contentsOf: url) {
                avatarImage = UIImage(data: data)
            }
            
            settingsUser = SettingsUser(
                name: user.displayName,
                email: user.email,
                domain: user.domain ?? "",
                institute: user.institute ?? "",
                username: user.username ?? "",
                avatarImage: avatarImage
            )
        }
    }

    func binding<T>(for keyPath: WritableKeyPath<UserSettings, T>) -> Binding<T> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { newValue in
                var updated = self.settings
                updated[keyPath: keyPath] = newValue
                self.settings = updated
                Task { await self.saveSettings() }
            }
        )
    }

    func updateSettings(_ update: (inout UserSettings) -> Void) {
        var updated = settings
        update(&updated)
        settings = updated
        Task { await saveSettings() }
    }

    func load(userId: String?) async {
        guard let uid = userId else { return }
        isLoading = true
        defer { isLoading = false }
        if settingsUser.email.isEmpty {
            do {
                let user = try await UserService.shared.fetchUserProfile(userId: uid)
                
                var avatarImage: UIImage? = nil
                if let path = user.profileImageURL, let url = Self.localImageURL(for: path), let data = try? Data(contentsOf: url) {
                    avatarImage = UIImage(data: data)
                }
                
                settingsUser = SettingsUser(
                    name: user.displayName,
                    email: user.email,
                    domain: user.domain ?? "",
                    institute: user.institute ?? "",
                    username: user.username ?? "",
                    avatarImage: avatarImage
                )
            } catch {
                print("Error loading profile: \(error)")
            }
        }

        if let cachedSettings = CoreDataService.shared.getCachedSettings(for: uid) {
            settings = cachedSettings
        }

        do {
            let remoteSettings = try await UserService.shared.fetchUserSettings(userId: uid)
            settings = remoteSettings
        } catch {
            if settings.userId.isEmpty {
                var defaults = UserSettings.default
                defaults.userId = uid
                defaults.id = uid
                settings = defaults
                CoreDataService.shared.cacheSettings(defaults)
            }
        }
    }

    func saveSettings() async {
        guard !settings.userId.isEmpty else { return }
        var updated = settings
        updated.updatedAt = Date()
        updated.syncStatus = .pendingUpdate
        settings = updated
        CoreDataService.shared.cacheSettings(updated)

        do {
            try await UserService.shared.updateSettings(updated)
            var synced = updated
            synced.syncStatus = .synced
            settings = synced
            CoreDataService.shared.cacheSettings(synced)
        } catch {
        }
    }

    func save() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let cached = CoreDataService.shared.getCachedProfile() else { return }
        
        var updated = cached
        updated.displayName = settingsUser.name
        updated.domain = settingsUser.domain
        updated.institute = settingsUser.institute
        updated.username = settingsUser.username
        
        if let avatar = settingsUser.avatarImage {
            // Save the image locally and get the relative path
            let fileName = "avatar_\(updated.id).jpg"
            if let url = Self.localImageURL(for: fileName), let data = avatar.jpegData(compressionQuality: 0.8) {
                do {
                    try data.write(to: url)
                    updated.profileImageURL = fileName
                } catch {
                    print("Failed to save avatar locally: \(error)")
                }
            }
        }
        
        do {
            try await UserService.shared.updateProfile(user: updated)
            // also trigger a cache refresh here
        } catch {
            print("Error saving profile: \(error)")
        }
        
        // Example: Save UserSettings to Core Data and Firebase
        // CoreDataService.shared.cacheSettings(self.settings)
        // try? await UserService.shared.updateSettings(self.settings)
    }

    func updateUser(_ user: SettingsUser) {
        settingsUser = user
        Task {
            await save()
        }
    }

    // Helper to get local document directory
    static func localImageURL(for path: String) -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        // If the path is somehow already an absolute string, or just a filename
        let filename = (path as NSString).lastPathComponent
        return documents.appendingPathComponent(filename)
    }
}
