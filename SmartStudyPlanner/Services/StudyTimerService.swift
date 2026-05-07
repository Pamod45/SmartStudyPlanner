import ActivityKit
import SwiftUI
import Combine
@MainActor
final class StudyTimerService: ObservableObject {
    static let shared = StudyTimerService()

    @Published var activeSession: StudySession? = nil
    @Published var elapsedSeconds: Int = 0
    @Published var isRunning: Bool = false

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

    @objc private func appForegrounded() {
        guard isRunning, let start = startDate else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(start))
    }

    func start(session: StudySession) {
        stopInAppTimer()
        startDate = Date()
        activeSession = session
        isRunning = true
        startInAppTimer()
        if #available(iOS 16.1, *) {
            startLiveActivity(session: session)
        }
    }
    
    func stop() -> Int {
        let elapsed = elapsedSeconds
        stopInAppTimer()
        if #available(iOS 16.1, *) { endLiveActivity() }
        startDate = nil
        activeSession = nil
        isRunning = false
        elapsedSeconds = 0
        return elapsed
    }

    var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
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
