import SwiftUI

struct AddStudySessionSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    let slot: AvailabilitySlot
    var scheduledDate: Date? = nil       // the calendar day tapped (required for dateRange slots)
    var existingSession: StudySession? = nil
    var onSave: (StudySession) -> Void
    var onDelete: (() -> Void)? = nil

    @State private var selectedSubject: Subject? = nil
    @State private var selectedTopic: StudyTopic? = nil
    @State private var customTopic: String = ""
    @State private var useCustomTopic: Bool = false
    @State private var availableResources: [Resource] = []
    @State private var selectedResourceIDs: Set<String> = []
    @State private var pendingResourceIDs: Set<String> = []
    @State private var startTime: Date = .now
    @State private var endTime: Date = .now
    @State private var notes: String = ""
    @State private var hasReminder: Bool = false
    var availableSubjects: [Subject] = []

    private var isEditing: Bool { existingSession != nil }

    private var topicName: String {
        useCustomTopic ? customTopic : (selectedTopic?.name ?? "")
    }

    private var canSave: Bool {
        selectedSubject != nil && !topicName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var systemTopics: [StudyTopic] { [] }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                Divider().background(theme.colors.border.opacity(0.3))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {

                        FieldSection(title: "SUBJECT") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.sm) {
                                    if availableSubjects.isEmpty {
                                        Text("No subjects yet — add one first")
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.colors.textSecondary)
                                    } else {
                                        ForEach(availableSubjects) { subject in
                                            subjectChip(subject)
                                        }
                                    }
                                }
                            }
                        }

                        if selectedSubject != nil {
                            FieldSection(title: "TOPIC") {
                                VStack(alignment: .leading, spacing: theme.spacing.md) {

                                    if !useCustomTopic {
                                        VStack(spacing: 0) {
                                            ForEach(systemTopics) { topic in
                                                topicRow(topic)
                                                if topic.id != systemTopics.last?.id {
                                                    Divider()
                                                        .background(theme.colors.border.opacity(0.2))
                                                        .padding(.leading, theme.spacing.xl + theme.spacing.md)
                                                }
                                            }
                                        }
                                        .background(theme.colors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                                    }

                                    Button {
                                        withAnimation(.spring(duration: 0.3)) {
                                            useCustomTopic.toggle()
                                            if useCustomTopic {
                                                selectedTopic = nil
                                                selectedResourceIDs = []
                                            } else {
                                                customTopic = ""
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: theme.spacing.sm) {
                                            Image(systemName: useCustomTopic ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(useCustomTopic ? theme.colors.primary : theme.colors.textSecondary)
                                            Text("Enter custom topic")
                                                .font(theme.typography.bodySmall)
                                                .foregroundColor(theme.colors.textSecondary)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    if useCustomTopic {
                                        TextField(
                                            "",
                                            text: $customTopic,
                                            prompt: Text("e.g., Hash Tables")
                                                .foregroundColor(theme.colors.textSecondary)
                                        )
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.colors.textPrimary)
                                        .tint(theme.colors.primary)
                                        .padding(theme.spacing.md)
                                        .background(theme.colors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                                    }
                                }
                            }
                        }

                        if selectedSubject != nil && !availableResources.isEmpty {
                            FieldSection(title: "RESOURCES") {
                                VStack(spacing: 0) {
                                    ForEach(availableResources) { resource in
                                        resourceRow(resource)
                                        if resource.id != availableResources.last?.id {
                                            Divider()
                                                .background(theme.colors.border.opacity(0.2))
                                                .padding(.leading, theme.spacing.xl + theme.spacing.md)
                                        }
                                    }
                                }
                                .background(theme.colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))

                                if !selectedTopic.isNil || useCustomTopic {
                                    Text("\(selectedResourceIDs.count) resource\(selectedResourceIDs.count == 1 ? "" : "s") selected")
                                        .font(theme.typography.bodySmall)
                                        .foregroundColor(theme.colors.textSecondary)
                                        .padding(.top, 4)
                                }
                            }
                        }

                        FieldSection(title: "SESSION TIME") {
                            VStack(spacing: 0) {
                                timeRow(label: "Start", time: $startTime)
                                Divider()
                                    .background(theme.colors.background)
                                    .padding(.leading, theme.spacing.md)
                                timeRow(label: "End", time: $endTime)
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        VStack(spacing: 0) {
                            toggleRow(icon: "bell.fill", title: "Set Reminder", isOn: $hasReminder)
                        }
                        .background(theme.colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))

                        FieldSection(title: "NOTES") {
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add focus goals or prep notes…")
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.colors.textSecondary)
                                        .padding(theme.spacing.md)
                                }
                                TextEditor(text: $notes)
                                    .font(theme.typography.bodyMedium)
                                    .foregroundColor(theme.colors.textPrimary)
                                    .tint(theme.colors.primary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 90)
                                    .padding(.vertical, theme.spacing.sm)
                                    .padding(.horizontal, theme.spacing.sm)
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        if isEditing {
                            Button {
                                onDelete?()
                                dismiss()
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Remove Session", systemImage: "trash")
                                        .font(theme.typography.bodyMedium.weight(.semibold))
                                        .foregroundColor(theme.colors.error)
                                    Spacer()
                                }
                                .padding(theme.spacing.md)
                                .background(theme.colors.error.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xxl)
                }
            }
            .background(theme.colors.surface.opacity(0.2))
        }
        .onAppear { prefill() }
        .onChange(of: selectedSubject) { _, _ in
            selectedTopic = nil
            selectedResourceIDs = []
            reloadResources()
        }
        .onChange(of: selectedTopic) { topic in
            guard !useCustomTopic else { return }
            if let topic {
                selectedResourceIDs = Set(availableResources.prefix(topic.resourceCount).map(\.id))
            } else {
                selectedResourceIDs = []
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text(isEditing ? "Edit Session" : "Add Session")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Button("Save") { saveSession() }
                .font(theme.typography.bodyMedium.weight(.semibold))
                .foregroundColor(canSave ? theme.colors.primary : theme.colors.textSecondary)
                .disabled(!canSave)
        }
    }

    private func subjectChip(_ subject: Subject) -> some View {
        let isSelected = selectedSubject?.id == subject.id
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedSubject = isSelected ? nil : subject
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(subject.color)
                    .frame(width: 8, height: 8)
                Text(subject.name)
                    .font(theme.typography.bodySmall.weight(.semibold))
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
            .background(isSelected ? subject.color : theme.colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? subject.color : theme.colors.border.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func topicRow(_ topic: StudyTopic) -> some View {
        let isSelected = selectedTopic?.id == topic.id
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedTopic = isSelected ? nil : topic
            }
        } label: {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(isSelected ? theme.colors.primary : theme.colors.textSecondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(topic.name)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("\(topic.resourceCount) resources · Est. \(topic.estimatedHours) hrs")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
        }
        .buttonStyle(.plain)
    }

    private func resourceRow(_ resource: Resource) -> some View {
        let isSelected = selectedResourceIDs.contains(resource.id)
        return Button {
            if isSelected {
                selectedResourceIDs.remove(resource.id)
            } else {
                selectedResourceIDs.insert(resource.id)
            }
        } label: {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(isSelected ? theme.colors.primary : theme.colors.textSecondary)

                Image(systemName: resource.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(resource.type.color)
                    .frame(width: 28, height: 28)
                    .background(resource.type.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(resource.name)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    Text(resource.type.rawValue + (resource.size.isEmpty ? "" : " · \(resource.size)"))
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
        }
        .buttonStyle(.plain)
    }

    private func timeRow(label: String, time: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(theme.colors.primary)
        }
        .padding(theme.spacing.md)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: icon)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 32, height: 32)
                .background(theme.colors.onSurface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.sm))

            Text(title)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.colors.primary)
        }
        .padding(theme.spacing.md)
    }

    private func reloadResources() {
        availableResources = []
        selectedResourceIDs = []
        guard let subject = selectedSubject else { return }
        Task {
            let fetched = (try? await ResourceService.shared.fetchResources(subjectId: subject.id)) ?? []
            await MainActor.run {
                availableResources = fetched
                if !pendingResourceIDs.isEmpty {
                    selectedResourceIDs = pendingResourceIDs
                    pendingResourceIDs  = []
                }
            }
        }
    }

    private func prefill() {
        let slotDay = slot.date ?? scheduledDate ?? Date()
        startTime = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: slot.startTime),
            minute: Calendar.current.component(.minute, from: slot.startTime),
            second: 0, of: slotDay
        ) ?? slot.startTime
        endTime = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: slot.endTime),
            minute: Calendar.current.component(.minute, from: slot.endTime),
            second: 0, of: slotDay
        ) ?? slot.endTime

        guard let session = existingSession else { return }

        // Store IDs before setting subject — onChange will clear selectedResourceIDs,
        // but reloadResources() will restore from pendingResourceIDs once fetch completes.
        pendingResourceIDs = Set(session.resourceIds)
        selectedSubject    = availableSubjects.first { $0.id == session.subjectId }

        customTopic    = session.topic
        useCustomTopic = true
        startTime      = session.startTime
        endTime        = session.endTime
        hasReminder    = session.hasReminder
        notes          = session.notes ?? ""
    }

    private func saveSession() {
        guard let subject = selectedSubject else { return }
        let name = topicName.trimmingCharacters(in: .whitespaces)

        // Editing → preserve original day; adding new → use slot date or calendar selection
        let slotDay = existingSession?.scheduledDate ?? slot.date ?? scheduledDate ?? Date()
        let cal = Calendar.current
        let s = cal.date(
            bySettingHour: cal.component(.hour, from: startTime),
            minute: cal.component(.minute, from: startTime),
            second: 0, of: slotDay
        ) ?? startTime
        let e = cal.date(
            bySettingHour: cal.component(.hour, from: endTime),
            minute: cal.component(.minute, from: endTime),
            second: 0, of: slotDay
        ) ?? endTime

        let session = StudySession(
            id: existingSession?.id ?? UUID().uuidString,
            subjectId: subject.id,
            subjectName: subject.name,
            subjectColorHex: subject.colorHex,
            title: name,
            topic: name,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            scheduledDate: slotDay,
            startTime: s,
            endTime: e,
            hasReminder: hasReminder,
            resourceIds: Array(selectedResourceIDs)
        )
        onSave(session)
        dismiss()
    }
}

private extension Optional {
    var isNil: Bool { self == nil }
}

#Preview {
    let slot = AvailabilitySlot()
    return AddStudySessionSheet(slot: slot) { _ in }
        .environment(\.theme, AppTheme.defaultTheme)
}
