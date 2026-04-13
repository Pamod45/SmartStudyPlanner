import SwiftUI

enum ProgressTab: String, CaseIterable {
    case summary = "Summary"
    case charts  = "Charts"
}

struct ProgressView: View {
    @Environment(\.theme) var theme
    @StateObject private var vm = ProgressViewModel()
    @State private var selectedTab: ProgressTab = .summary

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.background)

                tabPicker
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)

                ZStack {
                    if selectedTab == .summary {
                        SummaryView(vm: vm)
                    } else {
                        ChartsView(vm: vm)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Progress")
                .font(theme.typography.headingMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ProgressTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    ProgressView()
        .environment(\.theme, AppTheme.defaultTheme)
}
