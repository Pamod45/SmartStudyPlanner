import SwiftUI

struct StudySessionCard: View {
    @Environment(\.theme) var theme
    @ObservedObject private var timerService = StudyTimerService.shared

    let session: StudySession
    var onStart: () -> Void = {}
    var onStop: (Int) -> Void = { _ in }

    private var isActive: Bool {
        timerService.activeSession?.id == session.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(session.subjectName)
                .font(theme.typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(session.subjectColor)
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

                Text(session.timeRange)
                    .font(theme.typography.caption)
                    .foregroundColor(session.subjectColor)

                HStack(spacing: 4) {
                    Image(systemName: isActive ? "timer" : "clock")
                        .font(theme.typography.caption)
                    Text(isActive ? timerService.formattedElapsed : session.duration)
                        .font(theme.typography.bodyMedium)
                        .contentTransition(.numericText())
                }
                .foregroundColor(isActive ? theme.colors.primary : theme.colors.textSecondary)
                .animation(.linear(duration: 0.3), value: timerService.elapsedSeconds)
            }
            .padding(.bottom, theme.spacing.sm)

            if isActive {
                stopButton
            } else {
                PrimaryButton(title: "Start", icon: "play.fill", action: onStart)
            }
        }
        .padding(theme.spacing.md)
        .frame(width: 270)
        .background(theme.colors.surface)
        .cornerRadius(theme.radius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(isActive ? theme.colors.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private var stopButton: some View {
        Button(action: {
            let elapsed = timerService.stop()
            onStop(elapsed)
        }) {
            HStack {
                Image(systemName: "stop.fill")
                Text("Stop")
            }
            .font(theme.typography.headingSmall)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(Color.red.opacity(0.85))
            .clipShape(Capsule())
        }
    }
}
