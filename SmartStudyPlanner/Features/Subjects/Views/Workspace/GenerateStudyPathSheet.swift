//
//  GenerateStudyPathSheet.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-12.
//

import SwiftUI

struct GenerateStudyPathSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let subject: Subject
    let resources: [Resource]
    let isRegenerate: Bool
    var onGenerate: (StudyPath) -> Void

    @State private var selectedResourceIDs: Set<UUID> = []

    init(
        subject: Subject,
        resources: [Resource],
        isRegenerate: Bool = false,
        onGenerate: @escaping (StudyPath) -> Void
    ) {
        self.subject = subject
        self.resources = resources
        self.isRegenerate = isRegenerate
        self.onGenerate = onGenerate
        _selectedResourceIDs = State(initialValue: Set(resources.map { $0.id }))
    }

    private var selectedResources: [Resource] {
        resources.filter { selectedResourceIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                Divider().background(theme.colors.border.opacity(0.3))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.md) {
                        FieldSection(title: "AVAILABLE RESOURCES") {
                            VStack(spacing: theme.spacing.md) {
                                if resources.isEmpty {
                                    emptyResourcesView
                                } else {
                                    ForEach(resources) { resource in
                                        resourceRow(resource)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, theme.spacing.md)
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, 100)
                }

                generateButtonBar
            }.background(theme.colors.surface.opacity(0.2))
        }
    }

    private var sheetHeader: some View {
        HStack {
            Text("Study Path")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            if !resources.isEmpty {
                Button {
                    if selectedResourceIDs.count == resources.count {
                        selectedResourceIDs = []
                    } else {
                        selectedResourceIDs = Set(resources.map { $0.id })
                    }
                } label: {
                    Text(selectedResourceIDs.count == resources.count ? "Deselect All" : "Select All")
                        .font(theme.typography.bodyMedium.weight(.semibold))
                        .foregroundColor(theme.colors.primary)
                }
            }
        }
    }

    private func resourceRow(_ resource: Resource) -> some View {
        let isSelected = selectedResourceIDs.contains(resource.id)

        return Button {
            if isSelected {
                selectedResourceIDs.remove(resource.id)
            } else {
                selectedResourceIDs.insert(resource.id)
            }
        } label: {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    Rectangle()
                        .fill(resource.type.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .cornerRadius(theme.radius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.lg)
                                .stroke(resource.type.color.opacity(0.35), lineWidth: 1)
                        )
                    Image(systemName: resource.type.icon)
                        .font(theme.typography.headingSmall.weight(.semibold))
                        .foregroundColor(resource.type.color)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(resource.name)
                        .font(theme.typography.bodyMedium.weight(.semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(resource.size.isEmpty ? resource.type.rawValue : "\(resource.size) • \(dateLabel(resource))")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                ZStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(isSelected ? theme.colors.primary : theme.colors.textSecondary)
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
            
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var emptyResourcesView: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(theme.colors.textSecondary)
            Text("No resources added yet.\nAdd resources first to generate a study path.")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var generateButtonBar: some View {
        VStack(spacing: 0) {
            PrimaryButton(
                title: isRegenerate ? "Regenerate Study Path" : "Generate Study Path",
                icon: isRegenerate ? "arrow.clockwise" : nil
            ) {
                let path = StudyPath.generate(for: subject, using: selectedResources)
                onGenerate(path)
                dismiss()
            }
            .disabled(selectedResourceIDs.isEmpty)
            .opacity(selectedResourceIDs.isEmpty ? 0.5 : 1)
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.background)
        }
    }

    private func dateLabel(_ resource: Resource) -> String {
        let days = Int.random(in: 0...14)
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days <= 7  { return "\(days) days ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date().addingTimeInterval(Double(-days) * 86400))
    }
}

#Preview {
    GenerateStudyPathSheet(
        subject: Subject.samples.first!,
        resources: Resource.samples(for: Subject.samples.first!.id),
        isRegenerate: false
    ) { _ in }
    .environmentObject(ThemeManager())
    .environment(\.theme, AppTheme.defaultTheme)
}
