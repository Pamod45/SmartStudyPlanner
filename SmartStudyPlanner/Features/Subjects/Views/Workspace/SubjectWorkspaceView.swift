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

    @State private var selectedTab: WorkspaceTab = .resources
    @State private var deadlines: [Deadline]
    @State private var resources: [Resource]
    @State private var isDeadlinesExpanded: Bool = false
    @State private var showAddDeadline: Bool = false

    init(subject: Subject) {
        self.subject = subject
        _deadlines = State(initialValue: Deadline.samples(for: subject.id, color: subject.color))
        _resources = State(initialValue: Resource.samples(for: subject.id))
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        DeadlineSection(
                            deadlines: $deadlines,
                            isExpanded: $isDeadlinesExpanded,
                            onAdd: { showAddDeadline = true }
                        )
                        .padding(.bottom, theme.spacing.md)

                        workspaceTabPicker
                            
                            .padding(.bottom, theme.spacing.md)

                        tabContentHeader
                            .padding(.bottom, theme.spacing.md)

                        tabContent
                    }.padding(.horizontal, theme.spacing.sm)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddDeadline) {
            AddDeadlineSheet(subjectID: subject.id) { newDeadline in
                deadlines.append(newDeadline)
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
                HStack(spacing: theme.spacing.md){
//                    Button {
//                    } label: {
//                        Image(systemName: "magnifyingglass")
//                            .font(.system(size: 12, weight: .semibold))
//                            .foregroundColor(theme.colors.textPrimary)
//                        
//                    }

                    TextButton(title: "Add", icon: "plus" , style: .bold, action: {} )
                }
//                HStack{
//                    Button { dismiss() } label: {
//                        Image(systemName: "magnifyingglass")
//                            .fontWeight(.semibold)
//                            .foregroundColor(theme.colors.textSecondary)
//                            .frame(width: 36, height: 36)
//                    }
//                    Button { dismiss() } label: {
//                        Image(systemName: "plus")
//                            .fontWeight(.semibold)
//                            .foregroundColor(theme.colors.textSecondary)
//                            .frame(width: 36, height: 36)                    }
//                }.glassEffect(.regular, in: Capsule())
//                .overlay(
//                    Capsule()
//                        .stroke(theme.colors.textSecondary.opacity(0.1), lineWidth: 0.5)
//                )
//                .font(theme.typography.bodyMedium)
                
            }
                
            
            
        }
        .padding(.top, theme.spacing.md)
    }
    


    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .resources:
            ResourcesTabView(resources: $resources)
        case .studyPath:
            StudyPathTabView()
        case .quizzes:
            QuizzesTabView()
        case .aiAssistant:
            AIAssistantTabView()
        }
    }
}

#Preview {
    SubjectWorkspaceView(subject: Subject.samples.first!)
        .environment(\.theme, AppTheme.defaultTheme)
}
