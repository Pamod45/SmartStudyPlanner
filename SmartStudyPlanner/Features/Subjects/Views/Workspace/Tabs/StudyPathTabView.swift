//
//  StudyPathTabView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//

import SwiftUI

struct StudyPathTabView: View {
    @Environment(\.theme) var theme

    let subject: Subject
    let resources: [Resource]
    @Binding var studyPath: StudyPath?
    var onRegenerate: () -> Void
    var onGenerate: () -> Void

    @State private var expandedTopicID: UUID? = nil

    private var overallCompletion: Int {
        guard let path = studyPath, !path.topics.isEmpty else { return 0 }
        let total = path.topics.reduce(0) { $0 + $1.weightPercent }
        let done  = path.topics.reduce(0) { $0 + ($1.completionPercent * $1.weightPercent / 100) }
        guard total > 0 else { return 0 }
        return done * 100 / total
    }

    var body: some View {
        if let path = studyPath {
            curriculumView(path: path)
        } else {
            emptyView
        }
    }

    private var emptyView: some View {
        VStack(spacing: theme.spacing.lg) {
            Spacer(minLength: 40)
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary)
            Text("No Study Path Yet")
                .font(theme.typography.headingSmall)
                .foregroundColor(theme.colors.textPrimary)
            Text("Generate a personalised curriculum\nfrom your uploaded resources.")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Generate Study Path") { onGenerate() }
                .padding(.horizontal, theme.spacing.xl)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, theme.spacing.xl)
    }

    private func curriculumView(path: StudyPath) -> some View {
        VStack(spacing: theme.spacing.md) {
            regenerateButton

            HStack {
                Text("Curriculum Flow")
                    .font(theme.typography.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text("\(overallCompletion)% Completed")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(path.topics.enumerated()), id: \.element.id) { index, topic in
                    timelineRow(topic: topic, index: index, totalCount: path.topics.count)
                }
            }
        }
        .padding(.bottom, theme.spacing.xl)
    }

    private var regenerateButton: some View {
        Button { onRegenerate() } label: {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "arrow.clockwise")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                Text("Regenerate Study Path")
                    .font(theme.typography.bodyLarge.weight(.semibold))
            }
            .foregroundColor(theme.colors.textOnPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func timelineRow(topic: StudyPathTopic, index: Int, totalCount: Int) -> some View {
        let isExpanded = expandedTopicID == topic.id
        let isCurrent  = !topic.isCompleted && (index == 0 || (studyPath?.topics[index - 1].isCompleted ?? false))

        return HStack(alignment: .top, spacing: theme.spacing.sm) {
            timelineIndicator(topic: topic, index: index, totalCount: totalCount, isCurrent: isCurrent)
            topicCard(topic: topic, isExpanded: isExpanded, isCurrent: isCurrent)
                .padding(.bottom, index < totalCount - 1 ? theme.spacing.md : 0)
        }
    }

    private func timelineIndicator(topic: StudyPathTopic, index: Int, totalCount: Int, isCurrent: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(
                        topic.isCompleted ? theme.colors.textSecondary.opacity(0.25) :
                        isCurrent        ? theme.colors.primary :
                                           theme.colors.surface
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().stroke(
                            topic.isCompleted ? theme.colors.textSecondary.opacity(0.35) :
                            isCurrent        ? theme.colors.primary :
                                               theme.colors.border.opacity(0.5),
                            lineWidth: 1.5
                        )
                    )
                if isCurrent {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.colors.textOnPrimary)
                } else {
                    Text("\(topic.order)")
                        .font(theme.typography.bodySmall.weight(.bold))
                        .foregroundColor(topic.isCompleted ? theme.colors.textSecondary : theme.colors.textPrimary)
                }
            }
            if index < totalCount - 1 {
                Rectangle()
                    .fill(theme.colors.border.opacity(0.35))
                    .frame(width: 2)
                    .frame(minHeight: 40)
            }
        }
        .frame(width: 36)
    }

    private func topicCard(topic: StudyPathTopic, isExpanded: Bool, isCurrent: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                expandedTopicID = isExpanded ? nil : topic.id
            }
        } label: {
            HStack(spacing: 0) {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.colors.primary)
                        .frame(width: 4)
                        .padding(.vertical, 1)
                }
                VStack(alignment: .leading, spacing: 0) {
                    topicCardHeader(topic: topic, isExpanded: isExpanded)
                    if isExpanded {
                        topicCardExpanded(topic: topic, isCurrent: isCurrent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.xl)
                    .stroke(
                        isCurrent ? theme.colors.primary.opacity(0.5) : theme.colors.border.opacity(0.35),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func topicCardHeader(topic: StudyPathTopic, isExpanded: Bool) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(topic.title)
                    .font(theme.typography.headingSmall)
                    .foregroundColor(theme.colors.textPrimary)

                HStack(alignment: .top, spacing: theme.spacing.xs) {
                    Text(topic.description)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text("\(topic.weightPercent)%")
                        .font(theme.typography.bodySmall.weight(.semibold))
                        .foregroundColor(theme.colors.textSecondary)
                }

                if topic.isCompleted && !isExpanded {
                    completedBadge
                }
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.top, 2)
        }
        .padding(theme.spacing.md)
    }

    private var completedBadge: some View {
        Text("COMPLETED")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(theme.colors.textSecondary)
            .tracking(1.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.colors.textSecondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private func topicCardExpanded(topic: StudyPathTopic, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if topic.isCompleted {
                completedBadge
                    .padding(.horizontal, theme.spacing.md)
            }

            if !topic.subtopics.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    ForEach(topic.subtopics, id: \.self) { subtopic in
                        HStack(alignment: .top, spacing: theme.spacing.sm) {
                            Circle()
                                .fill(theme.colors.textSecondary.opacity(0.6))
                                .frame(width: 5, height: 5)
                                .padding(.top, 7)
                            Text(subtopic)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.md)
            }

            if !topic.resources.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("TOPIC RESOURCES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.colors.textSecondary)
                        .tracking(1.5)
                        .padding(.horizontal, theme.spacing.md)

                    VStack(spacing: theme.spacing.xs) {
                        ForEach(topic.resources) { resource in
                            topicResourceRow(resource)
                        }
                    }
                    .padding(.horizontal, theme.spacing.md)
                }
            }

            if !topic.isCompleted {
                HStack(spacing: theme.spacing.sm) {
                    PrimaryButton(
                        title: "Mark Complete",
                        action: {
                            if let idx = studyPath?.topics.firstIndex(where: { $0.id == topic.id }) {
                                studyPath?.topics[idx].isCompleted = true
                                studyPath?.topics[idx].completionPercent = 100
                                expandedTopicID = nil
                            }
                        },
                        font: theme.typography.bodyLarge.weight(.semibold)
                    )
                    Button {
                    } label: {
                        Text("Take Quiz")
                            .font(theme.typography.bodyLarge.weight(.semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.md)
                            .background(theme.colors.onSurface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, theme.spacing.md)
            }
        }
        .padding(.bottom, theme.spacing.md)
    }

    private func topicResourceRow(_ resource: Resource) -> some View {
        HStack(spacing: theme.spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(resource.type.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(resource.type.color.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: resource.type.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(resource.type.color)
            }
            Text(resource.name)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "eye")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.onSurface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }
}
