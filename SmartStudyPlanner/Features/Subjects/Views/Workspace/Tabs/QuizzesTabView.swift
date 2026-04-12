//
//  QuizzesTabView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//

import SwiftUI

struct QuizzesTabView: View {
    @Environment(\.theme) var theme

    let subject: Subject
    let studyPath: StudyPath?
    let resources: [Resource]
    @Binding var attempts: [QuizAttempt]

    @State private var showConfig: Bool = false
    @State private var activeAttempt: QuizAttempt? = nil
    @State private var showAllAttempts: Bool = false

    private var averageScore: Int {
        guard !attempts.isEmpty else { return 0 }
        return attempts.reduce(0) { $0 + $1.scorePercent } / attempts.count
    }

    private var displayedAttempts: [QuizAttempt] {
        showAllAttempts ? attempts : Array(attempts.prefix(3))
    }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            startButton

            if !attempts.isEmpty {
                statsRow
                previousAttemptsSection
            } else {
                emptyState
            }
        }
        .padding(.bottom, theme.spacing.xl)
        .sheet(isPresented: $showConfig) {
            QuizConfigSheet(
                subject: subject,
                studyPath: studyPath,
                resources: resources
            ) { newAttempt in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    activeAttempt = newAttempt
                }
            }
            .environment(\.theme, theme)
        }
        .fullScreenCover(item: $activeAttempt) { attempt in
            QuizSessionView(attempt: attempt) { completed in
                attempts.insert(completed, at: 0)
            }
            .environment(\.theme, theme)
        }
    }

    private var startButton: some View {
        PrimaryButton(title: "Start New Quiz", icon: "play.fill") {
            showConfig = true
        }
    }

    private var statsRow: some View {
        HStack(spacing: theme.spacing.sm) {
            statCard(label: "AVERAGE SCORE", value: "\(averageScore)", unit: "%")
            statCard(label: "TOTAL ATTEMPTS", value: "\(attempts.count)", unit: nil, icon: "arrow.clockwise")
        }
    }

    private func statCard(label: String, value: String, unit: String?, icon: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .tracking(1.5)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                if let u = unit {
                    Text(u)
                        .font(theme.typography.bodyMedium.weight(.semibold))
                        .foregroundColor(theme.colors.textSecondary)
                }
                if let ic = icon {
                    Image(systemName: ic)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.35), lineWidth: 1))
    }

    private var previousAttemptsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Previous Attempts")
                .font(theme.typography.headingSmall)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: theme.spacing.sm) {
                ForEach(displayedAttempts) { attempt in
                    attemptRow(attempt)
                }
            }

            if attempts.count > 3 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAllAttempts.toggle()
                    }
                } label: {
                    HStack(spacing: theme.spacing.xs) {
                        Text(showAllAttempts ? "Show Less" : "View All")
                            .font(theme.typography.bodyMedium.weight(.semibold))
                            .foregroundColor(theme.colors.primary)
                        Image(systemName: showAllAttempts ? "chevron.up.2" : "chevron.down.2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.colors.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func attemptRow(_ attempt: QuizAttempt) -> some View {
        let scoreColor: Color = attempt.scorePercent >= 85 ? .green : attempt.scorePercent >= 60 ? .orange : .red

        return HStack(spacing: theme.spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: theme.radius.lg)
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text("\(attempt.scorePercent)%")
                    .font(theme.typography.bodySmall.weight(.bold))
                    .foregroundColor(scoreColor)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(attempt.quizName)
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
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

            Image(systemName: "chevron.right")
                .font(theme.typography.bodySmall.weight(.semibold))
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.35), lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: theme.spacing.md) {
            Spacer(minLength: 20)
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary)
            Text("No quizzes yet")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
            Text("Start your first quiz to track your progress.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}
