import ActivityKit
import SwiftUI
import Combine

// Tracks the active dashboard study timer and mirrors it to a Live Activity when supported.
@MainActor
final class StudyTimerService: ObservableObject {
    static let shared = StudyTimerService()

    @Published var activeSession: StudySession? = nil
    @Published var elapsedSeconds: Int = 0
    @Published var isRunning: Bool = false

    private(set) var accumulatedSeconds: Int = 0

    private var startDate: Date?
    private var timer: Timer?
    private var _activity: Any?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appForegrounded),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // Recalculates elapsed time from the stored start date because timers pause while the app is backgrounded.
    @objc private func appForegrounded() {
        guard isRunning, let start = startDate else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(start))
    }

    var totalElapsedSeconds: Int { accumulatedSeconds + elapsedSeconds }

    var formattedTotal: String { format(totalElapsedSeconds) }
    var formattedElapsed: String { format(elapsedSeconds) }

    // Starts a fresh timer for a study session.
    func start(session: StudySession) {
        accumulatedSeconds = 0
        Task {
                if #available(iOS 16.1, *) {
                    for activity in Activity<StudyTimerAttributes>.activities {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                }
                _startTimer(session: session)
            }
    }
    
    // Resumes a paused session by keeping the already accumulated seconds.
    func resume(session: StudySession, previousSeconds: Int) {
        accumulatedSeconds = previousSeconds
        _startTimer(session: session)
    }

    @discardableResult
    // Stops the active timer but returns the total so the dashboard can save partial progress.
    func pause() -> Int {
        let total = totalElapsedSeconds
        accumulatedSeconds = total
        stopInAppTimer()
        if #available(iOS 16.1, *) { endLiveActivity() }
        startDate = nil
        isRunning = false
        elapsedSeconds = 0
        return total
    }

    @discardableResult
    // Finishes the timer, clears all local timer state, and returns the final duration.
    func complete() -> Int {
        let total = totalElapsedSeconds
        _fullReset()
        return total
    }

    // Shared start path used by both new and resumed sessions.
    private func _startTimer(session: StudySession) {
        stopInAppTimer()
        startDate = Date()
        activeSession = session
        isRunning = true
        elapsedSeconds = 0
        startInAppTimer()
        if #available(iOS 16.1, *) { startLiveActivity(session: session) }
    }

    private func _fullReset() {
        stopInAppTimer()
        if #available(iOS 16.1, *) { endLiveActivity() }
        startDate = nil
        activeSession = nil
        isRunning = false
        elapsedSeconds = 0
        accumulatedSeconds = 0
    }

    func format(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%02d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    private func startInAppTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            Task { @MainActor in self.elapsedSeconds = Int(Date().timeIntervalSince(start)) }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopInAppTimer() {
        timer?.invalidate()
        timer = nil
    }

    @available(iOS 16.1, *)
    private var activity: Activity<StudyTimerAttributes>? {
        get { _activity as? Activity<StudyTimerAttributes> }
        set { _activity = newValue }
    }

    @available(iOS 16.1, *)
    // Live Activity shows the same running timer on the lock screen/Dynamic Island.
    private func startLiveActivity(session: StudySession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = StudyTimerAttributes(
            sessionId: session.id,
            sessionTitle: session.title,
            subjectName: session.subjectName,
            subjectColorHex: session.subjectColorHex
        )
        let state = StudyTimerAttributes.ContentState(startDate: startDate ?? Date())
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Live Activity start failed: \(error)")
        }
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() {
        guard let act = activity else { return }
        Task {
            let finalState = StudyTimerAttributes.ContentState(startDate: self.startDate ?? Date())
            await act.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
