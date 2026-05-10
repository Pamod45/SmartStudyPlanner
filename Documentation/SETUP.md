# SmartStudyPlanner — Setup Guide

A complete guide for getting the project running from scratch. Follow every section in order.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone and Open the Project](#2-clone-and-open-the-project)
3. [Firebase Setup](#3-firebase-setup)
4. [Google Sign-In Setup](#4-google-sign-in-setup)
5. [LLM Setup — Hosted Server (Required)](#5-llm-setup--hosted-server-required)
6. [LLM Setup — Apple Foundation Models (Optional, iOS 26+)](#6-llm-setup--apple-foundation-models-optional-ios-26)
7. [Running the App](#7-running-the-app)
8. [Test Environment Setup](#8-test-environment-setup)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

### Required tools

| Tool | Minimum version | Notes |
|---|---|---|
| Xcode | 26.0 beta or later | Required for iOS 26 SDK and `FoundationModels` framework |
| iOS Simulator / Device | iOS 17+ | App runs on iOS 17+; AI features require iOS 26 |
| macOS | Sequoia or later | Xcode 26 requires this |
| A Firebase project | — | Free Spark plan is sufficient |
| A local or hosted LLM server | — | See section 5 |

### Optional (for Apple Intelligence AI path)

| Requirement | Details |
|---|---|
| iOS 26 device or simulator | iPhone 16 Pro / iPhone 16 / M-series iPad |
| Apple Intelligence enabled | Settings → Apple Intelligence & Siri |
| Xcode 26 SDK | Ships with Xcode 26 |

> If you do not have an iOS 26 device or Apple Intelligence, the app automatically falls back to the hosted LLM server. All features still work.

---

## 2. Clone and Open the Project

```bash
git clone https://github.com/Pamod45/SmartStudyPlanner
cd SmartStudyPlanner
open SmartStudyPlanner.xcodeproj
```

Xcode will resolve Swift Package dependencies automatically on first open. This may take a few minutes wait for the package resolution spinner in the top bar to finish before building.

**Packages resolved automatically (no manual steps needed):**

| Package | Version | Purpose |
|---|---|---|
| `firebase-ios-sdk` | 12.12.0 | Auth, Firestore |
| `googlesignin-ios` | 9.1.0 | Google Sign-In |

---

## 3. Firebase Setup

The app uses **Firebase Authentication** and **Firebase Firestore**. Both must be enabled before the app can sign in or store any data.

### 3.1 Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com).
2. Click **Add project**, give it a name (e.g. `SmartStudyPlanner`), and follow the steps.

### 3.2 Register the iOS app

1. In the Firebase console, click the iOS icon to add an iOS app.
2. Set the **Bundle ID** to match what is in Xcode:
   - Open `SmartStudyPlanner.xcodeproj` → select the `SmartStudyPlanner` target → **General** tab → copy the Bundle Identifier field.
3. Click **Register app**.
4. Download `GoogleService-Info.plist` when prompted.

### 3.3 Add GoogleService-Info.plist to the project

1. Delete or replace the existing `GoogleService-Info.plist` at the project root if one is present.
2. Drag the downloaded file into Xcode — drop it **inside the `SmartStudyPlanner/` group** (not the root).
3. In the dialog that appears, check **"Add to targets: SmartStudyPlanner"** and click **Finish**.
4. Do not commit this file to public source control — it contains your project's API keys.

### 3.4 Enable Email/Password Authentication

1. In the Firebase console, go to **Authentication → Sign-in method**.
2. Enable **Email/Password**.
3. Click **Save**.

### 3.5 Enable Google Sign-In Authentication

1. Still in **Authentication → Sign-in method**, enable **Google**.
2. Set a project support email.
3. Click **Save**.

### 3.6 Enable Cloud Firestore

1. Go to **Firestore Database** in the Firebase console.
2. Click **Create database**.
3. Choose **Start in test mode** for development (allows all reads/writes for 30 days).
4. Select a region close to your users and click **Enable**.

> **Production note:** Before launching, replace test mode rules with proper security rules that check `request.auth.uid`.

### 3.7 Firestore security rules (recommended for development)

Paste these rules in **Firestore → Rules** while developing:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3.8 Required Firestore collections

The app creates documents automatically. No manual collection setup is needed. The collections that will be created are:

`users` · `userSettings` · `subjects` · `resources` · `deadlines` · `studyPathTopics` · `studySessions` · `availabilitySlots` · `quizAttempts` · `appNotifications`

---

## 4. Google Sign-In Setup

Google Sign-In requires a URL scheme added to the Xcode project.

### 4.1 Add the reversed client ID URL scheme

1. Open `GoogleService-Info.plist` and copy the value of `REVERSED_CLIENT_ID`.
   It looks like: `com.googleusercontent.apps.xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
2. In Xcode, select the `SmartStudyPlanner` target → **Info** tab → **URL Types** section.
3. Click **+** to add a new URL type.
4. Paste the `REVERSED_CLIENT_ID` value into the **URL Schemes** field.
5. Leave the other fields blank.

### 4.2 Verify Google Sign-In in Info.plist

The `CFBundleURLTypes` entry should now look like this (values will differ for your project):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

---

## 5. LLM Setup — Hosted Server (Required)

The app currently routes all AI generation (study paths, quizzes, AI assistant) through a **hosted OpenAI-compatible server**. This is the active path regardless of device type.

The AI features are:
- **Study Path generation** — builds an ordered topic list from your uploaded resources
- **Quiz generation** — creates multiple-choice questions from study material
- **AI Assistant** — chat interface scoped to your subject resources

### 5.1 What kind of server is needed

Any server that exposes an **OpenAI-compatible chat completions endpoint**:

```
POST /v1/chat/completions
Content-Type: application/json

{
  "messages": [...],
  "temperature": 0.1,
  "max_tokens": 1400
}
```

Returns a response in the standard OpenAI format:

```json
{
  "choices": [
    { "message": { "role": "assistant", "content": "..." } }
  ]
}
```

### 5.2 Recommended local server options

| Option | Best for | Setup effort |
|---|---|---|
| **Ollama** | Quick local setup, macOS native | Low |
| **LM Studio** | GUI-based, no terminal needed | Low |
| **llama.cpp server** | Maximum control and performance | Medium |

#### Option A — Ollama (recommended)

```bash
# Install Ollama
brew install ollama

# Pull a capable instruction-following model
ollama pull llama3.1:8b

# Start the server (default port 11434)
ollama serve
```

Ollama's OpenAI-compatible endpoint is at:
```
http://localhost:11434/v1/chat/completions
```

#### Option B — LM Studio

1. Download LM Studio from [lmstudio.ai](https://lmstudio.ai).
2. Search for and download a model (Llama 3.1 8B, Qwen 2.5 7B, or Gemma 2 9B all work well).
3. Go to **Local Server** tab and click **Start Server**.
4. The default endpoint is `http://localhost:1234/v1/chat/completions`.

#### Option C — Any cloud-hosted OpenAI-compatible API

If you have an API key for OpenAI, Together AI, Groq, or similar, use their chat completions URL and add `Authorization: Bearer YOUR_API_KEY` to the request headers. You will need to add the header in `HostedLLMBackend.swift` (see 5.3).

### 5.3 Update the server URL in the source code

The URL is hardcoded in **two files**. Update both to match your server's address.

**File 1:** [SmartStudyPlanner/Features/Subjects/Services/StudyContentOrchestrator.swift](SmartStudyPlanner/Features/Subjects/Services/StudyContentOrchestrator.swift) — line 12

```swift
// Change this:
private let hostedServerURL = URL(string: "http://192.168.1.21:8080/v1/chat/completions")!

// To your server, for example:
private let hostedServerURL = URL(string: "http://localhost:11434/v1/chat/completions")!
```

**File 2:** [SmartStudyPlanner/Shared/Services/AIServices/AIAssistantService.swift](SmartStudyPlanner/Shared/Services/AIServices/AIAssistantService.swift) — line 65

```swift
// Change this:
private let serverURL = URL(string: "http://192.168.1.21:8080/v1/chat/completions")!

// To your server, for example:
private let serverURL = URL(string: "http://localhost:11434/v1/chat/completions")!
```

> **Running on a physical device?** `localhost` will not work because the device is not your Mac. Use your Mac's local IP address instead (find it in **System Preferences → Network**, e.g. `192.168.1.x`). Make sure your Mac's firewall allows connections on the LLM server port.

### 5.4 Recommended models

The prompts ask the model to return strict JSON arrays. Models that follow instructions reliably work best:

| Model | Size | Good for |
|---|---|---|
| `llama3.1:8b` | ~5 GB | Balanced speed and quality |
| `qwen2.5:7b` | ~5 GB | Strong JSON output |
| `gemma2:9b` | ~6 GB | High accuracy |
| `llama3.1:70b` | ~40 GB | Best quality, needs high-end hardware |

### 5.5 Allow App Transport Security for local HTTP

By default iOS blocks plain HTTP requests. Because the local server runs on HTTP, the app's `Info.plist` must allow it.

Verify that `Info.plist` inside the `SmartStudyPlanner` target contains:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

If it is missing, add it. If you are using a remote server with HTTPS, this entry is not needed.

---

## 6. LLM Setup — Apple Foundation Models (Optional, iOS 26+)

The app includes a complete on-device AI backend using **Apple Foundation Models** (`FoundationModels` framework). This path is currently disabled in code but fully implemented and ready to activate.

### 6.1 Device requirements

| Requirement | Detail |
|---|---|
| iOS version | 26.0 or later |
| Device | iPhone 16 / 16 Plus / 16 Pro / 16 Pro Max, or any M-series iPad |
| Apple Intelligence | Must be enabled in Settings → Apple Intelligence & Siri |
| Language | Apple Intelligence is available in English (US) and select other languages |

### 6.2 How to disable the on-device path

Please comment the the Foundation Models backend in two files to use the hosted LLM

**File 1:** [SmartStudyPlanner/Shared/Services/AIServices/StudyLLMBackend.swift](SmartStudyPlanner/Shared/Services/AIServices/StudyLLMBackend.swift) — inside `LLMBackendSelector.resolve`

```swift
// Uncomment these lines:
if case .available = SystemLanguageModel.default.availability {
    print("[LLM] Using FoundationModels (Apple Intelligence)")
    return FoundationModelsBackend()
}
```

**File 2:** [SmartStudyPlanner/Shared/Services/AIServices/AIAssistantService.swift](SmartStudyPlanner/Shared/Services/AIServices/AIAssistantService.swift) — inside `send(userMessage:contextText:subjectName:contextId:history:)`

```swift
// Uncomment these lines:
if case .available = SystemLanguageModel.default.availability {
    return try await sendViaFoundationModel(
        userMessage: userMessage,
        contextText: contextText,
        subjectName: subjectName,
        contextId: contextId
    )
}
```

---

## 7. Running the App

### 7.1 Select a scheme and destination

1. In Xcode choose the `SmartStudyPlanner` scheme.
2. Select a simulator (iPhone 16 or later for best experience) or a connected device.
3. Press `Cmd + R` to build and run.

### 7.2 First launch checklist

On first launch the app will:
- Request notification permission — tap **Allow** to enable session and deadline reminders.
- Check Firebase configuration — if `GoogleService-Info.plist` is missing or incorrect the app will crash with a Firebase configuration error in the console.
- Check LLM server availability — the AI features will silently fail if the server URL is unreachable. Check the Xcode console for `[LLM]` log lines.

### 7.3 Verify LLM connection

After signing in, create a subject, add any text note as a resource, then tap **Generate Study Path**. If the AI request succeeds you will see topics appear. If it fails:
- Check the Xcode console for `[HostedLLM]` log lines.
- Confirm the server is running and the URL in both source files is correct.
- Confirm `NSAllowsLocalNetworking` is set for local HTTP servers.

---

## 8. Test Environment Setup

The test suite is in `SmartStudyPlannerTests/`. Most tests are pure unit tests that run with no setup. Two test classes hit real Firebase and need credentials.

### 8.1 Pure unit tests (no setup needed)

These run immediately with no credentials, no server, and no device permissions:

| Test class | What it covers |
|---|---|
| `UserTests` | AppUser Firestore mapping |
| `StudyScheduleServiceTests` | Scheduler algorithm |
| `StudyPathTests` | StudyPathTopic model |
| `QuizTests` | Quiz scoring |
| `NotificationTests` | Notification icons and date formatting |
| `StudyPlanTests` | AvailabilitySlot, StudySession, StudyPlan models + advanced scheduler |
| `ProgressTests` | WeeklyProgressSnapshot, subjectDistribution, streak calculation |
| `SettingsTests` | UserSettings serialization, LocalSettingsManager, SettingsViewModel |

Run all of them at once: `Cmd + U`

### 8.2 Firebase-backed tests (credentials required)

These two test classes create real data in your Firebase project and clean it up after each run:

| Test class | What it covers |
|---|---|
| `AuthenticationTests` | Sign-in, sign-out, profile caching, Face ID |
| `SubjectWorkspaceTests` | Resources, deadlines, study paths, quiz attempts end-to-end |

**Step 1 — Create a test Firebase account**

Create a dedicated test user in the Firebase console under **Authentication → Users → Add user**. Use a throwaway email — never a personal account.

**Step 2 — Add environment variables to the test scheme**

1. In Xcode go to **Product → Scheme → Edit Scheme** (`Cmd + <`).
2. Select the **Test** action.
3. Open the **Arguments** tab.
4. Under **Environment Variables** add:

| Variable | Value |
|---|---|
| `AUTH_TEST_EMAIL` | Email of your test Firebase account |
| `AUTH_TEST_PASSWORD` | Password of your test Firebase account |

5. Click **Close**.

> These variables are stored locally in the `.xcscheme` file. Do not commit them. They are excluded from the shared scheme by default.

**Step 3 — Run the Firebase-backed tests**

```
Cmd + U
```

Or run just the Firebase tests from the terminal:

```bash
xcodebuild test \
  -project SmartStudyPlanner.xcodeproj \
  -scheme SmartStudyPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SmartStudyPlannerTests/AuthenticationTests \
  -only-testing SmartStudyPlannerTests/SubjectWorkspaceTests
```

If the environment variables are not set the Firebase tests call `throw XCTSkip(...)` and are marked as skipped, not failed.

---

## 9. Troubleshooting

### Firebase: "No Google app configured" crash on launch

`GoogleService-Info.plist` is missing from the app target or contains the wrong Bundle ID.

- Verify the file is inside the `SmartStudyPlanner/` group in Xcode (not just in the filesystem).
- In Xcode Navigator, select the file and open the **File Inspector** — confirm `SmartStudyPlanner` is checked under Target Membership.
- Confirm the `BUNDLE_ID` in the plist matches your Xcode target's Bundle Identifier exactly.

### Google Sign-In: "Invalid URL scheme" error

The `REVERSED_CLIENT_ID` URL scheme is missing or wrong.

- Open `GoogleService-Info.plist`, copy `REVERSED_CLIENT_ID`.
- In Xcode target → **Info → URL Types**, ensure that exact string is listed as a URL Scheme.

### LLM: "Server returned HTTP 404" or connection refused

- Confirm the LLM server is running: open a terminal and run `curl http://localhost:11434/v1/chat/completions` (adjust port/host).
- Confirm both URL strings in `StudyContentOrchestrator.swift` and `AIAssistantService.swift` point to the correct address.
- If testing on a physical device, replace `localhost` with your Mac's LAN IP address.
- Confirm `NSAllowsLocalNetworking` is in `Info.plist` for local HTTP connections.

### LLM: Study path or quiz generates garbage / no results

The model returned malformed JSON. The hosted backend has a salvage parser but very small models may still fail.

- Switch to a larger model (8B parameters minimum recommended).
- In Ollama: `ollama pull llama3.1:8b` then restart the server.
- Check the Xcode console for `[HostedLLM]` log lines showing the raw server response.

### Apple Foundation Models: "unavailable" in console

```
Availability: unavailable(reason: ...)
```

This is printed on every launch. It means the device/simulator does not support Apple Intelligence. The app falls back to the hosted server automatically — this is not an error.

To use Foundation Models:
- Use an iPhone 16 / 16 Pro (physical device), or the iOS 26 simulator with Apple Intelligence enabled in Simulator settings.
- Make sure **Apple Intelligence** is turned on in **Settings → Apple Intelligence & Siri** on the device.

### Tests: Firebase-backed tests skipped

```
Test skipped: Set AUTH_TEST_EMAIL and AUTH_TEST_PASSWORD to run authentication tests.
```

This is expected when the environment variables are not set. Follow section 8.2 to configure them.

### Swift Package resolution fails

If Xcode shows package resolution errors:

```bash
# Reset package caches
File → Packages → Reset Package Caches

# Or from terminal:
xcodebuild -resolvePackageDependencies \
  -project SmartStudyPlanner.xcodeproj \
  -scheme SmartStudyPlanner
```

### Build error: `@Generable` macro not found

`@Generable` is part of the `FoundationModels` framework which ships with the iOS 26 SDK. If you see this error:
- Confirm Xcode 26 (or the beta that includes iOS 26 SDK) is selected as the active Xcode in **Xcode → Settings → Locations → Command Line Tools**.
- Run `sudo xcode-select -s /Applications/Xcode-26.app` if needed (adjust path for your Xcode beta name).
