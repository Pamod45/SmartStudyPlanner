import SwiftUI

// Collects the user's available study window before the view model expands and saves it.
struct ManageAvailabilitySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onSave: (AvailabilitySlot) -> Void

    @State private var selectedType: AvailabilityType = .specificDate
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: .now) ?? .now
    @State private var endTime: Date   = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: .now) ?? .now
    @State private var selectedDate: Date
    @State private var rangeStart: Date
    @State private var rangeEnd: Date

    init(initialDate: Date = .now, onSave: @escaping (AvailabilitySlot) -> Void) {
        self.onSave = onSave
        let cal = Calendar.current
        let effective = max(cal.startOfDay(for: .now), cal.startOfDay(for: initialDate))
        _selectedDate = State(initialValue: effective)
        _rangeStart   = State(initialValue: effective)
        _rangeEnd     = State(initialValue: cal.date(byAdding: .day, value: 6, to: effective) ?? effective)
    }

    private var todayStart: Date {
        Calendar.current.startOfDay(for: .now)
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                Divider().background(theme.colors.border.opacity(0.3))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {

                        FieldSection(title: "AVAILABILITY TYPE") {
                            HStack(spacing: theme.spacing.sm) {
                                typeChip(.specificDate, label: "Single Date", icon: "calendar")
                                typeChip(.dateRange,    label: "Date Range",  icon: "calendar.badge.plus")
                            }
                        }

                        FieldSection(title: "TIME WINDOW") {
                            VStack(spacing: 0) {
                                timeRow(label: "Start Time", time: $startTime)
                                Divider()
                                    .background(theme.colors.background)
                                    .padding(.leading, theme.spacing.md)
                                timeRow(label: "End Time", time: $endTime)
                            }
                            .background(theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                        }

                        dateSection
                    }
                    .padding(theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xxl)
                }
            }
            .background(theme.colors.surface.opacity(0.2))
        }
        .onChange(of: rangeStart) { _, newValue in
            if rangeEnd < newValue {
                rangeEnd = newValue
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Add Availability")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Button("Save") { save() }
                .font(theme.typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.primary)
        }
    }

    private func typeChip(_ type: AvailabilityType, label: String, icon: String) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedType = type }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(theme.typography.bodySmall)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? theme.colors.primary : theme.colors.surface)
            .foregroundColor(isSelected ? theme.colors.textOnPrimary : theme.colors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg)
                    .stroke(isSelected ? theme.colors.primary : theme.colors.border.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func timeRow(label: String, time: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(theme.colors.primary)
        }
        .padding(theme.spacing.md)
    }

    @ViewBuilder
    private var dateSection: some View {
        switch selectedType {
        case .specificDate:
            FieldSection(title: "DATE") {
                HStack {
                    Text("Select Date")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Spacer()
                    DatePicker("", selection: $selectedDate, in: todayStart..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(theme.colors.primary)
                }
                .padding(theme.spacing.md)
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            }

        case .dateRange:
            FieldSection(title: "DATE RANGE") {
                VStack(spacing: 0) {
                    HStack {
                        Text("From")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        DatePicker("", selection: $rangeStart, in: todayStart..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(theme.colors.primary)
                    }
                    .padding(theme.spacing.md)

                    Divider()
                        .background(theme.colors.background)
                        .padding(.leading, theme.spacing.md)

                    HStack {
                        Text("To")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        DatePicker("", selection: $rangeEnd, in: Calendar.current.startOfDay(for: max(todayStart, rangeStart))..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(theme.colors.primary)
                    }
                    .padding(theme.spacing.md)
                }
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))

                let days = Calendar.current.dateComponents([.day], from: rangeStart, to: rangeEnd).day ?? 0
                Text("Applies to \(days + 1) day\(days == 0 ? "" : "s")")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.top, 4)
            }
        }
    }

    // Builds the slot differently for single-date and date-range availability; persistence happens in StudyPlanViewModel.
    private func save() {
        let slot = AvailabilitySlot(
            type:       selectedType,
            startTime:  startTime,
            endTime:    endTime,
            date:       selectedType == .specificDate ? selectedDate : nil,
            rangeStart: selectedType == .dateRange    ? rangeStart   : nil,
            rangeEnd:   selectedType == .dateRange    ? rangeEnd     : nil
        )
        onSave(slot)
        dismiss()
    }
}

#Preview {
    ManageAvailabilitySheet(onSave: { _ in })
        .environment(\.theme, AppTheme.defaultTheme)
}
