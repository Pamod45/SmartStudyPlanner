import SwiftUI

struct DashboardView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var sessionVM: SessionViewModel
    @StateObject private var vm = DashboardViewModel()

    @State private var editingDeadline: Deadline? = nil
    @State private var pendingAction: ResourceAction? = nil
    @State private var showSubjectPicker = false
    @State private var pickerSelectedSubject: Subject? = nil
    @State private var shortcutFlow: ShortcutFlow? = nil

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
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(item: $shortcutFlow) { flow in
            resourceSheet(for: flow.action, subject: flow.subject)
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
                    .environment(\.theme, theme)
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(theme.colors.primary)
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

            if vm.upcomingSessions.isEmpty {
                Text("No sessions in the next 7 days")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, theme.spacing.sm)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.md) {
                        ForEach(vm.upcomingSessions) { session in
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
                                onStop: { elapsedSeconds in
                                    Task {
                                        var updated = session
                                        updated.status = .completed
                                        updated.actualDurationMinutes = max(1, elapsedSeconds / 60)
                                        updated.updatedAt = Date()
                                        try? await StudySessionService.shared.update(updated)
                                        vm.upcomingSessions.removeAll { $0.id == session.id }
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

            if vm.upcomingDeadlines.isEmpty {
                Text("No upcoming deadlines")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, theme.spacing.sm)
            } else {
                VStack(spacing: theme.spacing.md) {
                    ForEach(vm.upcomingDeadlines) { deadline in
                        DeadlineCard(deadline: deadline, action: {
                            editingDeadline = deadline
                        })
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

    // MARK: - Resource sheet dispatcher

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
