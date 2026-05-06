//
//  QuizResultsView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct QuizResultsView: View {
    @Environment(\.theme) var theme
    let attempt: QuizAttempt
    var onDone: () -> Void
    var onReattempt: () -> Void

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.xl) {
                        scoreSection
                        resultTitleSection
                        statsSection
                        questionReviewSection
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.xl)
                    .padding(.bottom, 100)
                }
                doneBar
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = Double(attempt.scorePercent) / 100.0
            }
        }
    }

    private var scoreSection: some View {
        VStack(spacing: theme.spacing.md) {
            Text(attempt.quizName)
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.textPrimary)

            ZStack {
                Circle()
                    .stroke(theme.colors.surface, lineWidth: 14)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(theme.colors.primary, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(attempt.scorePercent)%")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text("SCORE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.colors.textSecondary)
                        .tracking(2)
                }
            }
        }
    }

    private var resultTitleSection: some View {
        VStack(spacing: theme.spacing.xs) {
            Text(attempt.resultTitle)
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.textPrimary)
            Text("You got \(attempt.correctCount) out of \(attempt.questions.count) questions correct.")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var statsSection: some View {
        HStack(spacing: theme.spacing.sm) {
            statCard(label: "TIME SPENT", value: attempt.timeSpentFormatted, valueColor: theme.colors.textPrimary)
            statCard(label: "ACCURACY", value: attempt.accuracyLabel, valueColor: attempt.accuracyColor)
        }
    }

    private func statCard(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .tracking(1.5)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.35), lineWidth: 1))
    }

    private var questionReviewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Question Review")
                    .font(theme.typography.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Button {} label: {
                    Text("SHOW ALL")
                        .font(theme.typography.bodySmall.weight(.bold))
                        .foregroundColor(theme.colors.primary)
                }
            }

            ForEach(Array(attempt.questions.enumerated()), id: \.element.id) { i, q in
                reviewCard(q, index: i)
            }
        }
    }

    private func reviewCard(_ q: QuizQuestion, index: Int) -> some View {
        let userAnswer = attempt.selectedAnswers[q.id]
        let isCorrect = userAnswer == q.correctOptionIndex

        return VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(alignment: .top, spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("\(index + 1)")
                        .font(theme.typography.bodySmall.weight(.bold))
                        .foregroundColor(isCorrect ? .green : .red)
                }
                Text(q.questionText)
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                ZStack {
                    Circle()
                        .fill(isCorrect ? Color.green : Color.red)
                        .frame(width: 28, height: 28)
                    Image(systemName: isCorrect ? "checkmark" : "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            if let ua = userAnswer {
                answerRow(label: "YOUR ANSWER", text: q.options[ua], accentColor: isCorrect ? .green : .red)
            }

            if !isCorrect {
                answerRow(label: "CORRECT ANSWER", text: q.options[q.correctOptionIndex], accentColor: .green)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.35), lineWidth: 1))
    }

    private func answerRow(label: String, text: String, accentColor: Color) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.7))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(accentColor)
                    .tracking(1.5)
                Text(text)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.leading, theme.spacing.sm)
            Spacer()
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.onSurface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }

    private var doneBar: some View {
        HStack(spacing: theme.spacing.sm) {
            Button {
                onDone()
            } label: {
                Text("Done")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.xl)
                            .stroke(theme.colors.primary.opacity(0.5), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            PrimaryButton(title: "Try Again", icon: "arrow.clockwise") {
                onReattempt()
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
        .background(theme.colors.background)
    }
}
