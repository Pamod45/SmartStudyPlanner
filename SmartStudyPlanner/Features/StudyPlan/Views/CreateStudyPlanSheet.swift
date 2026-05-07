import SwiftUI

struct CreateStudyPlanSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var availabilitySlots: [AvailabilitySlot] = []
    var subjects: [Subject] = []
    var studyPathTopics: [String: [StudyPathTopic]] = [:]
    var onPlanCreated: (([StudySession]) -> Void)? = nil

    @State private var startDate: Date = .now
    @State private var endDate: Date   = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var expandedSubjectID: String? = nil
    @State private var selectedSubjectIDs: Set<String> = []
    @State private var selectedTopicIDs: Set<String> = []
    @State private var isScheduling: Bool = false
    @State private var showValidationAlert: Bool = false
    @State private var validationTitle: String = ""
    @State private var validationMessage: String = ""

    private var hasSelection: Bool { !selectedSubjectIDs.isEmpty }
    private var todayStart: Date { Calendar.current.startOfDay(for: .now) }

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
                                dateRow(label: "Start Date", date: $startDate, range: todayStart...)
                                Divider()
                                    .background(theme.colors.background)
                                    .padding(.leading, theme.spacing.md)
                                dateRow(label: "End Date", date: $endDate, range: Calendar.current.startOfDay(for: max(todayStart, startDate))...)
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        FieldSection(title: "SUBJECTS & TOPICS") {
                            if subjects.isEmpty {
                                emptySubjectsView
                            } else {
                                VStack(spacing: theme.spacing.md) {
                                    ForEach(subjects) { subject in
                                        subjectRow(subject)
                                    }
                                }
                            }
                        }

                        if availabilitySlots.isEmpty {
                            noSlotsWarning
                        }
                    }
                    .padding(theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xxl)
                }
            }
            .background(theme.colors.surface.opacity(0.2))

            if isScheduling {
                schedulingOverlay
            }
        }
        .onChange(of: startDate) { _, newValue in
            if endDate < newValue {
                endDate = newValue
            }
        }
        .alert(validationTitle, isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }

    private var headerSection: some View {
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

            Text("Create Study Plan")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Button("Create") { createPlan() }
                .font(theme.typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(hasSelection ? theme.colors.primary : theme.colors.textSecondary)
                .disabled(!hasSelection || isScheduling)
        }
    }

    private func dateRow(label: String, date: Binding<Date>, range: PartialRangeFrom<Date>) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            DatePicker("", selection: date, in: range, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(theme.colors.primary)
        }
        .padding(theme.spacing.md)
    }

    private func topics(for subject: Subject) -> [StudyPathTopic] {
        (studyPathTopics[subject.id] ?? []).sorted { $0.order < $1.order }
    }

    private func topicKey(_ topic: StudyPathTopic, subject: Subject) -> String {
        "\(subject.id)-\(topic.id)"
    }

    private func allTopicsDeselected(for subject: Subject) -> Bool {
        topics(for: subject).allSatisfy { !selectedTopicIDs.contains(topicKey($0, subject: subject)) }
    }

    private func subjectRow(_ subject: Subject) -> some View {
        let isSelected = selectedSubjectIDs.contains(subject.id)
        let isExpanded = expandedSubjectID == subject.id
        let subjectTopics = topics(for: subject)
        let totalMins = subjectTopics.reduce(0) { $0 + $1.estimatedMinutes }

        return VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        if isSelected {
                            selectedSubjectIDs.remove(subject.id)
                            subjectTopics.forEach { selectedTopicIDs.remove(topicKey($0, subject: subject)) }
                        } else {
                            selectedSubjectIDs.insert(subject.id)
                            subjectTopics.forEach { selectedTopicIDs.insert(topicKey($0, subject: subject)) }
                        }
                    }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(isSelected ? theme.colors.primary : theme.colors.textSecondary)
                }
                .buttonStyle(.plain)

                Circle()
                    .fill(subject.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 3) {
                    Text(subject.name)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    if subjectTopics.isEmpty {
                        Text("No study path yet")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    } else {
                        Text("\(subjectTopics.count) topics · ~\(totalMins / 60)h \(totalMins % 60)m")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                if !subjectTopics.isEmpty {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            expandedSubjectID = isExpanded ? nil : subject.id
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(theme.colors.border.opacity(0.5), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(theme.spacing.md)

            if isExpanded && !subjectTopics.isEmpty {
                VStack(spacing: 0) {
                    ForEach(subjectTopics) { topic in
                        topicRow(topic, subject: subject)
                        if topic.id != subjectTopics.last?.id {
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

    private func topicRow(_ topic: StudyPathTopic, subject: Subject) -> some View {
        let key        = topicKey(topic, subject: subject)
        let isSelected = selectedTopicIDs.contains(key)
        let hrs        = topic.estimatedMinutes / 60
        let mins       = topic.estimatedMinutes % 60

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                if isSelected {
                    selectedTopicIDs.remove(key)
                    if allTopicsDeselected(for: subject) {
                        selectedSubjectIDs.remove(subject.id)
                    }
                } else {
                    selectedTopicIDs.insert(key)
                    selectedSubjectIDs.insert(subject.id)
                }
            }
        } label: {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(isSelected ? theme.colors.primary : theme.colors.textSecondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(topic.title)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    HStack(spacing: 6) {
                        if hrs > 0 {
                            Text("~\(hrs)h \(mins)m")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textSecondary)
                        } else {
                            Text("~\(mins)m")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        difficultyBadge(topic.difficultyLevel)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
        }
        .buttonStyle(.plain)
    }

    private func difficultyBadge(_ level: Int) -> some View {
        let color: Color = level <= 3 ? theme.colors.success :
                           level <= 6 ? .orange : theme.colors.error
        return Text("Lvl \(level)")
            .font(theme.typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var emptySubjectsView: some View {
        HStack {
            Spacer()
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "book.closed")
                    .font(.system(size: 28))
                    .foregroundColor(theme.colors.textSecondary)
                Text("No subjects yet")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                Text("Add subjects and generate a Study Path first.")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.vertical, theme.spacing.xl)
    }

    private var noSlotsWarning: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("No availability slots added yet. Add your free time first so the scheduler can place sessions.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }

    private var schedulingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: theme.spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.primary))
                    .scaleEffect(1.4)
                Text("Building your schedule…")
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(theme.spacing.xl)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isScheduling)
    }

    // MARK: - Plan creation

    private func createPlan() {
        let entries = buildEntries()
        let period = selectedPeriod()
        let slots   = availabilitySlots
        let requiredMinutes = entries.flatMap(\.topics).reduce(0) { total, topic in
            total + (topic.estimatedMinutes > 0 ? topic.estimatedMinutes : max(30, topic.weightPercent * 6))
        }

        guard !entries.isEmpty else {
            showValidation(
                title: "Select Topics",
                message: "Select at least one topic before creating a study plan."
            )
            return
        }

        let availableSlots = slots.filter { slotApplies($0, during: period) }
        guard !availableSlots.isEmpty else {
            showValidation(
                title: "No Availability",
                message: "There are no available study times in the selected date range. Add availability first, then create the plan."
            )
            return
        }

        isScheduling = true
        let sessions = StudyScheduleService.shared.schedule(
            entries: entries,
            slots:   availableSlots,
            period:  period
        )
        let validSessions = sessions.filter { sessionFits($0, in: availableSlots) }
        let scheduledMinutes = validSessions.reduce(0) { $0 + max(0, $1.durationMinutes) }

        guard !validSessions.isEmpty else {
            isScheduling = false
            showValidation(
                title: "No Sessions Created",
                message: "The selected availability is too short to create a study session. Add a longer availability slot in this date range."
            )
            return
        }

        guard validSessions.count == sessions.count else {
            isScheduling = false
            showValidation(
                title: "Availability Mismatch",
                message: "Some generated sessions fell outside your available time slots. Add availability in the selected date range and try again."
            )
            return
        }

        guard scheduledMinutes >= requiredMinutes else {
            isScheduling = false
            showValidation(
                title: "Not Enough Availability",
                message: "Your selected topics need about \(formatMinutes(requiredMinutes)), but this date range can schedule only about \(formatMinutes(scheduledMinutes)). Remove some topics or add more availability to complete the plan."
            )
            return
        }

        Task {
            await MainActor.run {
                isScheduling = false
                onPlanCreated?(validSessions)
                dismiss()
            }
        }
    }

    private func buildEntries() -> [StudyScheduleService.SubjectEntry] {
        subjects.compactMap { subject in
            guard selectedSubjectIDs.contains(subject.id) else { return nil }
            let selected = topics(for: subject).filter { selectedTopicIDs.contains(topicKey($0, subject: subject)) }
            guard !selected.isEmpty else { return nil }
            return StudyScheduleService.SubjectEntry(
                subject:         subject,
                topics:          selected,
                nearestDeadline: nil   
            )
        }
    }

    private func selectedPeriod() -> DateInterval {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let endStart = cal.startOfDay(for: endDate)
        let nextDay = cal.date(byAdding: .day, value: 1, to: endStart) ?? endStart
        let end = nextDay.addingTimeInterval(-1)
        return DateInterval(start: start, end: end)
    }

    private func slotApplies(_ slot: AvailabilitySlot, during period: DateInterval) -> Bool {
        let cal = Calendar.current
        var current = cal.startOfDay(for: period.start)
        let last = cal.startOfDay(for: period.end)

        while current <= last {
            if slot.applies(on: current) {
                return true
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return false
    }

    private func sessionFits(_ session: StudySession, in slots: [AvailabilitySlot]) -> Bool {
        slots.contains { slot in
            sessionFits(session, in: slot)
        }
    }

    private func sessionFits(_ session: StudySession, in slot: AvailabilitySlot) -> Bool {
        let cal = Calendar.current

        guard slot.applies(on: session.scheduledDate) || slot.applies(on: session.startTime) else {
            return false
        }

        let slotStartMinutes = minutesSinceStartOfDay(slot.startTime, calendar: cal)
        let slotEndMinutes = minutesSinceStartOfDay(slot.endTime, calendar: cal)
        let sessionStartMinutes = minutesSinceStartOfDay(session.startTime, calendar: cal)
        let sessionEndMinutes = minutesSinceStartOfDay(session.endTime, calendar: cal)

        return sessionStartMinutes >= slotStartMinutes
            && sessionEndMinutes <= slotEndMinutes
            && session.endTime > session.startTime
    }

    private func minutesSinceStartOfDay(_ date: Date, calendar: Calendar) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    private func showValidation(title: String, message: String) {
        validationTitle = title
        validationMessage = message
        showValidationAlert = true
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
}

#Preview {
    CreateStudyPlanSheet()
        .environment(\.theme, AppTheme.defaultTheme)
}
