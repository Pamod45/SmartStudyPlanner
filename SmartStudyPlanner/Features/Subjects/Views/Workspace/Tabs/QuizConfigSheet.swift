//
//  QuizConfigSheet.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct QuizConfigSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let subject: Subject
    let studyPath: StudyPath?
    let resources: [Resource]
    var onStart: (QuizAttempt) -> Void

    @State private var quizName: String = ""
    @State private var questionCountText: String = ""
    @State private var configTab: ConfigTab = .topics
    @State private var selectedTopicIDs: Set<UUID> = []
    @State private var selectedResourceIDs: Set<UUID> = []

    enum ConfigTab { case topics, resources }

    private var questionCount: Int { Int(questionCountText) ?? 5 }

    private var topics: [StudyPathTopic] {
        studyPath?.topics ?? []
    }

    private var sessionSettingsText: String {
        let sel = topics.filter { selectedTopicIDs.contains($0.id) }
        if sel.isEmpty { return "Select topics above to configure your quiz session." }
        let names = sel.prefix(2).map { $0.title }.joined(separator: " and ")
        let extra = sel.count > 2 ? " and \(sel.count - 2) more" : ""
        return "Questions will be weighted towards \(names)\(extra). Duration is set to 15 minutes by default."
    }

    private var canStart: Bool {
        configTab == .topics ? !selectedTopicIDs.isEmpty : !selectedResourceIDs.isEmpty
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        titleSection
                        quizIdentitySection
                        questionCountSection
                        tabSection
                        sessionSettingsSection
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.xl)
                    .padding(.bottom, 100)
                }
                startButton
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: 0) {
                Text("Configure your\n")
                    .font(theme.typography.headingLarge ?? theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            Text("Quiz Resources.")
                .font(theme.typography.headingLarge ?? theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.primary)
                .offset(y: -theme.spacing.md)

            Text("Select the materials you want to be quizzed on. Our AI will generate unique questions based on these specific files.")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    private var quizIdentitySection: some View {
        FieldSection(title: "QUIZ IDENTITY") {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "pencil.and.scribble")
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(width: 20)
                TextField("", text: $quizName,
                          prompt: Text("Enter Quiz Name (e.g., Midterm Prep)")
                            .foregroundColor(theme.colors.textSecondary))
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
        }
    }

    private var questionCountSection: some View {
        FieldSection(title: "NUMBER OF QUESTIONS") {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "list.number")
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(width: 20)
                TextField("", text: $questionCountText,
                          prompt: Text("e.g., 20")
                            .foregroundColor(theme.colors.textSecondary))
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
        }
    }

    private var tabSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: 4) {
                tabButton(label: "Topics", tab: .topics)
                tabButton(label: "Resources", tab: .resources)
            }
            .padding(4)
            .background(theme.colors.surface)
            .clipShape(Capsule())

            if configTab == .topics {
                topicsContent
            } else {
                resourcesContent
            }
        }
    }

    private func tabButton(label: String, tab: ConfigTab) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { configTab = tab } } label: {
            Text(label)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(configTab == tab ? theme.colors.textOnPrimary : theme.colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.sm)
                .background(configTab == tab ? theme.colors.primary : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var topicsContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("CORE TOPICS")
                    .font(theme.typography.caption.weight(.bold))
                    .foregroundColor(theme.colors.textSecondary)
                    .tracking(2)
                Spacer()
                Button {
                    if selectedTopicIDs.count == topics.count {
                        selectedTopicIDs = []
                    } else {
                        selectedTopicIDs = Set(topics.map { $0.id })
                    }
                } label: {
                    Text(selectedTopicIDs.count == topics.count ? "Deselect All" : "Select All")
                        .font(theme.typography.bodyMedium.weight(.semibold))
                        .foregroundColor(theme.colors.primary)
                }
            }

            if topics.isEmpty {
                Text("Generate a study path first to see topics here.")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            } else {
                VStack(spacing: theme.spacing.sm) {
                    ForEach(topics) { topic in
                        topicRow(topic)
                    }
                }
            }
        }
    }

    private func topicRow(_ topic: StudyPathTopic) -> some View {
        let isSelected = selectedTopicIDs.contains(topic.id)
        return Button {
            if isSelected { selectedTopicIDs.remove(topic.id) }
            else { selectedTopicIDs.insert(topic.id) }
        } label: {
            HStack(spacing: theme.spacing.md) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(topic.title)
                        .font(theme.typography.bodyLarge.weight(.semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(topic.subtopics.prefix(3).joined(separator: ", "))
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.colors.primary : Color.clear)
                        .frame(width: 24, height: 24)
                    Circle()
                        .stroke(isSelected ? theme.colors.primary : theme.colors.border.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.colors.textOnPrimary)
                    }
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(isSelected ? theme.colors.primary.opacity(0.5) : theme.colors.border.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var resourcesContent: some View {
        VStack(spacing: theme.spacing.sm) {
            ForEach(resources) { resource in
                resourceRow(resource)
            }
        }
    }

    private func resourceRow(_ resource: Resource) -> some View {
        let isSelected = selectedResourceIDs.contains(resource.id)
        return Button {
            if isSelected { selectedResourceIDs.remove(resource.id) }
            else { selectedResourceIDs.insert(resource.id) }
        } label: {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radius.lg)
                        .fill(resource.type.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: theme.radius.lg)
                            .stroke(resource.type.color.opacity(0.3), lineWidth: 1))
                    Image(systemName: resource.type.icon)
                        .font(theme.typography.bodyLarge.weight(.semibold))
                        .foregroundColor(resource.type.color)
                }
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(resource.name)
                        .font(theme.typography.bodyMedium.weight(.semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(resource.type.rawValue)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle().fill(isSelected ? theme.colors.primary : Color.clear).frame(width: 24, height: 24)
                    Circle().stroke(isSelected ? theme.colors.primary : theme.colors.border.opacity(0.6), lineWidth: 1.5).frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(theme.colors.textOnPrimary)
                    }
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(isSelected ? theme.colors.primary.opacity(0.5) : theme.colors.border.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var sessionSettingsSection: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            Image(systemName: "info.circle.fill")
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.primary)
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Session Settings")
                    .font(theme.typography.bodyLarge.weight(.bold))
                    .foregroundColor(theme.colors.primary)
                Text(sessionSettingsText)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(RoundedRectangle(cornerRadius: theme.radius.xl).stroke(theme.colors.primary.opacity(0.2), lineWidth: 1))
    }

    private var startButton: some View {
        VStack(spacing: 0) {
            Divider().background(theme.colors.border.opacity(0.3))
            PrimaryButton(title: "Start Quiz", icon: "play.fill") {
                let selTopics = topics.filter { selectedTopicIDs.contains($0.id) }
                let selResources = resources.filter { selectedResourceIDs.contains($0.id) }
                let count = max(3, questionCount)
                let questions = QuizAttempt.generateQuestions(from: selTopics, resources: selResources, count: count)
                let name = quizName.isEmpty ? (selTopics.first?.title ?? "Custom Quiz") : quizName
                let attempt = QuizAttempt(
                    quizName: name,
                    topicName: selTopics.first?.title ?? "Custom",
                    questions: questions,
                    timeSpentSeconds: 0,
                    subjectColor: subject.color
                )
                onStart(attempt)
                dismiss()
            }
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.background)
        }
    }
}
