import SwiftUI

struct StudyPlanView: View {
    @Environment(\.theme) var theme
    @State private var selectedDate: DateComponents? = nil
    @State private var availabilitySlots: [AvailabilitySlot] = AvailabilitySlot.samples
    @State private var showManageAvailability: Bool = false
    @State private var showCreateStudyPlan: Bool = false

    var slotsForSelectedDate: [AvailabilitySlot] {
        guard let selected = selectedDate,
              let date = Calendar.current.date(from: selected) else { return [] }
        return availabilitySlots.filter { slot in
            switch slot.type {
            case .date:
                return slot.date.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
            case .daily:
                return true
            case .weekly:
                let weekday = Calendar.current.component(.weekday, from: date)
                return slot.weekday == weekday
            case .range:
                guard let start = slot.rangeStart, let end = slot.rangeEnd else { return false }
                return date >= start && date <= end
            }
        }
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacing.lg) {
                        CalendarView(
                            selectedDate: $selectedDate,
                            slots: availabilitySlots
                        )
                        .background(theme.colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                        .padding(.horizontal, theme.spacing.lg)

                        if !slotsForSelectedDate.isEmpty {
                            slotListSection
                                .padding(.horizontal, theme.spacing.lg)
                        } else if selectedDate != nil {
                            emptySlotSection
                                .padding(.horizontal, theme.spacing.lg)
                        }
                    }
                    .padding(.bottom, theme.spacing.xxl)
                }
            }
        }
        .sheet(isPresented: $showManageAvailability) {
            ManageAvailabilitySheet { newSlot in
                availabilitySlots.append(newSlot)
            }
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showCreateStudyPlan) {
            CreateStudyPlanSheet(availabilitySlots: availabilitySlots)
                .environment(\.theme, theme)
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Study Plan")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            HStack(spacing: theme.spacing.md) {
                TextButton(title: "Add Time", icon: "plus", style: .bold) {
                    showManageAvailability = true
                }

                TextButton(title: "Create Plan", icon: "sparkles", style: .bold) {
                    showCreateStudyPlan = true
                }
            }
        }
    }

    private var slotListSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Available Slots")
                .font(theme.typography.headingSmall)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            ForEach(slotsForSelectedDate) { slot in
                slotRow(slot)
            }
        }
    }

    private func slotRow(_ slot: AvailabilitySlot) -> some View {
        HStack(spacing: theme.spacing.md) {
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.colors.primary)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(slot.formattedTimeRange)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(slot.type.rawValue)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    availabilitySlots.removeAll { $0.id == slot.id }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.error)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
    }

    private var emptySlotSection: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 32))
                .foregroundColor(theme.colors.textSecondary)
            Text("No available slots for this day")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, theme.spacing.xl)
    }
}

#Preview {
    StudyPlanView()
        .environment(\.theme, AppTheme.defaultTheme)
}
