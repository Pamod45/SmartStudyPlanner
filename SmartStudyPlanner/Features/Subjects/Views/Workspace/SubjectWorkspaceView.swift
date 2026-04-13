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

    let subject: Subject
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
    @State private var studyPath: StudyPath? = nil
    @State private var showGeneratePath: Bool = false
    @State private var isRegeneratePath: Bool = false
    @State private var quizAttempts: [QuizAttempt] = []

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
                    onCardTap: { deadline in selectedDeadline = deadline }
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

                ScrollView(showsIndicators: false) {
                    tabContent
                        .padding(.horizontal, theme.spacing.sm)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddDeadline) {
            AddDeadlineSheet(subjectId: subject.id) { newDeadline in
                deadlines.append(newDeadline)
            }
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedDeadline) { deadline in
            AddDeadlineSheet(
                subjectId: subject.id,
                existingDeadline: deadline,
                onSave: { _ in },
                onUpdate: { updated in
                    if let index = deadlines.firstIndex(where: { $0.id == updated.id }) {
                        deadlines[index] = updated
                    }
                }
            )
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showAddResource) {
            AddResourceSheet { newResource in
                resources.append(newResource)
            }
            .environment(\.theme, theme)
        }
        .sheet(item: $selectedNote) { note in
            AddNoteView(existingResource: note) { updatedResource in
                if let index = resources.firstIndex(where: { $0.id == updatedResource.id }) {
                    resources[index] = updatedResource
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
        .sheet(isPresented: $showGeneratePath) {
            GenerateStudyPathSheet(
                subject: subject,
                resources: resources,
                isRegenerate: isRegeneratePath
            ) { newPath in
                studyPath = newPath
            }
            .environment(\.theme, theme)
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

            Color.clear.frame(width: 36, height: 36)
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
            Text(selectedTab == .resources ? "Your Resources" : selectedTab.rawValue)
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
                        selectedPDF = resource
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
            AIAssistantTabView()
        }
    }
}
#Preview {
    SubjectWorkspaceView(subject: Subject(name: "iOS Development", colorHex: "#3B82F6"))
        .environment(\.theme, AppTheme.defaultTheme)
}
