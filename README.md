# SmartStudyPlanner

**Index:** COBSCCOMP242P-003  
**Name:** T.H.P.P. Perera

An iOS study planning application built with SwiftUI. The app helps students organise study material, schedule sessions against their availability, track progress over time, and generate AI-powered study paths and quizzes from uploaded resources.

---

## Overview

SmartStudyPlanner is structured around five main tabs — Dashboard, Subjects, Study Plan, Progress, and Settings. Each feature module is backed by Firebase Firestore for remote persistence and Core Data for local caching, so the app remains functional on slow or intermittent connections.

AI generation (study paths, quizzes, and an in-session assistant) uses Apple Foundation Models on supported devices and falls back automatically to an OpenAI-compatible hosted server on older hardware.

---

## Features

### Dashboard
- Today's study sessions with live timer and status tracking
- Upcoming deadlines across all subjects
- In-app notification feed

### Subjects and Workspace
- Subject management with colour and icon customisation
- Resource library supporting PDF, notes, links, recordings
- Deadline tracking with tags, priority, and reminder scheduling
- AI-generated study paths that break a subject into weighted, ordered topics
- AI-generated multiple-choice quizzes from study material

### Study Plan
- Calendar view with availability slots (specific date or date range)
- Manual session creation with availability enforcement
- Automated session scheduler that fills available blocks and prioritises topics by deadline pressure, difficulty, and weight
- iOS Calendar sync via EventKit
- Cascading deletion - removing an availability slot removes all sessions and calendar events inside it

### Progress
- Weekly stats: hours studied, session count, day streak, and average rating
- Per-subject mastery score combining study hours (70%) and quiz performance (30%)
- Activity charts (daily, monthly, quarterly) and subject distribution pie chart
- Auto-generated insights: peak day, top subject, weekly trend, and weakest quiz area

### Settings
- Profile editing with avatar support
- Notification timing for sessions, deadlines, daily goals, and quizzes
- Study goal configuration used by the progress calculations
- Accessibility preferences: text size and high contrast
- Face ID unlock using saved credentials

---

## Advanced Features and iOS Frameworks

### FoundationModels (iOS 26+)
Apple's on-device language model framework. Used to generate study paths and quizzes through `LanguageModelSession` and structured output via the `@Generable` macro and `@Guide` property wrappers. The app checks `SystemLanguageModel.default.availability` at runtime and falls back to the hosted server when the model is unavailable.

### ActivityKit — Live Activities
The study session timer runs as a Live Activity on the Lock Screen and Dynamic Island. `StudyTimerAttributes` defines the layout and `StudyTimerService` pushes updates while a session is in progress, so the elapsed time is visible without opening the app.

### Swift Charts
The Progress tab renders the daily activity line/area chart and the subject distribution pie chart using the native `Charts` framework (`LineMark`, `AreaMark`, `SectorMark`). Data is passed directly from `ProgressViewModel` computed properties with no third-party charting library.

### Vision and VisionKit
`TextRecognitionService` uses `VNRecognizeTextRequest` to extract text from images. `ScannerView` wraps `VNDocumentCameraViewController` (VisionKit) to let the user scan physical documents with the camera. Extracted text is passed to the LLM for study path and quiz generation.

### PDFKit
`ContentExtractionService` opens PDF resources with `PDFDocument` and iterates pages to extract plain text used as LLM input. `PDFViewerSheet` renders PDFs inline with `PDFView` inside the resource viewer.

### Speech Framework and AVFoundation
`AudioTranscriptionService` uses `SFSpeechRecognizer` with an `AVAudioEngine` audio tap to transcribe live recordings in real time. The resulting transcript is saved as a resource and can be fed into study path generation. `TextToSpeechManager` uses `AVSpeechSynthesizer` to read AI assistant responses aloud.

### EventKit — Calendar Integration
`CalendarSyncService` exports study sessions to the user's iOS Calendar using `EKEventStore`. The service handles both full access and the write-only partial access introduced in iOS 17, requesting only the minimum permission needed for the operation.

### LocalAuthentication
`LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` is called when the user enables Face ID in Settings. A successful biometric evaluation triggers a full Firebase email/password sign-in using credentials stored in `UserDefaults`.

### UserNotifications
`NotificationService` schedules all reminders locally via `UNUserNotificationCenter` with no push server. Custom `userInfo` payloads carry the notification type and reference ID so `AppDelegate` can reconstruct an `AppNotification` model and insert it into the in-app notification feed when the notification is delivered or tapped.

### Core Data
`CoreDataService` mirrors every Firestore fetch into a local persistent store. ViewModels load from Core Data first on every screen open, giving instant content, then replace it silently when the remote fetch completes.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| State management | Combine, `@MainActor`, `@Published` |
| Remote storage | Firebase Firestore |
| Authentication | Firebase Auth, Google Sign-In |
| Local cache | Core Data |
| Device-local settings | UserDefaults |
| Calendar integration | EventKit |
| Local notifications | UserNotifications |
| On-device AI (iOS 26+) | Apple Foundation Models (`FoundationModels`) |
| Hosted AI fallback | OpenAI-compatible chat completions API |
| Package manager | Swift Package Manager |

---

## Project Structure

```
SmartStudyPlanner/
├── App/
│   ├── SmartStudyPlannerApp.swift     Entry point, Firebase init, notification delegate
│   └── ContentView.swift              Tab router
│
├── Features/
│   ├── Authentication/                Sign-in, sign-up, Face ID, session restore
│   ├── Dashboard/                     Today view, session cards, notification feed
│   ├── Subjects/                      Subject list, workspace, resources, deadlines,
│   │                                  study paths, quizzes, AI assistant
│   ├── StudyPlan/                     Calendar, availability slots, session scheduling
│   ├── Progress/                      Stats, charts, streak, subject mastery, insights
│   └── Settings/                      Profile, notifications, goals, accessibility
│
├── Shared/
│   ├── Models/                        Data models (Study, User, Quiz, Progress, Settings)
│   ├── Services/                      Firebase services, AI backends, content extraction,
│   │                                  notifications, calendar sync
│   ├── Components/                    Reusable SwiftUI components
│   └── Theme/                         ThemeManager, colour extensions
│
└── SmartStudyPlannerTests/            Unit and integration test suite
```

---

## Getting Started

Full setup instructions including Firebase configuration, Google Sign-In, and LLM server setup are in [SETUP.md](Documentation/SETUP.md).

### Quick summary

1. Clone the repository and open `SmartStudyPlanner.xcodeproj` in Xcode 26 or later.
2. Create a Firebase project, enable Email/Password and Google authentication, enable Firestore, and add `GoogleService-Info.plist` to the `SmartStudyPlanner` target.
3. Add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as a URL scheme under the target's Info tab.
4. Start an OpenAI-compatible LLM server (Ollama recommended) and update the two URL strings in `StudyContentOrchestrator.swift` and `AIAssistantService.swift`.
5. Build and run on a simulator or device running iOS 17 or later.

---

## Running Tests

The test suite is in `SmartStudyPlannerTests/`. Most tests are pure unit tests that require no credentials or running services.

```
Cmd + U
```

Two test classes (`AuthenticationTests`, `SubjectWorkspaceTests`) write to a real Firebase project and are skipped automatically unless `AUTH_TEST_EMAIL` and `AUTH_TEST_PASSWORD` are set as environment variables in the Xcode test scheme.

Full test coverage details and run commands are in [TESTING.md](Documentation/TESTING.md).

---

## Documentation

| File | Contents |
|---|---|
| [SETUP.md](Documentation/SETUP.md) | Step-by-step setup for Firebase, Google Sign-In, LLM server, and test credentials |
| [FEATURES.md](Documentation/FEATURES.md) | Feature descriptions, data flows, and formulas for every module |
| [TESTING.md](Documentation/TESTING.md) | Test coverage by module, what each test checks, and how to run subsets |

---

## Requirements

- Xcode 26 or later
- iOS 17 or later (deployment target)
- iOS 26 with Apple Intelligence enabled for on-device AI generation (optional — falls back to hosted server)
- A Firebase project with Authentication and Firestore enabled
- An OpenAI-compatible LLM server for AI features
