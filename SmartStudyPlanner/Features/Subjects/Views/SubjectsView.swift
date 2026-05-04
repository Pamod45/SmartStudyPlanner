//
//  Subject.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-01.
//

import SwiftUI

struct SubjectsView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @StateObject private var vm = SubjectsViewModel()
    @State private var searchText: String = ""
    @State private var sortOption = 0
    @State private var isAscending: Bool = true
    @State private var showAddSubject: Bool = false
    @State private var selectedSubject: Subject?

    var filtered: [Subject] {
        var list = searchText.isEmpty ? vm.subjects : vm.subjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        if sortOption == 1 {
            list.sort { isAscending ? ($0.name < $1.name) : ($0.name > $1.name) }
        }
        return list
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

                SearchBar(text: $searchText, placeholder: "Search subjects")
                    .padding(.horizontal, theme.spacing.sm)

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: theme.spacing.md)

                if vm.subjects.isEmpty {
                    VStack(spacing: theme.spacing.md) {
                        Spacer()
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(theme.colors.textSecondary)
                        Text("No subjects yet")
                            .font(theme.typography.bodyLarge)
                            .foregroundColor(theme.colors.textSecondary)
                        Text("Tap + to add your first subject")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filtered) { subject in
                            SubjectCard(subject: subject) {
                                selectedSubject = subject
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: 0,
                                leading: theme.spacing.sm,
                                bottom: theme.spacing.md,
                                trailing: theme.spacing.sm
                            ))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    vm.deleteSubject(id: subject.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }.tint(Color.red)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .background(theme.colors.background)
                }
            }
        }
        .task(id: sessionViewModel.activeUserId) {
            await vm.load(userId: sessionViewModel.activeUserId)
        }
        .sheet(isPresented: $showAddSubject) {
            AddSubjectSheet { newSubject in
                vm.addSubject(newSubject, userId: sessionViewModel.activeUserId)
            }
            .environment(\.theme, theme)
        }
        .navigationDestination(item: $selectedSubject) { subject in
            SubjectWorkspaceView(subject: subject, subjectsVM: vm)
                .environment(\.theme, theme)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Subjects")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Spacer()

            Button { showAddSubject = true } label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }

            Menu {
                Button { sortOption = 0 } label: {
                    Label("Date Created", systemImage: sortOption == 0 ? "checkmark" : "")
                }
                Button { sortOption = 1 } label: {
                    Label("Alphabetical", systemImage: sortOption == 1 ? "checkmark" : "")
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }

            Menu {
                Button { isAscending = true } label: {
                    Label("Ascending", systemImage: isAscending ? "checkmark" : "")
                }
                Button { isAscending = false } label: {
                    Label("Descending", systemImage: !isAscending ? "checkmark" : "")
                }
            } label: {
                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }
        }
    }
}

#Preview {
    SubjectsView()
        .environmentObject(SessionViewModel())
        .environment(\.theme, AppTheme.defaultTheme)
}
