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

    var onSave: (Subject) -> Void

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

                    Text("Add Subject")
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()
                    
                    TextButton(title:"Save", style: .bold){
                        guard !subjectName.isEmpty else { return }
                        let newSubject = Subject(
                            name: subjectName,
                            color: selectedColor,
                            resources: 0,
                            topics: 0,
                            lastUpdated: "Just now"
                        )
                        onSave(newSubject)
                        dismiss()
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.lg)

                Divider()
                    .background(theme.colors.border.opacity(0.3))

                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {

                        fieldSection(title: "SUBJECT NAME") {
                            TextField(
                                "",
                                text: $subjectName,
                                prompt: Text("e.g., Web API")
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

                        fieldSection(title: "COLOR") {
                            ColorPickerRow(selectedColor: $selectedColor)
                        }

                        fieldSection(title: "ADDITIONAL NOTES") {
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
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)
                }
            }
            .padding(.vertical, theme.spacing.lg)
            .background(theme.colors.surface.opacity(0.2))
            
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(title)
                .font(theme.typography.caption.weight(.bold))
                .foregroundColor(theme.colors.textPrimary)
                .tracking(2)
            content()
        }
    }
}

#Preview {
    AddSubjectSheet { _ in }
        .environment(\.theme, AppTheme.defaultTheme)
}
