# SmartStudyPlanner Testing

This file tracks the current test coverage by module and the main cases each test file covers.

## Authentication

Test file: `SmartStudyPlannerTests/AuthenticationTests.swift`

These tests exercise the authentication flow through the existing app services.

- `testEmailPasswordSignInSucceeds`
  - Verifies that email/password sign in returns an `AppUser`.
  - Checks that the returned user has an id and the expected email.

- `testEmailPasswordSignInFailsWithWrongPassword`
  - Verifies that sign in fails when the password is incorrect.

- `testCurrentUserCanBeRestoredAfterSignIn`
  - Signs in first, then verifies `AuthService.getCurrentUser()` restores the same user.

- `testSignOutClearsAuthenticatedUser`
  - Signs in, signs out, then verifies Firebase current user and app restore state are cleared.

- `testProfileIsCachedAfterSignIn`
  - Verifies that signing in stores the user profile in Core Data through `CoreDataService`.

- `testFaceIDSignInFailsWithoutSavedCredentials`
  - Verifies Face ID sign in fails cleanly when no saved credentials exist.

Required user setup for Firebase-backed tests:

- Add `AUTH_TEST_EMAIL` and `AUTH_TEST_PASSWORD` to the Xcode test scheme environment variables.
- Use a test Firebase account, not a personal account.
- If these values are not set, the Firebase-backed authentication tests are skipped.

## User Models

Test file: `SmartStudyPlannerTests/UserTests.swift`

- `testAppUserFirestoreDataMapping`
  - Verifies `AppUser` maps expected fields into Firestore data.

- `testAppUserInitFromDictionary`
  - Verifies Firestore-style dictionary data can be converted into an `AppUser`.

- `testAppUserInitFailsWithoutRequiredFields`
  - Verifies `AppUser` creation fails when required fields are missing.

## Study Schedule

Test file: `SmartStudyPlannerTests/StudyScheduleServiceTests.swift`

- `testScheduleGeneratesCorrectSessions`
  - Verifies schedule generation creates sessions inside available time.
  - Checks total scheduled duration and break duration between sessions.

- `testScheduleWithInsufficientTime`
  - Verifies no sessions are generated when available time is less than the minimum session duration.

## Study Path

Test file: `SmartStudyPlannerTests/StudyPathTests.swift`

- `testStudyPathTopicCalculations`
  - Verifies estimated minutes/hours and difficulty clamping for normal values.

- `testStudyPathTopicMinimumDefaults`
  - Verifies minimum estimated duration and minimum difficulty clamping.

- `testStudyPathTopicFirestoreMapping`
  - Verifies `StudyPathTopic` maps expected fields into Firestore data.

## Subject Workspace

Test file: `SmartStudyPlannerTests/SubjectWorkspaceTests.swift`

These tests cover subject workspace behavior around resources, deadlines, study paths, and quiz attempts. Firebase-backed tests create temporary subjects and clean them up after running.

- `testResourceCreateFetchDeleteUpdatesSubjectCache`
  - Creates a resource for a temporary subject.
  - Verifies it can be fetched, cached in Core Data, and reflected in the subject resource count/resource ids.
  - Deletes the resource and verifies it is removed.

- `testDeadlineCreateFetchDeleteUpdatesSubject`
  - Creates a deadline for a temporary subject.
  - Verifies it can be fetched, cached in Core Data, and linked to the subject deadline ids.
  - Deletes the deadline and verifies it is removed.

- `testStudyPathSaveFetchDeletePreservesOrderAndTopicCount`
  - Saves generated study path topics for a temporary subject.
  - Verifies fetch order and subject topic count.
  - Deletes the study path and verifies the local topic count is cleared.

- `testQuizAttemptSaveFetchDeletePreservesQuestionsAndScore`
  - Saves a quiz attempt with questions and selected answers.
  - Verifies fetched attempt data, selected answers, correct count, and score percent.
  - Deletes the attempt and verifies it is removed.

- `testQuizAttemptHandlesEmptyAndPartialAnswers`
  - Verifies quiz score behavior for empty and partially answered attempts.
  - Checks time formatting used by quiz result views.

- `testSubjectAndStudyPathMappingHandlesCountsAndResourceIds`
  - Verifies subject count/id mapping.
  - Verifies study path topic resource ids, estimated minutes, and difficulty clamping.

Required user setup for Firebase-backed subject workspace tests:

- Add `AUTH_TEST_EMAIL` and `AUTH_TEST_PASSWORD` to the Xcode test scheme environment variables.
- Use a test Firebase account.
- If these values are not set, the Firebase-backed subject workspace tests are skipped.

## Quiz

Test file: `SmartStudyPlannerTests/QuizTests.swift`

- `testQuizAttemptCalculations`
  - Verifies correct count, score percent, points, pass/fail state, accuracy label, and formatted time.

- `testQuizAttemptPerfectScore`
  - Verifies perfect score calculations and pass/high accuracy state.

## Notifications

Test file: `SmartStudyPlannerTests/NotificationTests.swift`

- `testNotificationTypeProperties`
  - Verifies notification type icons.

- `testNotificationDateStringJustNow`
  - Verifies date display for a newly created notification.

- `testNotificationDateStringHoursAgo`
  - Verifies date display for older notifications.

## Study Plan

Test file: `SmartStudyPlannerTests/StudyPlanTests.swift`

These are pure unit tests with no Firebase, Core Data, or device API dependencies.

- `testAvailabilitySlotAppliesOnSpecificDateAndNotOtherDays`
  - Verifies a `.specificDate` slot matches only its own date and not adjacent days.

- `testAvailabilitySlotAppliesWithinDateRangeBoundaries`
  - Verifies a `.dateRange` slot applies on the first day, last day, and a mid-range day.
  - Verifies the slot does not apply before the range start or after the range end.

- `testStudySessionComputedDurationProperties`
  - Verifies `durationMinutes`, `duration`, `startHour`, and `endHour` for a 10:00–11:30 session.

- `testStudyPlanProgressPercentageClampsAtHundred`
  - Verifies `progressPercentage` returns 0 when `targetHours` is 0.
  - Verifies the correct percentage when partially complete.
  - Verifies the result clamps to 100 when completed hours exceed the target.

- `testSchedulerPrioritizesTopicWithNearerDeadline`
  - Schedules two subjects with identical topics but different deadline pressures.
  - Verifies the subject with the nearer deadline is scheduled first.

- `testSchedulerSpreadsTopicAcrossMultipleBlocks`
  - Schedules a 90-minute topic against two separate 60-minute availability slots on different days.
  - Verifies exactly two sessions are created totalling 90 minutes, both referencing the same topic.

## Progress

Test file: `SmartStudyPlannerTests/ProgressTests.swift`

These are pure unit tests with no Firebase, Core Data, or device API dependencies.

- `testWeeklySnapshotGoalCompletionPercentageClamps`
  - Verifies `WeeklyProgressSnapshot.goalCompletionPercentage` returns 0 when `goalHours` is 0.
  - Verifies the correct percentage for a partially completed week.
  - Verifies the result clamps to 100 when hours studied exceed the goal.

- `testSubjectDistributionIsEmptyWithNoCompletedSessions`
  - Verifies `subjectDistribution` returns an empty array when `completedSessions` is empty.

- `testSubjectDistributionPercentagesMatchStudyTime`
  - Sets two completed sessions (60 min Algebra, 30 min Biology) directly on the view model.
  - Verifies the distribution percentages are 2/3 and 1/3 respectively.
  - Verifies the result is sorted descending by percentage.

- `testStreakIsZeroForEmptySessions`
  - Verifies `computeStreak` returns currentStreak = 0, longestStreak = 0, and nil lastStudyDate for empty input.

- `testStreakCountsConsecutiveDaysAndResetsOnGap`
  - Passes sessions for today and yesterday (current run of 2) plus four sessions on days 5–8 ago (run of 4).
  - Verifies currentStreak = 2 and longestStreak = 4.
  - Verifies the gap at day-2 correctly resets the current streak count.

## Settings

Test file: `SmartStudyPlannerTests/SettingsTests.swift`

These are pure unit tests with no Firebase, Core Data, or device API dependencies. `setUp` and `tearDown` clean the four `UserDefaults` keys owned by `LocalSettingsManager` so tests cannot affect each other.

- `testUserSettingsDefaultValues`
  - Verifies the eight most important fields in `UserSettings.default` match their expected values.
  - Acts as a regression guard against accidental changes that would affect all new users.

- `testUserSettingsFirestoreRoundTrip`
  - Serializes a customised `UserSettings` to `firestoreData` and deserializes it with `init?(from:userId:)`.
  - Verifies numeric fields, theme enum, booleans, and `syncStatus` all survive the round trip.

- `testUserSettingsInitUsesSystemThemeForUnknownValue`
  - Passes an unrecognised theme string to `init?(from:userId:)`.
  - Verifies the result safely defaults to `.system` instead of crashing or producing a blank UI state.

- `testUserSettingsFirestoreDataClampsOutOfRangeDates`
  - Sets `dailyGoalAlertTime` to a date far outside Firestore's accepted range.
  - Verifies `firestoreData` replaces it with the 09:00 fallback so Firestore never receives a rejected value.

- `testLocalSettingsManagerPersistsAccessibilityPreferences`
  - Sets `textSize`, `reduceMotion`, and `highContrast` on one `LocalSettingsManager` instance.
  - Creates a second instance and verifies all three values were persisted to `UserDefaults` via `didSet`.

- `testSettingsViewModelLocalImageURLBuildsDocumentsPath`
  - Calls the static `SettingsViewModel.localImageURL(for:)` helper with a plain filename.
  - Verifies the returned URL has the correct last path component and sits inside the Documents directory.

---

## Notes

- Pure unit tests (Study Plan, Progress, Settings) run fully offline with no credentials.
- Authentication and Subject Workspace tests hit real Firebase and are skipped automatically when credentials are not set.
- Avoid committing real credentials. Keep test credentials in the Xcode scheme environment variables only.

---

## Running Tests

### Run all tests at once

**Xcode:** Press `Cmd + U` with any file open, or go to **Product → Test**.

**Terminal:**
```
xcodebuild test \
  -project SmartStudyPlanner.xcodeproj \
  -scheme SmartStudyPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Run a single test class

**Xcode:** Click the diamond icon next to the class declaration in the editor gutter, or right-click the class in the Test navigator and choose **Run**.

**Terminal:**
```
xcodebuild test \
  -project SmartStudyPlanner.xcodeproj \
  -scheme SmartStudyPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SmartStudyPlannerTests/SettingsTests
```

Replace `SettingsTests` with any of the class names below:

| Class | File |
|---|---|
| `AuthenticationTests` | AuthenticationTests.swift |
| `UserTests` | UserTests.swift |
| `StudyScheduleServiceTests` | StudyScheduleServiceTests.swift |
| `StudyPathTests` | StudyPathTests.swift |
| `SubjectWorkspaceTests` | SubjectWorkspaceTests.swift |
| `QuizTests` | QuizTests.swift |
| `NotificationTests` | NotificationTests.swift |
| `StudyPlanTests` | StudyPlanTests.swift |
| `ProgressTests` | ProgressTests.swift |
| `SettingsTests` | SettingsTests.swift |

### Run a single test method

**Xcode:** Click the diamond icon next to the method in the editor gutter.

**Terminal:**
```
xcodebuild test \
  -project SmartStudyPlanner.xcodeproj \
  -scheme SmartStudyPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SmartStudyPlannerTests/SettingsTests/testUserSettingsDefaultValues
```

### Run only offline unit tests (no Firebase required)

```
xcodebuild test \
  -project SmartStudyPlanner.xcodeproj \
  -scheme SmartStudyPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SmartStudyPlannerTests/UserTests \
  -only-testing SmartStudyPlannerTests/StudyScheduleServiceTests \
  -only-testing SmartStudyPlannerTests/StudyPathTests \
  -only-testing SmartStudyPlannerTests/QuizTests \
  -only-testing SmartStudyPlannerTests/NotificationTests \
  -only-testing SmartStudyPlannerTests/StudyPlanTests \
  -only-testing SmartStudyPlannerTests/ProgressTests \
  -only-testing SmartStudyPlannerTests/SettingsTests
```

### Run only Firebase-backed tests

Set credentials in the scheme first, then:

```
xcodebuild test \
  -project SmartStudyPlanner.xcodeproj \
  -scheme SmartStudyPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SmartStudyPlannerTests/AuthenticationTests \
  -only-testing SmartStudyPlannerTests/SubjectWorkspaceTests
```

### Set Firebase credentials for the scheme

1. In Xcode open **Product → Scheme → Edit Scheme** (`Cmd + <`).
2. Select the **Test** action in the left panel.
3. Open the **Arguments** tab.
4. Under **Environment Variables** add:
   - `AUTH_TEST_EMAIL` — email of a dedicated test account
   - `AUTH_TEST_PASSWORD` — password of that account
5. Use a throwaway Firebase account, never a personal one.
6. These variables are stored in the local `.xcscheme` file and are not committed to source control.
