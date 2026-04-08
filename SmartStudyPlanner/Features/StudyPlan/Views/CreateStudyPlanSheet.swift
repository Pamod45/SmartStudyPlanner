import SwiftUI

struct CreateStudyPlanSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var availabilitySlots: [AvailabilitySlot] = []

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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isSelected {
                            selectedSubjectIDs.remove(subject.id)
                            topics.forEach { selectedTopicIDs.remove("\(subject.id)-\($0.id)") }
                            if isExpanded { expandedSubjectID = nil }
                        } else {
                            selectedSubjectIDs.insert(subject.id)
                            topics.forEach { selectedTopicIDs.insert("\(subject.id)-\($0.id)") }
                            expandedSubjectID = subject.id
                        }
                    }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
                .background(theme.colors.background.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                .padding(.horizontal, theme.spacing.sm)
                .padding(.bottom, theme.spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }

    private func topicRow(_ topic: StudyTopic, subject: Subject) -> some View {
        let topicKey = "\(subject.id)-\(topic.id)"
        let isSelected = selectedTopicIDs.contains(topicKey)

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                if isSelected {
                    selectedTopicIDs.remove(topicKey)
                    if allTopicsDeselected(for: subject) {
                        selectedSubjectIDs.remove(subject.id)
                    }
                } else {
                    selectedTopicIDs.insert(topicKey)
                    selectedSubjectIDs.insert(subject.id)
                }
            }
        } label: {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
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

    private func sampleTopics(for subject: Subject) -> [StudyTopic] {
        let names = ["Linear \(subject.name)", "Non Linear \(subject.name)", "Time Complexity", "Advanced Topics"]
        return names.enumerated().map { i, name in
            StudyTopic(name: name, resources: (i + 1) * 2, estimatedHours: (i + 1) * 3)
        }
    }
}

struct StudyTopic: Identifiable {
    let id: UUID = UUID()
    let name: String
    let resources: Int
    let estimatedHours: Int
}

#Preview {
    CreateStudyPlanSheet()
        .environment(\.theme, AppTheme.defaultTheme)
}
