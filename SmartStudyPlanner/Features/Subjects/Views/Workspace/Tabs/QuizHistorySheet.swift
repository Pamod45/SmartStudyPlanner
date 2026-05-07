//
//  QuizHistorySheet.swift
//  SmartStudyPlanner
//

import SwiftUI

// MARK: - QuizGroup (grouping model)

struct QuizGroup: Identifiable {
    let id: String                    // = quizName (unique per quiz)
    let quizName: String
    let topicName: String
    var attempts: [QuizAttempt]       // sorted newest-first

    var latestAttempt: QuizAttempt? { attempts.first }
    var latestScore: Int              { latestAttempt?.scorePercent ?? 0 }
    var bestScore: Int                { attempts.map(\.scorePercent).max() ?? 0 }
    var averageScore: Int {
        guard !attempts.isEmpty else { return 0 }
        return attempts.reduce(0) { $0 + $1.scorePercent } / attempts.count
    }
    var attemptCount: Int             { attempts.count }
    var scoreColor: Color {
        let s = latestScore
        if s >= 85 { return .green }
        if s >= 60 { return .orange }
        return Color(red: 1, green: 0.45, blue: 0.45)
    }
}

// MARK: - QuizHistorySheet

struct QuizHistorySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let group: QuizGroup
    var onReattempt: (QuizAttempt) -> Void   // passes the template attempt back to parent

    @State private var selectedAttempt: QuizAttempt? = nil

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────────────────
                header
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.md) {
                        statsRow
                        attemptsList
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, 100)
                }

                // ── Bottom bar ───────────────────────────────────────────
                bottomBar
            }
        }
        // View full results for a single attempt
        .sheet(item: $selectedAttempt) { attempt in
            QuizResultsView(
                attempt: attempt,
                onDone: { selectedAttempt = nil },
                onReattempt: {
                    selectedAttempt = nil
                    dismiss()
                    // Small delay to let both sheets close before parent fires fullScreenCover
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onReattempt(attempt)
                    }
                }
            )
            .environment(\.theme, theme)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(group.quizName)
                    .font(theme.typography.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)
                Text(group.topicName)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(theme.colors.border.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: theme.spacing.sm) {
            statCard(label: "BEST SCORE",    value: "\(group.bestScore)%",    accent: .green)
            statCard(label: "AVERAGE",       value: "\(group.averageScore)%", accent: theme.colors.primary)
            statCard(label: "ATTEMPTS",      value: "\(group.attemptCount)",  accent: theme.colors.textSecondary)
        }
    }

    private func statCard(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .tracking(1.4)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Attempts list

    private var attemptsList: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("All Attempts")
                .font(theme.typography.headingSmall)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: theme.spacing.sm) {
                ForEach(Array(group.attempts.enumerated()), id: \.element.id) { index, attempt in
                    attemptRow(attempt, attemptNumber: group.attempts.count - index)
                }
            }
        }
    }

    private func attemptRow(_ attempt: QuizAttempt, attemptNumber: Int) -> some View {
        let scoreColor: Color = attempt.scorePercent >= 85 ? .green
                              : attempt.scorePercent >= 60 ? .orange
                              : Color(red: 1, green: 0.45, blue: 0.45)
        let isLatest = attempt.id == group.latestAttempt?.id

        return Button {
            selectedAttempt = attempt
        } label: {
            HStack(spacing: theme.spacing.md) {
                // Score badge
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radius.lg)
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Text("\(attempt.scorePercent)%")
                        .font(theme.typography.bodySmall.weight(.bold))
                        .foregroundColor(scoreColor)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(spacing: theme.spacing.xs) {
                        Text("Attempt \(attemptNumber)")
                            .font(theme.typography.bodyLarge.weight(.semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        if isLatest {
                            Text("LATEST")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(theme.colors.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.colors.primary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: theme.spacing.md) {
                        Label(attempt.dateFormatted, systemImage: "calendar")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                        Label(attempt.durationFormatted, systemImage: "clock")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                // Correct / total
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(attempt.correctCount)/\(attempt.questions.count)")
                        .font(theme.typography.bodySmall.weight(.bold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text("correct")
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(theme.spacing.md)
            .background(isLatest ? theme.colors.primary.opacity(0.05) : theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.xl)
                    .stroke(isLatest ? theme.colors.primary.opacity(0.25) : theme.colors.border.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isLatest)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            PrimaryButton(title: "Try Again", icon: "arrow.clockwise") {
                guard let template = group.latestAttempt else { return }
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onReattempt(template)
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.background)
        }
    }
}
