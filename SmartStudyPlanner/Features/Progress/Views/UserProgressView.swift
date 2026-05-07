import SwiftUI

enum ProgressTab: String, CaseIterable {
    case summary = "Summary"
    case charts  = "Charts"
}

struct UserProgressView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var sessionVM: SessionViewModel
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
        .task(id: sessionVM.activeUserId) {
            await vm.load(userId: sessionVM.activeUserId)
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
    UserProgressView()
        .environment(\.theme, AppTheme.defaultTheme)
        .environmentObject(SessionViewModel())
}
