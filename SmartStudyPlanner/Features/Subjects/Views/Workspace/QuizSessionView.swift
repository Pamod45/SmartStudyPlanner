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
    @State private var showQuitAlert: Bool = false

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
                QuizResultsView(
                    attempt: attempt,
                    onDone: { dismiss() },
                    onReattempt: { resetForReattempt() }
                )
            } else {
                questionScreen
            }
        }.background(theme.colors.surface.opacity(0.2))
    }
    
    private func resetForReattempt() {
        let fresh = QuizAttempt(
            id: UUID().uuidString,
            userId:          attempt.userId,
            quizId:          attempt.quizId,
            quizName:        attempt.quizName,
            topicName:       attempt.topicName,
            subjectId:       attempt.subjectId,
            subjectColorHex: attempt.subjectColorHex,
            questions:       attempt.questions, 
            selectedAnswers: [:],
            answers:         [],
            timeSpentSeconds: 0,
            completedAt:     Date(),
            syncStatus:      .localOnly
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            attempt             = fresh
            currentIndex        = 0
            selectedOptionIndex = nil
            startTime           = Date()
            showResults         = false
        }
    }

    private var questionScreen: some View {
        VStack(spacing: 0) {
            header
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.background)

            progressBar
                .padding(.bottom, theme.spacing.md)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    if let q = currentQuestion {
                        questionBody(q)
                        optionsList(q)
                    }
                }
                .padding(.bottom, 120)
            }

            bottomBar
        }.padding(.horizontal, theme.spacing.lg)
    }

    private var header: some View {
        HStack(spacing: 0) {
            TextButton(title: "", icon: "arrow.left", style: .bold) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentIndex -= 1
                    selectedOptionIndex = attempt.selectedAnswers[attempt.questions[currentIndex].id]
                }
            }
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.3 : 1)
            .padding(.trailing,theme.spacing.sm)

            Text(attempt.quizName)
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
                .padding(.trailing, theme.spacing.sm)

            Text("QUESTION \(currentIndex + 1)/\(attempt.questions.count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.colors.primary)
                .tracking(0.5)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, 4)
                .background(theme.colors.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
            
            Spacer()
            
            Button {
                showQuitAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }
            .buttonStyle(.plain)
            .alert("Quit Quiz?", isPresented: $showQuitAlert) {
                Button("Quit", role: .destructive) { dismiss() }
                Button("Keep Going", role: .cancel) { }
            } message: {
                Text("Your progress will be lost. Are you sure you want to leave?")
            }
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
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .tracking(1.5)
            Text(q.questionText)
                .font(theme.typography.headingLarge)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, theme.spacing.md)
    }

    private func optionsList(_ q: QuizQuestion) -> some View {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return VStack(spacing: theme.spacing.md) {
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
                    .padding(.bottom, theme.spacing.md)
            }
            
            PrimaryButton(
                title: isLastQuestion ? "Submit Quiz" : "Next Question"
            )
            {
                guard let opt = selectedOptionIndex,
                      let q = currentQuestion else { return }
                attempt.selectedAnswers[q.id] = opt
                if isLastQuestion {
                    let completed = QuizAttempt(id: attempt.id, quizName: attempt.quizName, topicName: attempt.topicName, subjectId: attempt.subjectId, subjectColorHex: attempt.subjectColorHex, questions: attempt.questions, selectedAnswers: attempt.selectedAnswers, timeSpentSeconds: Int(Date().timeIntervalSince(startTime)), completedAt: Date())
                    attempt = completed
                    onComplete(completed)
                    withAnimation(.easeInOut(duration: 0.3)) { showResults = true }
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentIndex += 1
                        selectedOptionIndex = nil
                    }
                }
            }
            .opacity(selectedOptionIndex != nil ? 1 : 0.5)
        }
    }

    private func expertTipCard(_ tip: String) -> some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            Image(systemName: "lightbulb")
                .font(theme.typography.bodyLarge.weight(.bold))
                .foregroundColor(theme.colors.primary)
            (
                Text("EXPERT TIP: ").foregroundColor(theme.colors.primary).bold() +
                Text(tip)
            )
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.all, theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.primary.opacity(0.2), lineWidth: 1))
    }
}
