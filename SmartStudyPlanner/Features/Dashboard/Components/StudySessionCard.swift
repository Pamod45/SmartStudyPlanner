import SwiftUI

// Dashboard card for starting, pausing, resuming, and completing a scheduled study session.

struct StudySessionCard: View {
    @Environment(\.theme) var theme
    @ObservedObject private var timerService = StudyTimerService.shared

    let session: StudySession
    var onStart: () -> Void = {}
    var onResume: () -> Void = {}
    var onPause: () -> Void = {}
    var onComplete: () -> Void = {}

    private var isRunning: Bool {
        timerService.activeSession?.id == session.id && timerService.isRunning
    }

    private var isPaused: Bool {
        timerService.activeSession?.id == session.id && !timerService.isRunning
    }

    private var isInterrupted: Bool {
        session.status == .inProgress && timerService.activeSession?.id != session.id
    }

    private var timeLabel: String {
        if isRunning  { return timerService.formattedTotal }
        if isPaused   { return timerService.formattedTotal }
        if isInterrupted, let mins = session.actualDurationMinutes {
            return timerService.format(mins * 60)
        }
        return session.duration
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(session.subjectName)
                .font(theme.typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(session.subjectColor)
                .lineLimit(1)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs)
                .background(session.subjectColor.opacity(0.2))
                .clipShape(Rectangle())
                .cornerRadius(theme.spacing.xs)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(session.title)
                    .font(theme.typography.headingMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)
                    .frame(height: 58, alignment: .topLeading)

                Text(session.timeRange + " •" + session.sessionDate)
                    .font(theme.typography.caption)
                    .foregroundColor(session.subjectColor)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: isRunning ? "timer" : "clock")
                        .font(theme.typography.caption)
                    Text(timeLabel)
                        .font(theme.typography.bodyMedium)
                        .contentTransition(.numericText())
                }
                .foregroundColor(isRunning ? theme.colors.primary : theme.colors.textSecondary)
                .animation(.linear(duration: 0.3), value: timerService.totalElapsedSeconds)
            }
            .padding(.bottom, theme.spacing.sm)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Study Session: \(session.title)")
            .accessibilityValue("Time: \(timeLabel), from \(session.timeRange). Status: \(isRunning ? "Running" : isPaused ? "Paused" : "Not Started")")

            Spacer(minLength: 0)

            if isRunning {
                runningButtons
            } else if isPaused || isInterrupted {
                pausedButtons
            } else {
                PrimaryButton(title: "Start", icon: "play.fill", action: onStart)
            }
        }
        .padding(theme.spacing.md)
        .frame(width: 270, height: 290, alignment: .topLeading)
        .background(theme.colors.surface)
        .cornerRadius(theme.radius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(
                    isRunning ? theme.colors.primary.opacity(0.5) :
                    (isPaused || isInterrupted) ? Color.orange.opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isRunning)
        .animation(.easeInOut(duration: 0.2), value: isPaused)
    }

    private var runningButtons: some View {
        HStack(spacing: theme.spacing.sm) {
            Button(action: onPause) {
                HStack(spacing: 4) {
                    Image(systemName: "pause.fill")
                    Text("Pause")
                }
                .font(theme.typography.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(Color.orange.opacity(0.85))
                .clipShape(Capsule())
            }

            Button(action: onComplete) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                    Text("Done")
                }
                .font(theme.typography.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(Color.green.opacity(0.85))
                .clipShape(Capsule())
            }
        }
    }

    private var pausedButtons: some View {
        HStack(spacing: theme.spacing.sm) {
            Button(action: onResume) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    Text("Resume")
                }
                .font(theme.typography.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.primary.opacity(0.85))
                .clipShape(Capsule())
            }

            Button(action: onComplete) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                    Text("Done")
                }
                .font(theme.typography.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(Color.green.opacity(0.85))
                .clipShape(Capsule())
            }
        }
    }
}
