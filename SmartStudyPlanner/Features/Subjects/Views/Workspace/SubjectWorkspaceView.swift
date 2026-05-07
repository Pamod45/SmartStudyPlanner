//
//  SubjectWorkspaceView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//


import SwiftUI

enum WorkspaceTab: String, CaseIterable {
    case resources   = "Resources"
    case studyPath   = "Study Path"
    case quizzes     = "Quizzes"
    case aiAssistant = "AI Assistant"
}

struct SubjectWorkspaceView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    @State var subject: Subject
    var subjectsVM: SubjectsViewModel? = nil

    @State private var selectedTab: WorkspaceTab = .resources
    @State private var deadlines: [Deadline] = []
    @State private var resources: [Resource] = []
    @State private var isDeadlinesExpanded: Bool = false
    @State private var showAddDeadline: Bool = false
    @State private var selectedDeadline: Deadline? = nil
    @State private var showAddResource: Bool = false
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var selectedNote: Resource? = nil
    @State private var selectedLink: Resource? = nil
    @State private var selectedPDF: Resource? = nil
    @State private var viewingPDF: Resource? = nil
    @State private var viewingRecording: Resource? = nil
    @State private var studyPath: StudyPath? = nil
    @State private var showGeneratePath: Bool = false
    @State private var isRegeneratePath: Bool = false
    @State private var quizAttempts: [QuizAttempt] = []
    
    @State private var isGeneratingAIPath: Bool = false
    @State private var generationProgressText: String = "Analyzing resources..."
    @State private var showEditSubject: Bool = false

    private var filteredResources: [Resource] {
        if searchText.isEmpty { return resources }
        return resources.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)

                DeadlineSection(
                    deadlines: $deadlines,
                    isExpanded: $isDeadlinesExpanded,
                    onAdd: { showAddDeadline = true },
                    onCardTap: { deadline in selectedDeadline = deadline },
                    onDelete: { deadline in deleteDeadline(deadline) }
                )
                .padding(.horizontal, theme.spacing.sm)
                .padding(.bottom, theme.spacing.md)

                workspaceTabPicker
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.md)

                tabContentHeader
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.lg)

                if isSearching && selectedTab == .resources {
                    
                    SearchBar(text: $searchText, placeholder: "Search subjects")
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.bottom, theme.spacing.md)
                    
                }

                if selectedTab == .aiAssistant {
                    tabContent
                        .padding(.horizontal, theme.spacing.sm)
                } else {
                    ScrollView(showsIndicators: false) {
                        tabContent
                            .padding(.horizontal, theme.spacing.sm)
                    }
                }
            }
            
            if isGeneratingAIPath {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: theme.spacing.lg) {
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.primary))
                            .controlSize(.large)
                        
                        Text(generationProgressText)
                            .font(theme.typography.bodyMedium.weight(.semibold))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    .padding(theme.spacing.xl)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                    .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: isGeneratingAIPath)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddDeadline) {
            AddDeadlineSheet(subjectId: subject.id, userId: subject.userId) { newDeadline in
                var deadline = newDeadline
                deadline.subjectColorHex = subject.colorHex
                deadlines.append(deadline)
                Task {
                    do {
                        try await DeadlineService.shared.createDeadline(deadline)
                    } catch {
                        print("Failed to save deadline: \(error)")
                    }
                }
            }
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showEditSubject) {
            AddSubjectSheet(
                editingSubject: subject,
                onSave: { _ in },
                onUpdate: { updated in
                    subject = updated
                    subjectsVM?.updateSubject(updated)
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedDeadline) { deadline in
            AddDeadlineSheet(
                subjectId: subject.id,
                userId: subject.userId,
                existingDeadline: deadline,
                onSave: { _ in },
                onUpdate: { updated in
                    if let index = deadlines.firstIndex(where: { $0.id == updated.id }) {
                        deadlines[index] = updated
                    }
                    Task {
                        do {
                            try await DeadlineService.shared.updateDeadline(updated)
                        } catch {
                            print("Failed to update deadline: \(error)")
                        }
                    }
                },
                onDelete: { deadlineToDelete in
                    deleteDeadline(deadlineToDelete)
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showAddResource) {
            AddResourceSheet { newResource in
                var resource = newResource
                resource.subjectId = subject.id
                resource.userId = subject.userId
                resources.append(resource)
                subjectsVM?.setResourceCount(resources.count, for: subject.id, resourceIds: resources.map(\.id))
                
                Task {
                    do {
                        try await ResourceService.shared.createResource(resource)
                        let fetchedResources = try await ResourceService.shared.fetchResources(subjectId: subject.id)
                        await MainActor.run {
                            resources = fetchedResources
                            subjectsVM?.setResourceCount(fetchedResources.count, for: subject.id, resourceIds: fetchedResources.map(\.id))
                        }
                    } catch {
                        print("Failed to save resource: \(error)")
                    }
                }
            }
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedNote) { note in
            AddNoteView(existingResource: note) { updatedResource in
                if let index = resources.firstIndex(where: { $0.id == updatedResource.id }) {
                    resources[index] = updatedResource
                    
                    Task {
                        do {
                            try await ResourceService.shared.updateResource(updatedResource)
                        } catch {
                            print("Failed to update resource: \(error)")
                        }
                    }
                }
            }
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedLink) { link in
            AddLinkSheet(
                existingResource: link,
                onSave: { _ in },
                onUpdate: { updated in
                    if let index = resources.firstIndex(where: { $0.id == updated.id }) {
                        resources[index] = updated
                        Task {
                            do {
                                try await ResourceService.shared.updateResource(updated)
                            } catch {
                                print("Failed to update resource: \(error)")
                            }
                        }
                    }
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedPDF) { pdf in
            AddPDFSheet(
                existingResource: pdf,
                onSave: { _ in },
                onUpdate: { updated in
                    if let index = resources.firstIndex(where: { $0.id == updated.id }) {
                        resources[index] = updated
                    }
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(item: $viewingPDF) { pdf in
            PDFViewerSheet(resource: pdf)
                .environment(\.theme, theme)
        }
        .sheet(item: $viewingRecording) { recording in
            RecordingPlayerView(resource: recording)
                .environment(\.theme, theme)
        }
        .sheet(isPresented: $showGeneratePath) {
            GenerateStudyPathSheet(
                subject: subject,
                resources: resources,
                isRegenerate: isRegeneratePath
            ) { newPath in
                generateStudyPath(with: newPath)
            }
            .environment(\.theme, theme)
        }
        .onAppear {
            loadResources()
            loadStudyPath()
            loadDeadlines()
        }
    }
    
    private func loadStudyPath() {
        let cachedTopics = CoreDataService.shared.getCachedStudyPath(for: subject.id)
        if !cachedTopics.isEmpty {
            self.studyPath = StudyPath(subjectId: subject.id, topics: cachedTopics)
        }
        
        Task {
            do {
                let topics = try await StudyPathService.shared.fetchStudyPath(for: subject.id)
                await MainActor.run {
                    self.studyPath = StudyPath(subjectId: subject.id, topics: topics)
                }
            } catch {
                print("Failed to fetch study path: \(error)")
            }
        }
    }

    private func loadDeadlines() {
        deadlines = CoreDataService.shared.getCachedDeadlines(for: subject.id)
        Task {
            do {
                let fetched = try await DeadlineService.shared.fetchDeadlines(subjectId: subject.id)
                await MainActor.run { deadlines = fetched }
            } catch {
                print("Failed to fetch deadlines: \(error)")
            }
        }
    }

    private func deleteDeadline(_ deadline: Deadline) {
        deadlines.removeAll { $0.id == deadline.id }
        Task {
            do {
                try await DeadlineService.shared.deleteDeadline(id: deadline.id, subjectId: subject.id)
            } catch {
                print("Failed to delete deadline: \(error)")
            }
        }
    }

    private func loadResources() {
        resources = CoreDataService.shared.getCachedResources(for: subject.id)
        
        Task {
            do {
                let fetchedResources = try await ResourceService.shared.fetchResources(subjectId: subject.id)
                await MainActor.run {
                    resources = fetchedResources
                    subjectsVM?.setResourceCount(fetchedResources.count, for: subject.id, resourceIds: fetchedResources.map(\.id))
                }
            } catch {
                print("Failed to fetch resources: \(error)")
            }
        }
    }
    
    private func generateStudyPath(with basePath: StudyPath) {
        isGeneratingAIPath = true
        generationProgressText = "Extracting text from resources..."
        
        let selectedResources = resources.filter { basePath.generatedFromResourceIds.contains($0.id) }
        print("DEBUG: generateStudyPath called with \(selectedResources.count) resources")
        
        Task {
            do {
                print("DEBUG: Starting text extraction...")
                let combinedText = try await ContentExtractionService.shared.extractText(from: selectedResources)
                print("DEBUG: Text extraction complete. Extracted \(combinedText.count) characters.")
                
                await MainActor.run {
                    generationProgressText = "Generating AI Study Path..."
                }
                
                print("DEBUG: Starting LLM generation...")
                let topics = try await StudyContentOrchestrator.shared.buildStudyPath(from: combinedText)

                await MainActor.run {
                    var finalPath = basePath
                    finalPath.topics = topics
                    self.studyPath = finalPath
                    self.isGeneratingAIPath = false
                    
                    Task {
                        do {
                            try await StudyPathService.shared.saveStudyPath(topics, for: subject.id)
                            print("✅ Study path saved")
                            // Refresh subject counts in the list
                            await MainActor.run {
                                subjectsVM?.refreshSubjectCounts(for: subject.id)
                            }
                        } catch {
                            print("❌ Failed to save study path: \(error)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    print("Failed to generate AI path: \(error)")
                    self.isGeneratingAIPath = false
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }

            Spacer()

            Text(subject.name)
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Button { showEditSubject = true } label: {
                Image(systemName: "pencil")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }
        }
    }

    private var workspaceTabPicker: some View {
        HStack() {
            ForEach(WorkspaceTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: theme.spacing.sm) {
                        Text(tab.rawValue)
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedTab == tab ? theme.colors.primary : theme.colors.textSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? theme.colors.primary : Color.clear)
                            .frame(height: 2)
                            .padding(.horizontal, theme.spacing.md)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var tabContentHeader: some View {
        HStack {
            Text(selectedTab == .resources ? "Your Resources (\(resources.count))" : selectedTab.rawValue)
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()
            
            if selectedTab == .resources {
                HStack(spacing: theme.spacing.md) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            isSearching.toggle()
                            if !isSearching { searchText = "" }
                        }
                    } label: {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    TextButton(title: "Add", icon: "plus", style: .bold, action: { showAddResource = true })
                }
            }
                
            
            
        }
        .padding(.top, theme.spacing.md)
    }


    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .resources:
            ResourcesTabView(
                resources: $resources,
                filteredResources: filteredResources,
                onOpenNote: { resource in
                    if resource.type == .note {
                        selectedNote = resource
                    } else if resource.type == .link {
                        selectedLink = resource
                    } else if resource.type == .pdf {
                        viewingPDF = resource
                    } else if resource.type == .recording {
                        viewingRecording = resource
                    }
                },
                onEditResource: { resource in
                    if resource.type == .pdf {
                        selectedPDF = resource
                    } else if resource.type == .link {
                        selectedLink = resource
                    }
                },
                onRenameResource: { resource, newName in
                    if let index = resources.firstIndex(where: { $0.id == resource.id }) {
                        var updatedResource = resources[index]
                        updatedResource.name = newName
                        updatedResource.updatedAt = Date()
                        resources[index] = updatedResource
                        
                        Task {
                            do {
                                try await ResourceService.shared.updateResource(updatedResource)
                            } catch {
                                print("Failed to rename resource: \(error)")
                            }
                        }
                    }
                }
            )
        case .studyPath:
            StudyPathTabView(
                subject: subject,
                resources: resources,
                studyPath: $studyPath,
                onRegenerate: {
                    isRegeneratePath = true
                    showGeneratePath = true
                },
                onGenerate: {
                    isRegeneratePath = false
                    showGeneratePath = true
                }
            )
        case .quizzes:
            QuizzesTabView(
                subject: subject,
                studyPath: studyPath,
                resources: resources,
                attempts: $quizAttempts
            )
        case .aiAssistant:
            AIAssistantTabView(
                subject: subject,
                resources: resources,
                studyPath: studyPath
            )
        }
    }
}
#Preview {
    SubjectWorkspaceView(subject: Subject(name: "iOS Development", colorHex: "#3B82F6"))
        .environment(\.theme, AppTheme.defaultTheme)
}
