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

    let subjectID: UUID
    var onSave: (Deadline) -> Void

    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var time: Date = .now
    @State private var hasReminder: Bool = false
    @State private var isHighPriority: Bool = false
    @State private var notes: String = ""
    @State private var selectedTag: DeadlineTag = .finalExam

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Add Deadline")
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Button("Save") {
                        saveDeadline()
                    }
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(name.isEmpty ? theme.colors.textSecondary : theme.colors.primary)
                    .disabled(name.isEmpty)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.lg)
                .padding(.bottom, theme.spacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.lg) {
                        fieldSection(title: "DEADLINE NAME") {
                            TextField("e.g., Final Exam", text: $name)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(theme.spacing.md)
                                .background(theme.colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                        }

                        HStack(spacing: theme.spacing.md) {
                            fieldSection(title: "DATE") {
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(theme.spacing.md)
                                    .background(theme.colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            fieldSection(title: "TIME") {
                                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(theme.spacing.md)
                                    .background(theme.colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))

                        fieldSection(title: "ADDITIONAL NOTES") {
                            TextField("Add specific requirements or sub-tasks...", text: $notes, axis: .vertical)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                                .lineLimit(4, reservesSpace: true)
                                .padding(theme.spacing.md)
                                .background(theme.colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.sm) {
                                ForEach(DeadlineTag.allCases) { tag in
                                    Button {
                                        selectedTag = tag
                                    } label: {
                                        Text(tag.rawValue)
                                            .font(theme.typography.bodySmall)
                                            .fontWeight(.semibold)
                                            .foregroundColor(tag == selectedTag ? .white : theme.colors.textSecondary)
                                            .padding(.horizontal, theme.spacing.md)
                                            .padding(.vertical, theme.spacing.xs)
                                            .background(selectedTag == tag ?   theme.colors.primary : theme.colors.surface)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
            .background(theme.colors.surface.opacity(0.2))
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textSecondary)
            content()
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 32, height: 32)
                .background(theme.colors.background)
                .clipShape(Circle())

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
            name: name,
            date: combined,
            hasReminder: hasReminder,
            isHighPriority: isHighPriority,
            notes: notes,
            tag: selectedTag,
            subjectID: subjectID
        )
        onSave(deadline)
        dismiss()
    }
}

#Preview {
    AddDeadlineSheet(subjectID: UUID()) { _ in }
        .environment(\.theme, AppTheme.defaultTheme)
}
