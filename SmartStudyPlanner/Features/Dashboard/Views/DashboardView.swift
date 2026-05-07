import SwiftUI

struct DashboardView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var sessionVM: SessionViewModel
    @EnvironmentObject var notificationStore: NotificationStore
    @StateObject private var vm = DashboardViewModel()

    @State private var editingDeadline: Deadline? = nil
    @State private var pendingAction: ResourceAction? = nil
    @State private var showSubjectPicker = false
    @State private var pickerSelectedSubject: Subject? = nil
    @State private var shortcutFlow: ShortcutFlow? = nil
    @State private var sessionToRate: StudySession? = nil

    private var visibleUpcomingSessions: [StudySession] {
        Array(vm.upcomingSessions.prefix(3))
    }

    private var visibleUpcomingDeadlines: [Deadline] {
        Array(vm.upcomingDeadlines.prefix(3))
    }

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)
                    .overlay(
                        Rectangle()
                            .fill(theme.colors.border.opacity(0.3))
                            .frame(height: 1),
                        alignment: .bottom
                    )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        studySessionsSection
                        upcomingDeadlinesSection
                        shortcutsSection
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.lg)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await vm.load(userId: sessionVM.activeUserId) }
        .sheet(isPresented: $showSubjectPicker, onDismiss: {
            if let subject = pickerSelectedSubject, let action = pendingAction {
                shortcutFlow = ShortcutFlow(action: action, subject: subject)
            }
            pickerSelectedSubject = nil
            pendingAction = nil
        }) {
            SubjectPickerSheet(subjects: vm.recentSubjects) { subject in
                pickerSelectedSubject = subject
            }
            .environment(\.theme, theme)
        }
        .sheet(item: $editingDeadline) { deadline in
            AddDeadlineSheet(
                subjectId: deadline.subjectId,
                userId: deadline.userId,
                existingDeadline: deadline,
                onSave: { _ in },
                onUpdate: { updated in
                    if let idx = vm.upcomingDeadlines.firstIndex(where: { $0.id == updated.id }) {
                        vm.upcomingDeadlines[idx] = updated
                    }
                    Task { try? await DeadlineService.shared.updateDeadline(updated) }
                },
                onDelete: { deleted in
                    vm.upcomingDeadlines.removeAll { $0.id == deleted.id }
                    Task {
                        try? await DeadlineService.shared.deleteDeadline(
                            id: deleted.id,
                            subjectId: deleted.subjectId
                        )
                    }
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(item: $shortcutFlow) { flow in
            resourceSheet(for: flow.action, subject: flow.subject)
                .environment(\.theme, theme)
        }
        .sheet(item: $sessionToRate) { session in
            SessionRatingSheet(session: session) { rating in
                guard let rating else { return }
                Task {
                    var updated = session
                    updated.rating = rating
                    updated.updatedAt = Date()
                    try? await StudySessionService.shared.update(updated)
                }
            }
            .environment(\.theme, theme)
        }
    }

    private var headerSection: some View {
        HStack {
            HStack(spacing: theme.spacing.md) {
                profileAvatar

                Text(greetingText)
                    .font(theme.typography.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Spacer()

            NavigationLink {
                NotificationListView()
                    .environmentObject(notificationStore)
                    .environment(\.theme, theme)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(theme.colors.primary)
                    if notificationStore.unreadCount > 0 {
                        Text("\(min(notificationStore.unreadCount, 99))")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .padding(.horizontal, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 10, y: -8)
                    }
                }
            }
        }
    }

    private var profileAvatar: some View {
        let user = sessionVM.currentUser
        let initial = user?.displayName
            .components(separatedBy: " ").first?.prefix(1).uppercased() ?? "?"

        let avatarImage: UIImage? = {
            guard let path = user?.profileImageURL, !path.isEmpty,
                  let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            else { return nil }
            let filename = (path as NSString).lastPathComponent
            let url = docs.appendingPathComponent(filename)
            return (try? Data(contentsOf: url)).flatMap { UIImage(data: $0) }
        }()

        return ZStack {
            Circle()
                .fill(theme.colors.surface)
                .overlay(Circle().stroke(theme.colors.border.opacity(0.4), lineWidth: 1))
            if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Text(initial)
                    .font(theme.typography.bodyLarge.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
        .frame(width: 44, height: 44)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let period: String
        switch hour {
        case 5..<12:  period = "Good morning"
        case 12..<17: period = "Good afternoon"
        case 17..<22: period = "Good evening"
        default:      period = "Good night"
        }
        let firstName = sessionVM.currentUser?.displayName
            .components(separatedBy: " ").first ?? "there"
        return "\(period), \(firstName)"
    }

    private var studySessionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Upcoming Study Sessions", actionTitle: "ACTIVE")

            if visibleUpcomingSessions.isEmpty {
                Text("No sessions in the next 7 days")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, theme.spacing.sm)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.md) {
                        ForEach(visibleUpcomingSessions) { session in
                            StudySessionCard(
                                session: session,
                                onStart: {
                                    StudyTimerService.shared.start(session: session)
                                    Task {
                                        var updated = session
                                        updated.status = .inProgress
                                        updated.updatedAt = Date()
                                        try? await StudySessionService.shared.update(updated)
                                        if let idx = vm.upcomingSessions.firstIndex(where: { $0.id == session.id }) {
                                            vm.upcomingSessions[idx] = updated
                                        }
                                    }
                                },
                                onResume: {
                                    let accumulated = (session.actualDurationMinutes ?? 0) * 60
                                    StudyTimerService.shared.resume(session: session, previousSeconds: accumulated)
                                },
                                onPause: {
                                    let totalSeconds = StudyTimerService.shared.pause()
                                    Task {
                                        var updated = session
                                        updated.actualDurationMinutes = max(1, totalSeconds / 60)
                                        updated.updatedAt = Date()
                                        try? await StudySessionService.shared.update(updated)
                                        if let idx = vm.upcomingSessions.firstIndex(where: { $0.id == session.id }) {
                                            vm.upcomingSessions[idx] = updated
                                        }
                                    }
                                },
                                onComplete: {
                                    let totalSeconds = StudyTimerService.shared.complete()
                                    Task {
                                        var updated = session
                                        updated.status = .completed
                                        updated.actualDurationMinutes = max(1, totalSeconds / 60)
                                        updated.updatedAt = Date()
                                        try? await StudySessionService.shared.update(updated)
                                        vm.upcomingSessions.removeAll { $0.id == session.id }
                                        sessionToRate = updated
                                        let settings = CoreDataService.shared.getCachedSettings(for: updated.userId) ?? .default
                                        NotificationService.shared.scheduleQuizReminder(for: updated, settings: settings)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var upcomingDeadlinesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Upcoming Deadlines", actionTitle: "View Calendar") {}

            if visibleUpcomingDeadlines.isEmpty {
                Text("No upcoming deadlines")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, theme.spacing.sm)
            } else {
                VStack(spacing: theme.spacing.md) {
                    ForEach(visibleUpcomingDeadlines) { deadline in
                        DeadlineCard(deadline: deadline, action: {
                            editingDeadline = deadline
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.upcomingDeadlines.removeAll { $0.id == deadline.id }
                                Task {
                                    try? await DeadlineService.shared.deleteDeadline(
                                        id: deadline.id,
                                        subjectId: deadline.subjectId
                                    )
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(title: "Smart Shortcuts")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: theme.spacing.md), GridItem(.flexible())],
                spacing: theme.spacing.md
            ) {
                ForEach(vm.shortcuts) { shortcut in
                    ShortcutCard(shortcut: shortcut) {
                        pendingAction = shortcut.resourceAction
                        showSubjectPicker = true
                    }
                }
            }
        }
    }


    @ViewBuilder
    private func resourceSheet(for action: ResourceAction, subject: Subject) -> some View {
        let save: (Resource) -> Void = { resource in
            var r = resource
            r.subjectId = subject.id
            r.userId = subject.userId
            Task { try? await ResourceService.shared.createResource(r) }
        }
        switch action {
        case .scanNotes:
            ScannerView(onSave: save).environment(\.theme, theme)
        case .liveRecording:
            LiveRecordingView(onSave: save).environment(\.theme, theme)
        case .newNote:
            AddNoteView(onSave: save).environment(\.theme, theme)
        case .addPDF:
            AddPDFSheet(onSave: save).environment(\.theme, theme)
        case .addLink:
            AddLinkSheet(onSave: save).environment(\.theme, theme)
        }
    }
}

private struct ShortcutFlow: Identifiable {
    let id = UUID()
    let action: ResourceAction
    let subject: Subject
}

private extension Shortcut {
    var resourceAction: ResourceAction {
        switch title {
        case "SCAN NOTES":     return .scanNotes
        case "IMPORT DOC":     return .addPDF
        case "RECORD LECTURES": return .liveRecording
        default:               return .newNote
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(SessionViewModel())
        .environment(\.theme, AppTheme.defaultTheme)
}
