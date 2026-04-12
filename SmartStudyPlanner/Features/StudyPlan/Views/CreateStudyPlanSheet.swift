import SwiftUI

struct CreateStudyPlanSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var availabilitySlots: [AvailabilitySlot] = []
    var onPlanCreated: (([StudySession]) -> Void)? = nil

    @State private var startDate: Date = .now
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var expandedSubjectID: UUID? = nil
    @State private var selectedSubjectIDs: Set<UUID> = []
    @State private var selectedTopicIDs: Set<String> = []

    let subjects: [Subject] = Subject.samples

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                Divider().background(theme.colors.border.opacity(0.3))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        FieldSection(title: "PLAN DURATION") {
                            VStack(spacing: 0) {
                                dateRow(label: "Start Date", date: $startDate)
                                Divider()
                                    .background(theme.colors.background)
                                    .padding(.leading, theme.spacing.md)
                                dateRow(label: "End Date", date: $endDate)
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        FieldSection(title: "FOCUS SUBJECTS") {
                            VStack(spacing: theme.spacing.md) {
                                ForEach(subjects) { subject in
                                    subjectRow(subject)
                                }
                            }
                        }
                    }
                    .padding(theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xxl)
                }
            }
            .background(theme.colors.surface.opacity(0.2))
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Create Study Plan")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Button("Create") {
                let sessions = generateSessions()
                onPlanCreated?(sessions)
                dismiss()
            }
            .font(theme.typography.bodyMedium)
            .fontWeight(.semibold)
            .foregroundColor(selectedSubjectIDs.isEmpty ? theme.colors.textSecondary : theme.colors.primary)
            .disabled(selectedSubjectIDs.isEmpty)
        }
    }

    private func dateRow(label: String, date: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            DatePicker("", selection: date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(theme.colors.primary)
        }
        .padding(theme.spacing.md)
    }

    private func topicKeys(for subject: Subject) -> [String] {
        sampleTopics(for: subject).map { "\(subject.id)-\($0.id)" }
    }

    private func allTopicsDeselected(for subject: Subject) -> Bool {
        let keys = topicKeys(for: subject)
        return keys.allSatisfy { !selectedTopicIDs.contains($0) }
    }

    private func subjectRow(_ subject: Subject) -> some View {
        let isSelected = selectedSubjectIDs.contains(subject.id)
        let isExpanded = expandedSubjectID == subject.id
        let topics = sampleTopics(for: subject)
        let totalHrs = topics.reduce(0) { $0 + $1.estimatedHours }

        return VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        if selectedSubjectIDs.contains(subject.id) {
                            selectedSubjectIDs.remove(subject.id)
                            topics.forEach { selectedTopicIDs.remove("\(subject.id)-\($0.id)") }
                        } else {
                            selectedSubjectIDs.insert(subject.id)
                            topics.forEach { selectedTopicIDs.insert("\(subject.id)-\($0.id)") }
                        }
                    }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(isSelected ? theme.colors.primary : theme.colors.textSecondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(subject.name)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("\(topics.count) Topics • \(subject.resources) Resources")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Text("Est. \(totalHrs) Hrs")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)

                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        expandedSubjectID = isExpanded ? nil : subject.id
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(theme.colors.border.opacity(0.5), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(theme.spacing.md)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(topics) { topic in
                        topicRow(topic, subject: subject)

                        if topic.id != topics.last?.id {
                            Divider()
                                .background(theme.colors.border.opacity(0.15))
                                .padding(.leading, theme.spacing.xl)
                        }
                    }
                }
                .padding(theme.spacing.sm)
                .background(theme.colors.onSurface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                .padding(.horizontal, theme.spacing.sm)
                .padding(.bottom, theme.spacing.sm)
            }
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
    }

    private func topicRow(_ topic: StudyTopic, subject: Subject) -> some View {
        let topicKey = "\(subject.id)-\(topic.id)"
        return TopicRowView(
            topic: topic,
            isSelected: selectedTopicIDs.contains(topicKey),
            onTap: {
                withAnimation(.spring(duration: 0.4)) {
                    if selectedTopicIDs.contains(topicKey) {
                        selectedTopicIDs.remove(topicKey)
                        if allTopicsDeselected(for: subject) {
                            selectedSubjectIDs.remove(subject.id)
                        }
                    } else {
                        selectedTopicIDs.insert(topicKey)
                        if !selectedSubjectIDs.contains(subject.id) {
                            selectedSubjectIDs.insert(subject.id)
                        }
                    }
                }
            }
        )
    }

    private func sampleTopics(for subject: Subject) -> [StudyTopic] {
        StudyTopic.samples(for: subject)
    }
    
    private func generateSessions() -> [StudySession] {
        let cal = Calendar.current
        let today = Date()

        var pairs: [(subject: Subject, topic: StudyTopic)] = []
        for subject in subjects where selectedSubjectIDs.contains(subject.id) {
            let topics = sampleTopics(for: subject)
            for topic in topics {
                let key = "\(subject.id)-\(topic.id)"
                if selectedTopicIDs.contains(key) {
                    pairs.append((subject, topic))
                }
            }
        }

        guard !pairs.isEmpty else { return [] }

        var studyDates: [Date] = []
        var cursor = today
        while studyDates.count < 4, cursor <= endDate {
            let hasSlot = availabilitySlots.contains { slot in
                switch slot.type {
                case .date:
                    return slot.date.map { cal.isDate($0, inSameDayAs: cursor) } ?? false
                case .daily:
                    return true
                case .weekly:
                    return slot.weekday == cal.component(.weekday, from: cursor)
                case .range:
                    guard let s = slot.rangeStart, let e = slot.rangeEnd else { return false }
                    return cursor >= s && cursor <= e
                }
            }
            if hasSlot { studyDates.append(cursor) }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }

        if studyDates.isEmpty {
            studyDates = (1...3).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
        }

        var sessions: [StudySession] = []
        var dayIndex = 0
        var sessionStartHour = 9

        for (idx, pair) in pairs.enumerated() {
            guard dayIndex < studyDates.count else { break }

            let day = studyDates[dayIndex]
            let durationHours = min(pair.topic.estimatedHours, 2)
            guard let start = cal.date(bySettingHour: sessionStartHour, minute: 0, second: 0, of: day),
                  let end   = cal.date(bySettingHour: sessionStartHour + durationHours, minute: 0, second: 0, of: day)
            else { continue }

            let session = StudySession(
                subject: pair.subject.name,
                topic: pair.topic.name,
                title: pair.topic.name,
                startTime: start,
                endTime: end,
                subjectColor: pair.subject.color,
                hasReminder: false
            )
            sessions.append(session)

            sessionStartHour += durationHours + 1
            if (idx + 1) % 2 == 0 {
                dayIndex += 1
                sessionStartHour = 9
            }
        }

        return sessions
    }
}

private struct TopicRowView: View {
    @Environment(\.theme) var theme
    let topic: StudyTopic
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(isSelected ? theme.colors.primary : theme.colors.textSecondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(topic.name)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("\(topic.resources) Resources")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Text("Est. \(topic.estimatedHours) Hrs")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateStudyPlanSheet()
        .environment(\.theme, AppTheme.defaultTheme)
}
