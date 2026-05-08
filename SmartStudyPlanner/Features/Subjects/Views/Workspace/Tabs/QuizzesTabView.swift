//
//  QuizzesTabView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//

import SwiftUI

// Shows quiz history for a subject and coordinates creating, running, saving, and deleting quiz attempts.
struct QuizzesTabView: View {
    @Environment(\.theme) var theme

    let subject: Subject
    let studyPath: StudyPath?
    let resources: [Resource]
    @Binding var attempts: [QuizAttempt]

    @State private var showConfig: Bool = false
    @State private var activeAttempt: QuizAttempt? = nil
    @State private var selectedGroup: QuizGroup? = nil
    @State private var isLoadingAttempts: Bool = false

    // Attempts are grouped by quiz name so repeated attempts appear under one quiz history card.
    private var quizGroups: [QuizGroup] {
        var dict: [String: [QuizAttempt]] = [:]
        for a in attempts {
            dict[a.quizName, default: []].append(a)
        }
        return dict
            .map { name, list -> QuizGroup in
                let sorted = list.sorted { $0.completedAt > $1.completedAt }
                return QuizGroup(
                    id:          name,
                    quizName:    name,
                    topicName:   sorted.first?.topicName ?? "",
                    attempts:    sorted
                )
            }
            .sorted { ($0.latestAttempt?.completedAt ?? .distantPast) > ($1.latestAttempt?.completedAt ?? .distantPast) }
    }

    private var overallAverage: Int {
        guard !attempts.isEmpty else { return 0 }
        return attempts.reduce(0) { $0 + $1.scorePercent } / attempts.count
    }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            if !attempts.isEmpty {
                startButton
                statsRow
                quizGroupsSection
            } else {
                emptyView
            }
        }
        .padding(.bottom, theme.spacing.xl)
        .sheet(isPresented: $showConfig) {
            QuizConfigSheet(
                subject: subject,
                studyPath: studyPath,
                resources: resources
            ) { newAttempt in
                activeAttempt = newAttempt
            }
            .environment(\.theme, theme)
        }
        .fullScreenCover(item: $activeAttempt) { attempt in
            QuizSessionView(attempt: attempt) { completed in
                attempts.insert(completed, at: 0)
                CoreDataService.shared.upsertAttempt(completed)
                Task {
                    do {
                        try await QuizService.shared.saveAttempt(completed, userId: subject.userId)
                    } catch {
                        print("[QuizzesTabView] Failed to save attempt: \(error)")
                    }
                }
            }
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedGroup) { group in
            QuizHistorySheet(group: group) { template in
                let fresh = QuizAttempt(
                    id:              UUID().uuidString,
                    userId:          template.userId,
                    quizId:          template.quizId,
                    quizName:        template.quizName,
                    topicName:       template.topicName,
                    subjectId:       template.subjectId,
                    subjectColorHex: template.subjectColorHex,
                    questions:       template.questions,
                    selectedAnswers: [:],
                    answers:         [],
                    timeSpentSeconds: 0,
                    syncStatus:      .localOnly
                )
                activeAttempt = fresh
            }
            .environment(\.theme, theme)
        }
        .onAppear {
            // Show cached attempts immediately, then refresh from Firebase.
            let cached = CoreDataService.shared.getCachedAttempts(for: subject.id)
            if !cached.isEmpty { attempts = cached }
            guard !isLoadingAttempts else { return }
            isLoadingAttempts = true
            Task {
                do {
                    let fresh = try await QuizService.shared.fetchAttempts(subjectId: subject.id)
                    await MainActor.run {
                        attempts = fresh
                        isLoadingAttempts = false
                    }
                } catch {
                    print("[QuizzesTabView] Failed to fetch attempts: \(error)")
                    await MainActor.run { isLoadingAttempts = false }
                }
            }
        }
    }

    private var startButton: some View {
        PrimaryButton(title: "Start New Quiz", icon: "play.fill") {
            showConfig = true
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: theme.spacing.sm) {
            statCard(label: "AVERAGE SCORE",  value: "\(overallAverage)", unit: "%")
            statCard(label: "QUIZZES TAKEN",  value: "\(quizGroups.count)", unit: nil, icon: "doc.text")
            statCard(label: "TOTAL ATTEMPTS", value: "\(attempts.count)",   unit: nil, icon: "arrow.clockwise")
        }
    }

    private func statCard(label: String, value: String, unit: String?, icon: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .tracking(1.4)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                if let u = unit {
                    Text(u)
                        .font(theme.typography.bodyMedium.weight(.semibold))
                        .foregroundColor(theme.colors.textSecondary)
                }
                if let ic = icon {
                    Image(systemName: ic)
                        .font(theme.typography.bodySmall)
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

    private var quizGroupsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("My Quizzes")
                .font(theme.typography.headingSmall)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: theme.spacing.sm) {
                ForEach(quizGroups) { group in
                    quizGroupCard(group)
                }
            }
        }
    }

    private func quizGroupCard(_ group: QuizGroup) -> some View {
        Button {
            selectedGroup = group
        } label: {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radius.lg)
                        .fill(group.scoreColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    VStack(spacing: 1) {
                        Text("\(group.latestScore)%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(group.scoreColor)
                        Text("LAST")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(group.scoreColor.opacity(0.7))
                            .tracking(0.8)
                    }
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(group.quizName)
                        .font(theme.typography.bodyLarge.weight(.semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    Text(group.topicName)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: theme.spacing.sm) {
                        Label(
                            group.attemptCount == 1 ? "1 attempt" : "\(group.attemptCount) attempts",
                            systemImage: "arrow.clockwise"
                        )
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.colors.primary.opacity(0.1))
                        .clipShape(Capsule())

                        if group.attemptCount > 1 {
                            Label("Best \(group.bestScore)%", systemImage: "star.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Capsule())
                        }
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
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.xl)
                    .stroke(theme.colors.border.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteQuizGroup(group)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // Deleting a quiz group removes every attempt for that quiz from UI, Core Data, and Firebase.
    private func deleteQuizGroup(_ group: QuizGroup) {
        let attemptIds = group.attempts.map(\.id)
        attempts.removeAll { attemptIds.contains($0.id) }
        attemptIds.forEach { CoreDataService.shared.deleteAttempt(id: $0) }

        Task {
            do {
                try await QuizService.shared.deleteAttempts(ids: attemptIds)
            } catch {
                print("[QuizzesTabView] Failed to delete quiz group: \(error)")
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: theme.spacing.lg) {
            Spacer(minLength: 40)
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary)
            Text("No quizzes yet")
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.textPrimary)
            Text("Start your first quiz to track your progress.")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            startButton
                .padding(.horizontal, theme.spacing.md)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, theme.spacing.xl)
    }
}
