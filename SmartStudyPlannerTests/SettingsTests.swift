import XCTest
@testable import SmartStudyPlanner

final class SettingsTests: XCTestCase {

    // UserDefaults keys written by LocalSettingsManager
    private let udKeys = [
        "accessibilityTextSize",
        "accessibilityReduceMotion",
        "accessibilityHighContrast",
        "securityFaceIDEnabled"
    ]

    override func setUp() {
        super.setUp()
        udKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        udKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    // MARK: - UserSettings.default

    func testUserSettingsDefaultValues() {
        let s = UserSettings.default

        XCTAssertEqual(s.dailyStudyGoalHours, 3.0,
                       "Default daily goal should be 3 hours — change requires intentional update")
        XCTAssertEqual(s.weeklyStudyGoalDays, 5)
        XCTAssertEqual(s.preferredSessionDurationMinutes, 60)
        XCTAssertEqual(s.breakDurationMinutes, 10)
        XCTAssertEqual(s.sessionReminderMinutesBefore, 15)
        XCTAssertEqual(s.theme, .system,
                       "Default theme must be .system so it follows the device setting")
        XCTAssertFalse(s.calendarSyncEnabled,
                       "Calendar sync must be opt-in — off by default")
        XCTAssertTrue(s.notificationsEnabled)
    }

    // MARK: - Firestore serialization round-trip

    func testUserSettingsFirestoreRoundTrip() {
        var original = UserSettings.default
        original.userId = "user-roundtrip"
        original.dailyStudyGoalHours = 4.5
        original.weeklyStudyGoalDays = 6
        original.preferredSessionDurationMinutes = 45
        original.theme = .dark
        original.calendarSyncEnabled = true
        original.notificationsEnabled = false
        original.sessionReminderMinutesBefore = 30
        original.syncStatus = .synced

        let data = original.firestoreData

        guard let restored = UserSettings(from: data, userId: "user-roundtrip") else {
            XCTFail("init?(from:userId:) returned nil for valid Firestore data")
            return
        }

        XCTAssertEqual(restored.dailyStudyGoalHours, 4.5)
        XCTAssertEqual(restored.weeklyStudyGoalDays, 6)
        XCTAssertEqual(restored.preferredSessionDurationMinutes, 45)
        XCTAssertEqual(restored.theme, .dark)
        XCTAssertTrue(restored.calendarSyncEnabled)
        XCTAssertFalse(restored.notificationsEnabled)
        XCTAssertEqual(restored.sessionReminderMinutesBefore, 30)
        XCTAssertEqual(restored.syncStatus, .synced)
    }

    // MARK: - Firestore init defensive fallbacks

    func testUserSettingsInitUsesSystemThemeForUnknownValue() {
        // An invalid theme string from a future or mismatched app version should not crash.
        let data: [String: Any] = ["theme": "unicorn_theme"]
        let settings = UserSettings(from: data, userId: "u-theme-test")

        XCTAssertEqual(settings?.theme, .system,
                       "Unknown theme rawValue must fall back to .system to avoid a blank UI state")
    }

    // MARK: - Date clamping safety in firestoreData

    func testUserSettingsFirestoreDataClampsOutOfRangeDates() {
        var settings = UserSettings.default
        // -99_999_999_999 seconds is far before the Unix epoch minimum —
        // Firestore rejects dates outside its valid range, so clampDate must replace it.
        settings.dailyGoalAlertTime = Date(timeIntervalSince1970: -99_999_999_999)

        let data = settings.firestoreData
        let savedDate = data["dailyGoalAlertTime"] as? Date

        XCTAssertNotNil(savedDate,
                        "dailyGoalAlertTime must always be present in firestoreData")

        // The fallback for dailyGoalAlertTime is today at 09:00
        let cal = Calendar.current
        XCTAssertEqual(cal.component(.hour, from: savedDate!), 9,
                       "Out-of-range date should be clamped to the 09:00 fallback hour")
        XCTAssertEqual(cal.component(.minute, from: savedDate!), 0,
                       "Out-of-range date should be clamped to :00 minutes")
    }

    // MARK: - LocalSettingsManager UserDefaults persistence

    func testLocalSettingsManagerPersistsAccessibilityPreferences() {
        // Avoid constructing the ObservableObject in this unit test; iOS 26 simulator
        // can crash during Combine teardown in app-hosted tests.
        LocalSettingsManager.persistTextSize(1.25)
        LocalSettingsManager.persistReduceMotion(true)
        LocalSettingsManager.persistHighContrast(true)

        XCTAssertEqual(UserDefaults.standard.double(forKey: "accessibilityTextSize"), 1.25,
                       accuracy: 0.001)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "accessibilityReduceMotion"),
                      "reduceMotion must write true to UserDefaults")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "accessibilityHighContrast"),
                      "highContrast must write true to UserDefaults")
    }

    // MARK: - SettingsViewModel static helpers

    @MainActor func testSettingsViewModelLocalImageURLBuildsDocumentsPath() {
        let filename = "avatar_unit-test-user.jpg"
        guard let url = SettingsViewModel.localImageURL(for: filename) else {
            XCTFail("localImageURL should return a non-nil URL for a plain filename")
            return
        }

        XCTAssertEqual(url.lastPathComponent, filename,
                       "URL last component must match the provided filename exactly")
        XCTAssertTrue(url.path.contains("Documents"),
                      "Profile images must be stored under the Documents directory")
    }
}
