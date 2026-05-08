import Foundation
import SwiftUI
import Combine

// Coordinates the Settings screens with the cached profile, Firebase profile, and user settings.
// Most settings save immediately when a toggle, slider, or menu changes.
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

    // Creates a SwiftUI binding that updates the local settings object and then persists the change.
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

    // Loads profile/settings from cache first when possible, then refreshes settings from Firebase.
    // If no remote settings exist yet, it creates a default settings object for this user.
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

    // Saves settings optimistically to Core Data, then marks them synced after Firebase accepts the update.
    // Daily goal notifications are rescheduled after a successful save because their timing may have changed.
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

            NotificationService.shared.rescheduleDailyGoalAlert(settings: synced)
        } catch {
        }
    }

    // Saves editable profile fields and stores the selected avatar image locally before updating the Firebase profile.
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
        } catch {
            print("Error saving profile: \(error)")
        }
        
    }

    func updateUser(_ user: SettingsUser) {
        settingsUser = user
        Task {
            await save()
        }
    }

    // Profile images are stored in the app's documents directory and the filename is saved on the user profile.
    static func localImageURL(for path: String) -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let filename = (path as NSString).lastPathComponent
        return documents.appendingPathComponent(filename)
    }
}
