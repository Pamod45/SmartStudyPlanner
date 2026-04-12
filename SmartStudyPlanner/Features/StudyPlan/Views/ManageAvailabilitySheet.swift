import SwiftUI

struct ManageAvailabilitySheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onSave: (AvailabilitySlot) -> Void

    @State private var selectedType: AvailabilityType = .date
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: .now) ?? .now
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: .now) ?? .now
    @State private var selectedDate: Date = .now
    @State private var selectedWeekday: Int = 2
    @State private var rangeStart: Date = .now
    @State private var rangeEnd: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

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
                            Picker("", selection: $selectedType) {
                                ForEach(AvailabilityType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(theme.colors.primary)
                        }

                        FieldSection(title: "TIME SLOT") {
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
                }
            }
            .background(theme.colors.surface.opacity(0.2))
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Manage Availability")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Button("Save") {
                save()
            }
            .font(theme.typography.bodyMedium)
            .fontWeight(.semibold)
            .foregroundColor(theme.colors.primary)
        }
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
        case .date:
            FieldSection(title: "DATE") {
                HStack {
                    Text("Select Date")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(theme.colors.primary)
                }
                .padding(theme.spacing.md)
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            }

        case .weekly:
            FieldSection(title: "DAY OF WEEK") {
                let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: theme.spacing.md
                ) {
                    ForEach(1...7, id: \.self) { day in
                        Button {
                            selectedWeekday = day
                        } label: {
                            Text(weekdays[day - 1])
                                .font(theme.typography.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedWeekday == day ? .white : theme.colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(selectedWeekday == day ? theme.colors.primary : theme.colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radius.xl)
                                        .stroke(
                                            selectedWeekday == day ? theme.colors.primary : theme.colors.border.opacity(0.3),
                                            lineWidth: 1.5
                                        )
                                )
                        }
                    }
                }
            }

        case .range:
            FieldSection(title: "DATE RANGE") {
                VStack(spacing: 0) {
                    HStack {
                        Text("Start Date")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        DatePicker("", selection: $rangeStart, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(theme.colors.primary)
                    }
                    .padding(theme.spacing.md)

                    Divider()
                        .background(theme.colors.background)
                        .padding(.leading, theme.spacing.md)

                    HStack {
                        Text("End Date")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        DatePicker("", selection: $rangeEnd, in: rangeStart..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(theme.colors.primary)
                    }
                    .padding(theme.spacing.md)
                }
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            }

        case .daily:
            EmptyView()
        }
    }

    private func save() {
        let slot = AvailabilitySlot(
            type: selectedType,
            startTime: startTime,
            endTime: endTime,
            date: selectedType == .date ? selectedDate : nil,
            weekday: selectedType == .weekly ? selectedWeekday : nil,
            rangeStart: selectedType == .range ? rangeStart : nil,
            rangeEnd: selectedType == .range ? rangeEnd : nil
        )
        onSave(slot)
        dismiss()
    }
}

#Preview {
    ManageAvailabilitySheet { _ in }
        .environment(\.theme, AppTheme.defaultTheme)
}
