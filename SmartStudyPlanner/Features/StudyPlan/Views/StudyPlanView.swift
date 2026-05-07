import SwiftUI

struct StudyPlanView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject private var sessionVM: SessionViewModel
    @StateObject private var vm = StudyPlanViewModel()
    @State private var selectedDate: DateComponents? = nil
    @State private var showManageAvailability: Bool = false
    @State private var showCreateStudyPlan: Bool = false
    @State private var selectedDeadline: Deadline? = nil
    @State private var sessionSheetSlot: AvailabilitySlot? = nil
    @State private var sessionSheetDate: Date? = nil
    @State private var editingSession: (slot: AvailabilitySlot, session: StudySession)? = nil

    var slotsForSelectedDate: [AvailabilitySlot] {
        guard let selected = selectedDate,
              let date = Calendar.current.date(from: selected) else { return [] }
        return vm.slotsForDate(date)
    }

    var sessionsForSelectedDate: [StudySession] {
        guard let selected = selectedDate,
              let date = Calendar.current.date(from: selected) else { return [] }
        return vm.sessionsForDate(date)
    }

    var deadlinesForSelectedDate: [Deadline] {
        guard let selected = selectedDate,
              let date = Calendar.current.date(from: selected) else { return [] }
        return vm.deadlinesForDate(date)
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.lg) {
                        CalendarView(
                            selectedDate: $selectedDate,
                            slots: vm.availabilitySlots,
                            sessions: vm.studySessions,
                            deadlines: vm.deadlines
                        )
                        .background(theme.colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                        .padding(.horizontal, theme.spacing.lg)

                        if !slotsForSelectedDate.isEmpty || !deadlinesForSelectedDate.isEmpty {
                            selectedDaySection
                                .padding(.horizontal, theme.spacing.lg)
                        } else if selectedDate != nil {
                            emptySlotSection
                                .padding(.horizontal, theme.spacing.lg)
                        }
                    }
                    .padding(.bottom, theme.spacing.xxl)
                }
            }
        }
        .sheet(isPresented: $showManageAvailability) {
            ManageAvailabilitySheet { newSlot in
                vm.addAvailabilitySlot(newSlot)
            }
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showCreateStudyPlan) {
            CreateStudyPlanSheet(
                availabilitySlots: vm.availabilitySlots,
                subjects:          vm.subjects,
                studyPathTopics:   vm.studyPathTopics,
                onPlanCreated: { sessions in
                    vm.addSessions(sessions)
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedDeadline) { deadline in
            AddDeadlineSheet(
                subjectId: deadline.subjectId,
                userId: deadline.userId,
                existingDeadline: deadline,
                onSave: { _ in },
                onUpdate: { _ in }
            )
            .environment(\.theme, theme)
        }
        .sheet(item: $sessionSheetSlot) { slot in
            AddStudySessionSheet(
                slot: slot,
                scheduledDate: sessionSheetDate,
                onSave: { newSession in vm.addSession(newSession) },
                availableSubjects: vm.subjects
            )
            .environment(\.theme, theme)
        }
        .sheet(item: Binding(
            get: { editingSession.map { EditSessionID(slot: $0.slot, session: $0.session) } },
            set: { val in editingSession = val.map { (slot: $0.slot, session: $0.session) } }
        )) { item in
            AddStudySessionSheet(
                slot: item.slot,
                existingSession: item.session,
                onSave: { updated in vm.updateSession(updated) },
                onDelete: { vm.removeSession(id: item.session.id) },
                availableSubjects: vm.subjects
            )
            .environment(\.theme, theme)
        }
        .onAppear {
            selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            Task { await vm.load(userId: sessionVM.currentUser?.id) }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Study Plan")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            HStack(spacing: theme.spacing.md) {
                TextButton(title: "Add Time", icon: "plus", style: .bold) {
                    showManageAvailability = true
                }

                TextButton(title: "Create Plan", icon: "sparkles", style: .bold) {
                    showCreateStudyPlan = true
                }

                if !vm.studySessions.isEmpty {
                    Button {
                        vm.syncAllToCalendar()
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.primary)
                    }
                }
            }
        }
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {

            if !slotsForSelectedDate.isEmpty {
                Text("Available Slots")
                    .font(theme.typography.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                ForEach(slotsForSelectedDate) { slot in
                    slotCard(slot)
                }
            }

            if !deadlinesForSelectedDate.isEmpty {
                Text("Deadlines")
                    .font(theme.typography.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(.top, slotsForSelectedDate.isEmpty ? 0 : theme.spacing.sm)

                ForEach(deadlinesForSelectedDate) { deadline in
                    deadlineCard(deadline)
                }
            }
        }
    }

    private func sessions(for slot: AvailabilitySlot) -> [StudySession] {
        // Resolve which calendar day to filter on
        let slotDate: Date
        switch slot.type {
        case .specificDate:
            guard let d = slot.date else { return [] }
            slotDate = d
        case .dateRange:
            guard let selected = selectedDate,
                  let d = Calendar.current.date(from: selected) else { return [] }
            slotDate = d
        }

        let cal = Calendar.current
        let slotStartMins = cal.component(.hour, from: slot.startTime) * 60
                          + cal.component(.minute, from: slot.startTime)
        let slotEndMins   = cal.component(.hour, from: slot.endTime) * 60
                          + cal.component(.minute, from: slot.endTime)

        return vm.studySessions.filter { session in
            let sessionStartMins = cal.component(.hour,   from: session.startTime) * 60
                                 + cal.component(.minute, from: session.startTime)
            let sessionEndMins = cal.component(.hour, from: session.endTime) * 60
                               + cal.component(.minute, from: session.endTime)
            return cal.isDate(session.startTime, inSameDayAs: slotDate)
                && sessionStartMins >= slotStartMins
                && sessionEndMins <= slotEndMins
                && session.endTime > session.startTime
        }
    }

    private func slotCard(_ slot: AvailabilitySlot) -> some View {
        let slotSessions = sessions(for: slot)

        return VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.colors.primary)
                    .frame(width: 4, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(slot.formattedTimeRange)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(verbatim: slot.type.rawValue)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                if !slotSessions.isEmpty {
                    Text("\(slotSessions.count) session\(slotSessions.count > 1 ? "s" : "")")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.colors.primary.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        vm.removeAvailabilitySlot(id: slot.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.error)
                }
            }
            .padding(theme.spacing.md)

            if !slotSessions.isEmpty {
                Divider()
                    .background(theme.colors.border.opacity(0.3))
                    .padding(.horizontal, theme.spacing.md)

                VStack(spacing: theme.spacing.sm) {
                    ForEach(slotSessions) { session in
                        inlineSessionCard(session, slot: slot)
                    }
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.top, theme.spacing.sm)
            }

            Divider()
                .background(theme.colors.border.opacity(0.2))
                .padding(.horizontal, theme.spacing.md)

            Button {
                sessionSheetSlot = slot
                sessionSheetDate = selectedDate.flatMap { Calendar.current.date(from: $0) }
            } label: {
                HStack(spacing: theme.spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.primary)
                    Text("Add Session")
                        .font(theme.typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.primary)
                    Spacer()
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }

    private func inlineSessionCard(_ session: StudySession, slot: AvailabilitySlot) -> some View {
        Button {
            editingSession = (slot: slot, session: session)
        } label: {
            HStack(spacing: theme.spacing.md) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(session.subjectColor)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.subjectName)
                        .font(theme.typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(session.subjectColor)

                    Text(session.topic.isEmpty ? session.title : session.topic)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.textSecondary)
                        Text(session.timeRange)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                Text(session.duration)
                    .font(theme.typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(session.subjectColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(session.subjectColor.opacity(0.12))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.colors.textSecondary.opacity(0.6))
            }
            .padding(theme.spacing.sm)
            .background(session.subjectColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md)
                    .stroke(session.subjectColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func deadlineCard(_ deadline: Deadline) -> some View {
        Button {
            selectedDeadline = deadline
        } label: {
            HStack(spacing: theme.spacing.md) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.red)
                    .frame(width: 4, height: 44)

                Image(systemName: deadline.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(deadline.name)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(deadline.tag.rawValue)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(.red.opacity(0.8))
                }

                Spacer()

                if deadline.isHighPriority {
                    Text("High Priority")
                        .font(theme.typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var slotListSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Available Slots")
                .font(theme.typography.headingSmall)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            ForEach(slotsForSelectedDate) { slot in
                slotCard(slot)
            }
        }
    }

    private var emptySlotSection: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 32))
                .foregroundColor(theme.colors.textSecondary)
            Text("No available slots for this day")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, theme.spacing.xl)
    }
}

private struct EditSessionID: Identifiable {
    let id: String
    let slot: AvailabilitySlot
    let session: StudySession
    init(slot: AvailabilitySlot, session: StudySession) {
        self.id = session.id
        self.slot = slot
        self.session = session
    }
}

#Preview {
    StudyPlanView()
        .environment(\.theme, AppTheme.defaultTheme)
}
