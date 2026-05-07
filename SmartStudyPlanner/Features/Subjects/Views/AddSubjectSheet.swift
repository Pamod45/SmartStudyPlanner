//
//  AddSubjectSheet.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-02.
//


import SwiftUI

struct AddSubjectSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    @State private var subjectName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var notes: String = ""

    var editingSubject: Subject? = nil
    var onSave: (Subject) -> Void
    var onUpdate: ((Subject) -> Void)? = nil

    private var isEditing: Bool { editingSubject != nil }

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(theme.typography.bodyMedium.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)

                    Spacer()

                    Text(isEditing ? "Edit Subject" : "Add Subject")
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()
                    
                    TextButton(title: "Save", style: .bold) {
                        guard !subjectName.isEmpty else { return }
                        if let existing = editingSubject {
                            var updated = existing
                            updated.name = subjectName
                            updated.colorHex = selectedColor.toHex() ?? existing.colorHex
                            updated.notes = notes
                            updated.updatedAt = Date()
                            onUpdate?(updated)
                        } else {
                            let newSubject = Subject(
                                name: subjectName,
                                colorHex: selectedColor.toHex() ?? "#3B82F6",
                                notes: notes
                            )
                            onSave(newSubject)
                        }
                        dismiss()
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.lg)

                Divider()
                    .background(theme.colors.border.opacity(0.3))

                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {

                        FieldSection(title: "SUBJECT NAME") {
                            TextField(
                                "",
                                text: $subjectName,
                                prompt: Text("e.g., Web API")
                                    .foregroundColor(theme.colors.textSecondary)
                            )
                            .font(theme.typography.bodyMedium)
                            .frame(minHeight: 28)
                            .foregroundColor(theme.colors.textPrimary)
                            .tint(theme.colors.primary)
                            .padding(theme.spacing.md)
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        FieldSection(title: "COLOR") {
                            ColorPickerRow(selectedColor: $selectedColor)
                        }

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
                    }
                    .padding(theme.spacing.lg)
                }
            }
            .padding(.vertical, theme.spacing.lg)
            .background(theme.colors.surface.opacity(0.2))
        }
        .onAppear {
            if let editing = editingSubject {
                subjectName = editing.name
                selectedColor = Color(hex: editing.colorHex) ?? .blue
                notes = editing.notes
            }
        }
    }
}

#Preview {
    AddSubjectSheet { _ in }
        .environment(\.theme, AppTheme.defaultTheme)
}
