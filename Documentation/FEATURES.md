# SmartStudyPlanner — Features & Application Flows

A reference document describing every major feature, how it works, and the data flow behind it. Intended for anyone who wants to understand the app without reading the source code.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Authentication](#authentication)
3. [Dashboard](#dashboard)
4. [Subjects & Workspace](#subjects--workspace)
5. [Study Plan](#study-plan)
6. [Progress](#progress)
7. [Settings](#settings)
8. [AI Features](#ai-features)
9. [Data Layer](#data-layer)
10. [Notifications](#notifications)

---

## Architecture Overview

SmartStudyPlanner is a SwiftUI iOS app structured around five main tabs. Each tab owns a `ViewModel` that coordinates between the UI and a set of services. Services talk to Firebase Firestore for remote storage and mirror results into Core Data for fast offline loading.

```
UI (SwiftUI Views)
      │
      ▼
ViewModels  (@MainActor, @Published state)
      │
      ├── Services  (Firebase Firestore reads/writes)
      │       └── CoreDataService  (local cache, always updated after remote call)
      │
      └── LocalSettingsManager  (UserDefaults — device-only prefs)
```

**Key principle:** Every remote write also updates the local Core Data cache. Screens load cached data first on open and replace it silently when Firebase responds. This means the app works immediately even on a slow connection.

---

## Authentication

### Supported methods
- Email and password (Firebase Auth)
- Google Sign-In (OAuth via Firebase)
- Face ID (biometric unlock using saved credentials)

### Sign-in flow

```
User enters email + password
        │
        ▼
AuthService.signIn(email:password:)
        │
        ▼
Firebase Auth returns FirebaseAuth.User
        │
        ▼
UserService.fetchUserProfile(userId:)  ──► Firestore users/{uid}
        │
        ▼
CoreDataService.cacheProfile(user)  ──► Core Data (offline copy)
        │
        ▼
AuthViewModel publishes AppUser  ──► App navigates to main tabs
```

### Face ID flow

Face ID uses credentials saved in `UserDefaults` (`faceId_email`, `faceId_password`). When enabled in Settings it runs a full email/password sign-in after biometric verification succeeds — it does not store a Firebase token.

```
User taps "Sign in with Face ID"
        │
        ▼
LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)
        │
   success?
   YES ──► read saved email+password from UserDefaults
           └──► AuthService.signIn(email:password:)  (same flow as above)
   NO  ──► show error, do not attempt sign-in
```

### Sign-out

`AuthService.signOut()` calls `Auth.auth().signOut()`. The app clears the active user session, removes Core Data cached profile, and returns to the login screen.

---

## Dashboard

The Dashboard is the first screen after sign-in. It gives a quick snapshot of today's study activity.

### What it shows
- **Today's study sessions** — cards for each scheduled or in-progress session with subject colour, time range, and topic
- **Upcoming deadlines** — next deadlines across all subjects sorted by due date
- **Notification feed** — recent app notifications (session reminders, streak alerts, weekly summaries)

### Session rating sheet

When a session is marked complete a `SessionRatingSheet` slides up. The user picks a 1–5 star rating. The rating is saved back to the `StudySession` record in Firebase and used by the Progress module to calculate the average rating stat.

### Data flow

```
DashboardViewModel.load(userId:)
        │
        ├── StudySessionService.fetchAll(userId:)  ──► Firestore
        ├── DeadlineService.fetchDeadlines(...)    ──► Firestore
        └── CoreDataService (cached fallback shown immediately)
```

---

## Subjects & Workspace

Subjects are the top-level container for all study material. Each subject holds resources, deadlines, a study path, and quiz attempts.

### Subject list

The subjects screen lists all active (non-archived) subjects. Each card shows the subject name, colour, icon, resource count, topic count, and upcoming deadline count.

Creating a subject saves it to Firestore and caches it in Core Data. The subject can be archived (hidden from most views) or deleted permanently.

### Resources

Each subject can hold any number of resources:

| Type | Icon | Use |
|---|---|---|
| PDF | doc.richtext.fill | Lecture notes, papers |
| Note | note.text | Text notes written in-app |
| Link | link | URLs to online material |
| Recording | waveform | Audio files |
**Resource flow:**
```
User picks file / pastes URL / writes note
        │
        ▼
ResourceService.createResource(resource)  ──► Firestore resources/{id}
        │
        ▼
CoreDataService.cacheResources([resource])
SubjectService updates subject.resourceCount + resourceIds
```

### Deadlines

Deadlines track assignment or exam due dates. They can be tagged (submission, exam, project, reading, other), prioritised, and optionally linked to a study session.

```
User creates deadline with due date and tag
        │
        ▼
DeadlineService.createDeadline(deadline)  ──► Firestore deadlines/{id}
        │
        ▼
CoreDataService.cacheDeadlines([deadline])
SubjectService updates subject.deadlineIds
        │
        ▼
NotificationService schedules deadline alert (if enabled in settings)
```

### Study Path

A Study Path is an ordered list of topics that breaks a subject into manageable learning chunks. Topics carry:
- **weightPercent** — relative importance (affects scheduler priority)
- **estimatedMinutes** — how long the topic takes to study
- **difficultyLevel** — 1–10 (affects scheduler priority, clamped on init)
- **resourceIds** — links topic to specific resources

Study Paths are generated by the on-device AI model (see [AI Features](#ai-features)) or created manually.

```
User requests AI study path generation
        │
        ▼
On-device LLM generates ordered topic list
        │
        ▼
StudyPathService.saveStudyPath(topics, for: subjectId)  ──► Firestore
        │
        ▼
CoreDataService caches topics
SubjectService updates subject.topicCount
```

### Quizzes

Quizzes are generated from study path topics using the on-device AI. Each quiz attempt records:
- Per-question selected answers
- Correct count and score percentage
- Time spent
- Pass/fail (threshold: 70%)

Quiz scores feed into the Progress module's subject mastery calculation (30% weight).

```
User requests quiz for a topic
        │
        ▼
On-device LLM generates questions (multiple choice, true/false, flashcard)
        │
        ▼
User completes quiz
        │
        ▼
QuizService.saveAttempt(attempt, userId:)  ──► Firestore quizAttempts/{id}
        │
        ▼
ProgressViewModel re-calculates subject mastery on next load
```

---

## Study Plan

The Study Plan tab is a calendar-based planner. It controls when the user studies by managing **availability slots** and **study sessions**.

### Availability slots

An availability slot describes when the user is free. There are two types:

| Type | Description |
|---|---|
| Specific Date | Free on one particular day at a given time window |
| Date Range | Free every day in a date range at the same time window |

Date-range slots are expanded into individual specific-date slots before saving so each day can be managed independently.

**Past dates are rejected** — the UI prevents adding availability for days already gone.

```
User picks a date + time window  (or date range + time window)
        │
        ▼
StudyPlanViewModel.addAvailabilitySlot(slot)
        │
    type == .dateRange?
    YES ──► expandRangeSlot() ──► one slot per day, past days filtered out
    NO  ──► single slot
        │
        ▼
Optimistic update: slot added to @Published array + Core Data immediately
        │
        ▼ (background Task)
AvailabilitySlotService.save(slot)  ──► Firestore availabilitySlots/{id}
```

### Creating study sessions

There are two ways to create sessions:

**Manual session:**
```
User fills AddStudySessionSheet (subject, topic, time)
        │
        ▼
StudyPlanViewModel.addSession(session)
        │
    sessionFitsAnyAvailabilitySlot(session)?
    NO  ──► silently rejected (session falls outside all slots)
    YES ──► add to @Published array + Core Data
             │
             ▼ (background Task)
             StudySessionService.save(session)  ──► Firestore
             CalendarSyncService.export(session)  ──► iOS Calendar (EventKit)
             NotificationService.scheduleSessionReminder(session:settings:)
```

**Auto-generated plan (Create Study Plan sheet):**
```
User selects subjects + topics + date period + break length
        │
        ▼
StudyScheduleService.schedule(entries:slots:period:breakMinutes:minSessionMinutes:)
        │  (pure algorithm — no Firebase, no Core Data)
        │
        ├── expandSlots()  ──► concrete time blocks inside period
        ├── buildQueue()   ──► topics sorted by priority score
        │       priority = (deadlinePressure × 3) + (difficulty × 2) + weight
        │       deadlinePressure = 100 / daysUntilDeadline
        │
        └── fillBlocks()   ──► walks blocks, fills with topic work + breaks
                               a topic too long for one block spills into the next
        │
        ▼
StudyPlanViewModel.addSessions([StudySession])
        │
        ▼ (background Task)
StudySessionService.saveAll(sessions)  ──► Firestore batch write
CalendarSyncService.exportAll(sessions)  ──► iOS Calendar
NotificationService schedules reminders for each session
```

### Removing availability

Deleting an availability slot cascades:
```
User swipes to delete a slot
        │
        ▼
All sessions that fall inside that slot's time window are identified
        │
        ▼
Sessions removed from @Published array + Core Data
Slot removed from @Published array + Core Data
        │
        ▼ (background Task)
CalendarSyncService removes each session's calendar event (if synced)
StudySessionService.deleteAll(ids:)  ──► Firestore batch delete
AvailabilitySlotService.delete(id:)  ──► Firestore
```

### Calendar view

The calendar component decorates each day with colour dots:
- **Blue dot** — has an availability slot
- **Subject-coloured dot** — has a study session
- **Red/orange dot** — has a deadline

Tapping a day shows the slots, sessions, and deadlines for that date.

---

## Progress

The Progress tab calculates and displays study performance metrics from completed sessions, quiz attempts, and saved resources.

> Only sessions with status `.completed` count toward any metric. Scheduled or skipped sessions are excluded.

### Summary stats (this week)

Four stat cards recalculate on each screen appearance:

| Card | Calculation |
|---|---|
| Hours This Week | Sum of `actualDurationMinutes ?? durationMinutes` for completed sessions this week ÷ 60 |
| Sessions Done | Count of completed sessions this week |
| Day Streak | `currentStreak` from streak calculation (see below) |
| Avg Rating | Mean of `rating` values from completed sessions that were rated |

### Subject mastery

Each subject gets a mastery score (0–1) displayed as a percentage:

```
weeklyTargetHours  = (dailyStudyGoalHours × 7) / numberOfActiveSubjects
                     ↑ total daily goal split equally across all non-archived subjects

sessionComponent   = min(hoursStudiedThisWeek / weeklyTargetHours, 1.0)

if subject has quiz attempts:
    averageQuizScore = sum(attempt.scorePercent for this subject) / numberOfAttempts
    quizComponent    = averageQuizScore / 100
    mastery          = (sessionComponent × 0.7) + (quizComponent × 0.3)
else:
    mastery          = sessionComponent
```

Status thresholds:

| Status | Mastery |
|---|---|
| EXCELLENT | ≥ 75% |
| GOOD | ≥ 40% |
| NEEDS FOCUS | < 40% |

### Study streak

The streak algorithm runs over all unique study days (calendar-day granularity):

1. Extract the set of unique days that have at least one completed session.
2. Sort the days and scan forward to find the **longest consecutive run** (longestStreak).
3. Walk backwards from today to count how many consecutive days include today (currentStreak). If today has no session, currentStreak = 0.

### Insights

Four auto-generated text insights appear when enough data exists:

| Tag | Logic |
|---|---|
| PEAK DAY | Weekday with the highest average study minutes across all completed sessions |
| TOP SUBJECT | Subject with the most completed study minutes this week |
| IMPROVING / WATCH OUT | This week's session count vs last week's count |
| NEEDS WORK | Subject with the lowest average quiz score across all attempts |

### Charts

**Daily Activity chart** — line/area chart of study hours per day, filterable by last 7 / 30 / 90 days and by subject. Multiple sessions on the same day are aggregated.

**Subject Distribution chart** — pie chart of each subject's share of all completed study minutes. Percentage = subject minutes / total minutes. Sorted descending.

---

## Settings

Settings are split into two storage layers:

| Layer | Storage | Examples |
|---|---|---|
| Firebase + Core Data | `UserSettings` struct | Study goals, notification timing, theme, integrations |
| Device only | `UserDefaults` via `LocalSettingsManager` | Text size, reduce motion, high contrast, Face ID toggle |

### Profile editing

The user can change display name, domain, institute, and username. A photo picker allows choosing a profile avatar. The image is saved as a JPEG to the app's Documents directory; only the filename is stored on the Firebase profile.

### Study goals

- **Daily study goal** — hours per day (0.5–12). Used by the Progress module to calculate the weekly target and the "Hours This Week" badge colour.
- **Preferred session duration** — default session length pre-filled in the session creator (15–120 min).
- **Break duration** — default break between sessions pre-filled in the plan generator (5–30 min).
- **Preferred study time** — Morning / Afternoon / Evening / Night (used as a hint for future reminder scheduling).

### Notification settings

| Setting | Controls |
|---|---|
| Session reminder | How many minutes before a session to fire a local notification (5 / 10 / 30 / 60) |
| Deadline alert | How many days before a deadline to fire a local notification |
| Daily goal alert | Time of day for the daily goal reminder |
| Quiz pending reminder | Whether to remind the user to take a quiz after completing a session |

All settings save immediately on change. After a successful Firebase save, `NotificationService.rescheduleDailyGoalAlert` is called to update the scheduled notification with the new time.

### Accessibility

Stored in `UserDefaults` — not synced to Firebase because these are device-specific preferences.

- **Text size slider** — 75%–150%, stored as a `Double` multiplier (0.75–1.5). Applied via SwiftUI's `.environment(\.sizeCategory, ...)`.
- **High contrast** — swaps colour scheme to higher-contrast variants via the app theme environment.

### Security (Face ID)

Toggling Face ID on calls `LocalAuthContext.evaluatePolicy` immediately. If authentication fails, the toggle reverts to off. When on, the current email and password are saved to `UserDefaults` (`faceId_email`, `faceId_password`) so the Face ID sign-in flow can re-authenticate without prompting for credentials.
---

## AI Features

SmartStudyPlanner runs AI inference **on-device** using the Transformers and Hub Swift packages — no external AI API calls are made.

### Study Path generation

```
User taps "Generate Study Path" on a subject
        │
        ▼
On-device LLM receives prompt:
  subject name + description + any existing resources
        │
        ▼
Model outputs ordered topic list with:
  title, description, weightPercent, estimatedMinutes, difficultyLevel
        │
        ▼
Topics displayed for review — user can edit before saving
        │
        ▼
StudyPathService.saveStudyPath(topics, for: subjectId)
```

### Quiz generation

```
User selects a study path topic and taps "Generate Quiz"
        │
        ▼
On-device LLM receives prompt:
  topic title + description + linked resource content (if any)
        │
        ▼
Model outputs questions (multiple choice, true/false, flashcard)
  each with correctOptionIndex and optional hint
        │
        ▼
Quiz rendered in-app — user answers, result recorded as QuizAttempt
```

### Session feedback

After marking a session complete the user can request AI feedback. The model receives the session topic and any notes and returns a short written reflection.

---

## Data Layer

### Firebase Firestore collections

| Collection | Key fields |
|---|---|
| `users` | profile, displayName, email, domain, institute |
| `userSettings` | all settings fields per userId |
| `subjects` | name, colorHex, topicCount, resourceCount, deadlineIds |
| `resources` | subjectId, resourceType, content, tags |
| `deadlines` | subjectId, dueDate, tag, priority, hasReminder |
| `studyPathTopics` | subjectId, order, weightPercent, estimatedMinutes, difficultyLevel |
| `studySessions` | subjectId, startTime, endTime, status, rating, topicIds |
| `availabilitySlots` | userId, type, startTime, endTime, date, rangeStart, rangeEnd |
| `quizAttempts` | subjectId, questions, selectedAnswers, scorePercent, timeSpentSeconds |
| `appNotifications` | userId, notificationType, title, message, createdAt |

### Sync status

Every model that syncs through Firebase conforms to `Syncable` and carries a `syncStatus` field:

| Status | Meaning |
|---|---|
| `localOnly` | Created locally, not yet written to Firebase |
| `pendingUpload` | In the process of uploading |
| `synced` | Matches Firebase |
| `pendingUpdate` | A local edit is waiting to sync |
| `pendingDelete` | Marked for deletion, not yet removed remotely |
| `conflicted` | Local and remote versions differ (rare edge case) |

### Core Data caching

Every service method that reads from Firebase also writes the result to Core Data immediately after. On the next app launch ViewModels load from Core Data first (instant), then refresh from Firebase in the background (up to date). This means screens never appear blank on launch.

---

## Notifications

All notifications are **local** (scheduled by the app, no push server required). `NotificationService` schedules and cancels `UNUserNotificationCenter` requests.

| Notification type | When it fires | Triggered by |
|---|---|---|
| Session reminder | X minutes before session start time | Adding or updating a session |
| Daily goal alert | Fixed time each day | Saving settings |
| Deadline alert | X days before due date | Creating a deadline |
| Quiz pending | X minutes after session ends | Completing a session |
| Streak alert | When a streak milestone is reached | Progress load |
| Weekly summary | End of each study week | Weekly summary job |

Notification permission is requested once on first launch. If denied, Settings shows a prompt linking to iOS Settings so the user can grant permission manually.
