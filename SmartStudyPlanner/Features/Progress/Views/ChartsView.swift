import SwiftUI
import Charts

enum ChartType: String, CaseIterable, Identifiable {
    case dailyActivity = "Daily Activity"
    case subjectDist   = "Subject Dist"
    var id: String { rawValue }
}

enum DateRangeFilter: String, CaseIterable {
    case week    = "Last 7 Days"
    case month   = "Last 30 Days"
    case quarter = "Last 90 Days"
}

enum TimePeriodFilter: String, CaseIterable {
    case week  = "This Week"
    case month = "This Month"
    case all   = "All Time"
}

struct ChartsView: View {
    @Environment(\.theme) var theme
    @ObservedObject var vm: ProgressViewModel
    @State private var selectedChart: ChartType = .dailyActivity

    var allSubjectNames: [String] { vm.subjectNames }

    @State private var dateRange: DateRangeFilter = .week
    @State private var timePeriod: TimePeriodFilter = .week
    @State private var selectedSubject: String? = nil
    @State private var activeFilterSheet: Int? = nil

    var allActivity: [DailyActivity]        { vm.dailyActivity }
    var monthActivity: [DailyActivity]      { vm.monthActivity }
    var quarterActivity: [DailyActivity]    { vm.quarterActivity }
    var distribution: [SubjectDistribution] { vm.subjectDistribution }

    var activityData: [DailyActivity] {
        let base: [DailyActivity]
        switch dateRange {
        case .week:    base = allActivity
        case .month:   base = monthActivity
        case .quarter: base = quarterActivity
        }
        guard let subject = selectedSubject else { return base }
        return base.filter { $0.subject == subject }
    }

    var distributionData: [SubjectDistribution] {
        switch timePeriod {
        case .week:
            return distribution
        case .month:
            return distribution.map {
                SubjectDistribution(name: $0.name, percentage: min($0.percentage * 1.15, 1.0), color: $0.color)
            }
        case .all:
            return distribution.map {
                SubjectDistribution(name: $0.name, percentage: min($0.percentage * 1.3, 1.0), color: $0.color)
            }
        }
    }

    var totalActivityHours: Double {
        let unique = Dictionary(grouping: activityData, by: { $0.day })
        return unique.values.map { $0.map(\.hours).reduce(0, +) }.reduce(0, +)
    }

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                chartTypePicker
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.md)

                filterStack
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                ZStack {
                    switch selectedChart {
                    case .dailyActivity: dailyActivityChart
                    case .subjectDist:   subjectDistChart
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.md)
                .frame(maxHeight: .infinity)
            }
        }
        .sheet(item: $activeFilterSheet) { slot in
            filterSheetContent(slot: slot)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }


    private var chartTypePicker: some View {
        HStack(spacing: theme.spacing.sm) {
            ForEach(ChartType.allCases) { type in
                Button {
                    withAnimation(.spring(duration: 0.3)) { selectedChart = type }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: iconFor(type))
                            .font(.system(size: 11, weight: .semibold))
                        Text(shortLabel(type))
                            .font(theme.typography.bodySmall.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedChart == type ? theme.colors.textOnPrimary : theme.colors.textPrimary)
                    .padding(.vertical, theme.spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(selectedChart == type ? theme.colors.primary : theme.colors.surface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func shortLabel(_ type: ChartType) -> String {
        switch type {
        case .dailyActivity: return "Activity"
        case .subjectDist:   return "Subjects"
        }
    }

    private func iconFor(_ type: ChartType) -> String {
        switch type {
        case .dailyActivity: return "chart.line.uptrend.xyaxis"
        case .subjectDist:   return "chart.pie.fill"
        }
    }


    private var filterStack: some View {
        let filters = filtersForCurrentChart
        return HStack(spacing: theme.spacing.sm) {
            ForEach(filters.indices, id: \.self) { i in
                let f = filters[i]
                Button { activeFilterSheet = i } label: {
                    HStack(spacing: theme.spacing.xs) {
                        Image(systemName: f.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(f.isActive ? theme.colors.primary : theme.colors.textSecondary)
                        Text(f.label)
                            .font(theme.typography.bodySmall.weight(.semibold))
                            .foregroundColor(f.isActive ? theme.colors.primary : theme.colors.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(f.isActive ? theme.colors.primary.opacity(0.1) : theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                    .overlay(RoundedRectangle(cornerRadius: theme.radius.lg)
                        .stroke(f.isActive ? theme.colors.primary.opacity(0.4) : theme.colors.border.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private struct FilterMeta {
        let icon: String
        let label: String
        let isActive: Bool
    }

    private var filtersForCurrentChart: [FilterMeta] {
        let subjectLabel = selectedSubject ?? "All Subjects"
        switch selectedChart {
        case .dailyActivity:
            return [
                FilterMeta(icon: "calendar",    label: dateRange.rawValue, isActive: dateRange != .week),
                FilterMeta(icon: "book.closed", label: subjectLabel,       isActive: selectedSubject != nil)
            ]
        case .subjectDist:
            return [
                FilterMeta(icon: "clock", label: timePeriod.rawValue, isActive: timePeriod != .week)
            ]
        }
    }

    @ViewBuilder
    private func filterSheetContent(slot: Int) -> some View {
        FilterSheetView(
            slot: slot,
            chart: selectedChart,
            dateRange: $dateRange,
            timePeriod: $timePeriod,
            selectedSubject: $selectedSubject,
            allSubjectNames: allSubjectNames
        )
    }


    private struct DailyTotal: Identifiable {
        let id = UUID()
        let day: String
        let index: Int
        let hours: Double
    }

    private var aggregatedActivity: [DailyTotal] {
        let data = activityData
        let grouped = Dictionary(grouping: data, by: \.day)
        let orderedDays: [String]
        switch dateRange {
        case .week:    orderedDays = ["MON","TUE","WED","THU","FRI","SAT","SUN"]
        case .month:   orderedDays = (1...30).map { "\($0)" }
        case .quarter: orderedDays = (1...13).map { "W\($0)" }
        }
        return orderedDays.enumerated().compactMap { (i, day) in
            guard let entries = grouped[day] else { return nil }
            let total = entries.map(\.hours).reduce(0, +)
            return DailyTotal(day: day, index: i, hours: total)
        }
    }

    private var dailyActivityChart: some View {
        let aggregated = aggregatedActivity
        let accent = theme.colors.primary

        return VStack(alignment: .leading, spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1f hrs", totalActivityHours))
                    .font(theme.typography.headingLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                HStack(spacing: 6) {
                    Spacer()
                    Text(dateRange.rawValue.uppercased())
                        .font(theme.typography.labelSmall.weight(.bold))
                        .foregroundColor(theme.colors.primary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(theme.colors.primary.opacity(0.15))
                        .clipShape(Capsule())
                    if let subject = selectedSubject {
                        Text(subject.uppercased())
                            .font(theme.typography.labelSmall.weight(.bold))
                            .foregroundColor(theme.colors.textSecondary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(theme.colors.surface)
                            .clipShape(Capsule())
                    }
                }
            }

            Chart {
                ForEach(aggregated) { item in
                    AreaMark(
                        x: .value("Day", item.index),
                        y: .value("Hours", item.hours)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent.opacity(0.35), accent.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Day", item.index),
                        y: .value("Hours", item.hours)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(accent)

                    PointMark(
                        x: .value("Day", item.index),
                        y: .value("Hours", item.hours)
                    )
                    .symbolSize(28)
                    .foregroundStyle(accent)
                }
            }
            .chartXAxis {
                AxisMarks(values: aggregated.map(\.index)) { value in
                    AxisValueLabel {
                        if let i = value.as(Int.self),
                           let item = aggregated.first(where: { $0.index == i }) {
                            Text(item.day)
                                .font(theme.typography.label)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(theme.colors.border.opacity(0.3))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(String(format: "%.0fh", v))
                                .font(theme.typography.label)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .frame(maxHeight: .infinity)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
    }


    private var subjectDistChart: some View {
        let data = distributionData
        return VStack(alignment: .leading, spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Subject Distribution")
                    .font(theme.typography.headingSmall).fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                Text("\(timePeriod.rawValue) breakdown")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Chart(data, id: \.name) { item in
                SectorMark(
                    angle: .value("Percentage", item.percentage),
                    innerRadius: .ratio(0.55),
                    angularInset: 2
                )
                .cornerRadius(4)
                .foregroundStyle(item.color)
                .annotation(position: .overlay) {
                    if item.percentage > 0.08 {
                        Text("\(Int(item.percentage * 100))%")
                            .font(theme.typography.labelSmall.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartBackground { _ in
                VStack(spacing: 2) {
                    Text("TOTAL")
                        .font(theme.typography.caption.weight(.semibold))
                        .foregroundStyle(theme.colors.textSecondary)
                    Text("100%")
                        .font(theme.typography.headingSmall).fontWeight(.bold)
                        .foregroundStyle(theme.colors.textPrimary)
                }
            }
            .chartLegend(.hidden)
            .frame(maxHeight: .infinity)

            VStack(spacing: theme.spacing.sm) {
                ForEach(data, id: \.name) { d in
                    HStack(spacing: theme.spacing.sm) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(d.color)
                            .frame(width: 12, height: 12)
                        Text(d.name)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        Text("\(Int(d.percentage * 100))%")
                            .font(theme.typography.bodySmall.weight(.bold))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
    }
}


struct FilterSheetView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    let slot: Int
    let chart: ChartType
    @Binding var dateRange: DateRangeFilter
    @Binding var timePeriod: TimePeriodFilter
    @Binding var selectedSubject: String?
    let allSubjectNames: [String]

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
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
                    Text(sheetTitle)
                        .font(theme.typography.headingSmall).fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.lg)
                .padding(.bottom, theme.spacing.md)

                Divider().background(theme.colors.border.opacity(0.3))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        sheetBody
                    }
                    .padding(theme.spacing.lg)
                }
            }
        }
    }

    private var sheetTitle: String {
        switch chart {
        case .dailyActivity:
            return slot == 0 ? "Date Range" : "Filter by Subject"
        case .subjectDist:
            return "Time Period"
        }
    }

    @ViewBuilder
    private var sheetBody: some View {
        switch chart {
        case .dailyActivity:
            if slot == 0 { dateRangePicker }
            else          { subjectPicker }
        case .subjectDist:
            timePeriodPicker
        }
    }

    private func optionRows<T: RawRepresentable & CaseIterable & Equatable>(
        title: String,
        cases: [T],
        selected: Binding<T>
    ) -> some View where T.RawValue == String {
        FieldSection(title: title) {
            VStack(spacing: 0) {
                ForEach(Array(cases.enumerated()), id: \.offset) { idx, option in
                    Button { selected.wrappedValue = option } label: {
                        HStack {
                            Text(option.rawValue)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                            Spacer()
                            if selected.wrappedValue == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(theme.colors.primary)
                            }
                        }
                        .padding(theme.spacing.md)
                    }
                    .buttonStyle(.plain)
                    if idx < cases.count - 1 {
                        Divider().background(theme.colors.border.opacity(0.2))
                            .padding(.leading, theme.spacing.md)
                    }
                }
            }
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
        }
    }

    private var dateRangePicker: some View {
        optionRows(title: "DATE RANGE", cases: DateRangeFilter.allCases, selected: $dateRange)
    }

    private var timePeriodPicker: some View {
        optionRows(title: "TIME PERIOD", cases: TimePeriodFilter.allCases, selected: $timePeriod)
    }

    private var subjectPicker: some View {
        FieldSection(title: "SUBJECT") {
            VStack(spacing: 0) {
                Button {
                    selectedSubject = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("All Subjects")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        if selectedSubject == nil {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(theme.colors.primary)
                        }
                    }
                    .padding(theme.spacing.md)
                }
                .buttonStyle(.plain)

                if !allSubjectNames.isEmpty {
                    Divider().background(theme.colors.border.opacity(0.2))
                        .padding(.leading, theme.spacing.md)
                }

                ForEach(Array(allSubjectNames.enumerated()), id: \.offset) { idx, name in
                    Button {
                        selectedSubject = name
                        dismiss()
                    } label: {
                        HStack(spacing: theme.spacing.md) {
                            Circle()
                                .fill(theme.colors.primary)
                                .frame(width: 10, height: 10)
                            Text(name)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                            Spacer()
                            if selectedSubject == name {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(theme.colors.primary)
                            }
                        }
                        .padding(theme.spacing.md)
                    }
                    .buttonStyle(.plain)
                    if idx < allSubjectNames.count - 1 {
                        Divider().background(theme.colors.border.opacity(0.2))
                            .padding(.leading, theme.spacing.md)
                    }
                }
            }
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
        }
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
