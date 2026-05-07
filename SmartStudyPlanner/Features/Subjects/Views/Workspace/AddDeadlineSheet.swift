//
//  AddDeadlineSheet.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//


import SwiftUI

struct AddDeadlineSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    let subjectId: String
    let userId: String
    var existingDeadline: Deadline? = nil
    var onSave: (Deadline) -> Void
    var onUpdate: ((Deadline) -> Void)? = nil

    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var time: Date = .now
    @State private var hasReminder: Bool = false
    @State private var isHighPriority: Bool = false
    @State private var notes: String = ""
    @State private var selectedTag: DeadlineTag = .finalExam

    private var isEditing: Bool { existingDeadline != nil }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(isEditing ? "Edit Deadline" : "Add Deadline")
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Button("Save") {
                        saveDeadline()
                    }
                    .font(theme.typography.bodyMedium.weight(.semibold))
                    .foregroundColor(name.isEmpty ? theme.colors.textSecondary : theme.colors.primary)
                    .disabled(name.isEmpty)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.lg)

                Divider()
                    .background(theme.colors.border.opacity(0.3))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        
                        FieldSection(title: "DEADLINE NAME") {
                            TextField(
                                "",
                                text: $name,
                                prompt: Text("e.g., Final Exam")
                                    .foregroundColor(theme.colors.textSecondary)
                            )
                            .font(theme.typography.bodyMedium)
                            .frame(minHeight: 28 )
                            .foregroundColor(theme.colors.textPrimary)
                            .tint(theme.colors.primary)
                            .padding(theme.spacing.md)
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        HStack(spacing: theme.spacing.md) {
                            FieldSection(title: "DATE") {
                                
                                ZStack {
                                    HStack {
                                        DatePicker("", selection: $date, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                        Spacer()
                                        Image(systemName: "calendar")
                                            .font(theme.typography.bodyLarge)
                                            .foregroundColor(theme.colors.primary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(theme.colors.surface)
                                    .cornerRadius(theme.radius.lg)
                                }
                            }

                            FieldSection(title: "TIME") {
                                ZStack {
                                    HStack {
                                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                        Spacer()
                                        Image(systemName: "clock.fill")
                                            .font(theme.typography.bodyLarge)
                                            .foregroundColor(theme.colors.primary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(theme.colors.surface)
                                    .cornerRadius(theme.radius.lg)
                                }
                            }
                        }

                        VStack(spacing: 0) {
                            toggleRow(icon: "bell.fill", title: "Set Reminder", isOn: $hasReminder)
                            Divider()
                                .background(theme.colors.background)
                                .padding(.leading, 52)
                            toggleRow(icon: "exclamationmark", title: "High Priority", isOn: $isHighPriority)
                        }
                        .background(theme.colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))

                        FieldSection(title: "ADDITIONAL NOTES") {
                            ZStack(alignment: .topLeading) {
                                
                            
                                if notes.isEmpty {
                                   
                                    Text("Add specific requirements or sub-tasks...")
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.colors.textSecondary)
                                        .padding(theme.spacing.md)
                                }
                                
                                TextEditor(text: $notes)
                                    .font(theme.typography.bodyMedium)
                                    .foregroundColor(
                                        notes.isEmpty ? theme.colors.textSecondary :
                                        theme.colors.textPrimary)
                                    .tint(theme.colors.primary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 100)
                                    .padding(.vertical, theme.spacing.sm)
                                    .padding(.horizontal, theme.spacing.m)
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }
                        
                        ChipPicker(
                            items: DeadlineTag.allCases,
                            selection: $selectedTag,
                            labelProvider: { $0.rawValue }
                        )
                        

                    }
                    .padding(theme.spacing.lg)
                }
            }
            .padding(.vertical, theme.spacing.lg)
            .background(theme.colors.surface.opacity(0.2))
        }
        .onAppear {
            guard let d = existingDeadline else { return }
            name = d.name
            date = d.dueDate
            time = d.dueDate
            hasReminder = d.hasReminder
            isHighPriority = d.isHighPriority
            notes = d.notes
            selectedTag = d.tag
        }
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

    private func saveDeadline() {
        let combined = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: time),
            minute: Calendar.current.component(.minute, from: time),
            second: 0,
            of: date
        ) ?? date

        let deadline = Deadline(
            id: existingDeadline?.id ?? UUID().uuidString,
            userId: existingDeadline?.userId ?? userId,
            subjectId: subjectId,
            name: name,
            dueDate: combined,
            hasReminder: hasReminder,
            isHighPriority: isHighPriority,
            notes: notes,
            tag: selectedTag
        )

        if isEditing {
            onUpdate?(deadline)
        } else {
            onSave(deadline)
        }
        dismiss()
    }
}

#Preview {
    AddDeadlineSheet(subjectId: UUID().uuidString, userId: "preview") { _ in }
        .environment(\.theme, AppTheme.defaultTheme)
}
