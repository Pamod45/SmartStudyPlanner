//
//  QuizSessionView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct QuizSessionView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var onComplete: (QuizAttempt) -> Void

    @State private var attempt: QuizAttempt
    @State private var currentIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var startTime: Date = Date()
    @State private var showResults: Bool = false

    init(attempt: QuizAttempt, onComplete: @escaping (QuizAttempt) -> Void) {
        _attempt = State(initialValue: attempt)
        self.onComplete = onComplete
    }

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < attempt.questions.count else { return nil }
        return attempt.questions[currentIndex]
    }

    private var progress: Double {
        guard !attempt.questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(attempt.questions.count)
    }

    private var isLastQuestion: Bool {
        currentIndex == attempt.questions.count - 1
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            if showResults {
                QuizResultsView(attempt: attempt) {
                    dismiss()
                }
            } else {
                questionScreen
            }
        }
    }

    private var questionScreen: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.background)

            progressBar
                .padding(.horizontal, theme.spacing.sm)
                .padding(.bottom, theme.spacing.md)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    if let q = currentQuestion {
                        questionBody(q)
                        optionsList(q)
                    }
                }
                .padding(.horizontal, theme.spacing.sm)
                .padding(.bottom, 120)
            }

            bottomBar
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(attempt.quizName)
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Text("QUESTION \(currentIndex + 1)/\(attempt.questions.count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .tracking(0.5)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, 6)
                .background(theme.colors.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.colors.surface)
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.colors.primary)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 4)
    }

    private func questionBody(_ q: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(q.category.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .tracking(1.5)
            Text(q.questionText)
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, theme.spacing.md)
    }

    private func optionsList(_ q: QuizQuestion) -> some View {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return VStack(spacing: theme.spacing.sm) {
            ForEach(Array(q.options.enumerated()), id: \.offset) { i, option in
                let isSelected = selectedOptionIndex == i
                Button { selectedOptionIndex = i } label: {
                    HStack(spacing: theme.spacing.md) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? theme.colors.primary : theme.colors.surface)
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(isSelected ? theme.colors.primary : theme.colors.border.opacity(0.5), lineWidth: 1.5))
                            Text(letters[i])
                                .font(theme.typography.bodyMedium.weight(.bold))
                                .foregroundColor(isSelected ? theme.colors.textOnPrimary : theme.colors.textSecondary)
                        }
                        Text(option)
                            .font(theme.typography.bodyLarge)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        ZStack {
                            Circle().fill(isSelected ? theme.colors.primary : Color.clear).frame(width: 22, height: 22)
                            Circle().stroke(isSelected ? theme.colors.primary : theme.colors.border.opacity(0.5), lineWidth: 1.5).frame(width: 22, height: 22)
                            if isSelected {
                                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(theme.colors.textOnPrimary)
                            }
                        }
                    }
                    .padding(theme.spacing.md)
                    .background(isSelected ? theme.colors.primary.opacity(0.08) : theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                    .overlay(RoundedRectangle(cornerRadius: theme.radius.xl)
                        .stroke(isSelected ? theme.colors.primary.opacity(0.6) : theme.colors.border.opacity(0.35), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            if let q = currentQuestion, !q.expertTip.isEmpty {
                expertTipCard(q.expertTip)
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.sm)
            }
            Divider().background(theme.colors.border.opacity(0.3))
            Button {
                guard let opt = selectedOptionIndex,
                      let q = currentQuestion else { return }
                attempt.selectedAnswers[q.id] = opt
                if isLastQuestion {
                    let completed = QuizAttempt(
                        id: attempt.id,
                        quizName: attempt.quizName,
                        topicName: attempt.topicName,
                        questions: attempt.questions,
                        selectedAnswers: attempt.selectedAnswers,
                        completedAt: Date(),
                        timeSpentSeconds: Int(Date().timeIntervalSince(startTime)),
                        subjectColor: attempt.subjectColor
                    )
                    attempt = completed
                    onComplete(completed)
                    withAnimation(.easeInOut(duration: 0.3)) { showResults = true }
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentIndex += 1
                        selectedOptionIndex = nil
                    }
                }
            } label: {
                HStack(spacing: theme.spacing.sm) {
                    Text(isLastQuestion ? "Submit Quiz" : "Next Question")
                        .font(theme.typography.bodyLarge.weight(.semibold))
                    if !isLastQuestion {
                        Image(systemName: "arrow.right")
                            .font(theme.typography.bodyLarge.weight(.semibold))
                    }
                }
                .foregroundColor(theme.colors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(selectedOptionIndex != nil ? theme.colors.primary : theme.colors.primary.opacity(0.4))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selectedOptionIndex == nil)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.background)
        }
    }

    private func expertTipCard(_ tip: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.primary)
            Text(tip)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.primary.opacity(0.2), lineWidth: 1))
    }
}
